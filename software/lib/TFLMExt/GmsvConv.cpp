/*
 * Copyright 2025 LIRMM
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
#include "tensorflow/lite/c/common.h"
#include "tensorflow/lite/kernels/internal/portable_tensor_utils.h"
#include "tensorflow/lite/kernels/internal/reference/conv.h"
#include "tensorflow/lite/kernels/internal/reference/integer_ops/conv.h"
#include "tensorflow/lite/kernels/kernel_util.h"
#include "tensorflow/lite/micro/kernels/conv.h"
#include "tensorflow/lite/micro/kernels/kernel_util.h"
#include "tensorflow/lite/micro/micro_log.h"
#pragma clang diagnostic pop

#include "adam/TFLMExt/GmsvConv.h"
#include "adam/Tensor/Gemm.h"
#include "adam/Tensor/GmsvGemm.h"
#include "adam/Tensor/QuantMulAcc.h"
#include "adam/Tensor/Tensor.h"
#include "adam/Tensor/TiledConv2D.h"

using namespace adam::tensor;
using namespace tflite;

namespace adam::tflm_ext {

TfLiteStatus GmsvConvEval(TfLiteContext *context, TfLiteNode *node) {
  const TfLiteEvalTensor *input =
      tflite::micro::GetEvalInput(context, node, kConvInputTensor);
  const TfLiteEvalTensor *filter =
      tflite::micro::GetEvalInput(context, node, kConvWeightsTensor);
  const TfLiteEvalTensor *bias =
      (NumInputs(node) == 3)
          ? tflite::micro::GetEvalInput(context, node, kConvBiasTensor)
          : nullptr;
  TfLiteEvalTensor *output =
      ::tflite::micro::GetEvalOutput(context, node, kConvOutputTensor);

  TFLITE_DCHECK(node->builtin_data != nullptr);
  const auto &params =
      *(reinterpret_cast<TfLiteConvParams *>(node->builtin_data));
  TFLITE_DCHECK(node->user_data != nullptr);
  const auto &data = *(static_cast<const OpDataConv *>(node->user_data));

  if (input->type != kTfLiteInt8) {
    MicroPrintf("Input type %s (%d) not supported.",
                TfLiteTypeGetName(input->type), input->type);
    return kTfLiteError;
  }

  if (filter->type != kTfLiteInt8) {
    MicroPrintf("Weight type %s (%d) not supported.",
                TfLiteTypeGetName(filter->type), filter->type);
    return kTfLiteError;
  }

  const ConvParams qparams = ConvParamsQuantized(params, data);
  const int32_t *output_multiplier = data.per_channel_output_multiplier;
  const int32_t *output_shift = data.per_channel_output_shift;
  const RuntimeShape input_shape = tflite::micro::GetTensorShape(input);
  const int8_t *input_data = tflite::micro::GetTensorData<int8_t>(input);
  const RuntimeShape filter_shape = tflite::micro::GetTensorShape(filter);
  const RuntimeShape bias_shape = tflite::micro::GetTensorShape(bias);
  const RuntimeShape output_shape = tflite::micro::GetTensorShape(output);
  int8_t *output_data = tflite::micro::GetTensorData<int8_t>(output);

#ifdef USE_TFLM_COMPRESSION
  MicroContext *micro_context = GetMicroContext(context);
  const CompressionTensorData *weights_comp_td =
      micro_context->GetTensorCompressionData(node, kConvWeightsTensor);
  const CompressionTensorData *bias_comp_td =
      micro_context->GetTensorCompressionData(node, kConvBiasTensor);
  const int8_t *filter_data = tflite::micro::GetTensorData<int8_t>(
      micro_context, filter, weights_comp_td, data.weights_scratch_index);
  const int32_t *bias_data = tflite::micro::GetOptionalTensorData<int32_t>(
      micro_context, bias, bias_comp_td, data.bias_scratch_index);
#else  // USE_TFLM_COMPRESSION
  const int8_t *filter_data = tflite::micro::GetTensorData<int8_t>(filter);
  const int32_t *bias_data =
      tflite::micro::GetOptionalTensorData<int32_t>(bias);
#endif // USE_TFLM_COMPRESSION

  const int32_t input_offset = qparams.input_offset; // r = s(q - Z)
  const int stride_width = qparams.stride_width;
  const int stride_height = qparams.stride_height;
  const int dilation_width_factor = qparams.dilation_width_factor;
  const int dilation_height_factor = qparams.dilation_height_factor;
  const int pad_width = qparams.padding_values.width;
  const int pad_height = qparams.padding_values.height;
  const int32_t output_offset = qparams.output_offset;

  // Set min and max value of the output.
  const int32_t output_activation_min = qparams.quantized_activation_min;
  const int32_t output_activation_max = qparams.quantized_activation_max;

  // Consistency check.
  TFLITE_DCHECK_LE(output_activation_min, output_activation_max);
  TFLITE_DCHECK_EQ(input_shape.DimensionsCount(), 4);
  TFLITE_DCHECK_EQ(filter_shape.DimensionsCount(), 4);
  TFLITE_DCHECK_EQ(output_shape.DimensionsCount(), 4);
  const int batches = MatchingDim(input_shape, 0, output_shape, 0);
  const int input_depth = input_shape.Dims(3);
  const int output_depth = MatchingDim(filter_shape, 0, output_shape, 3);
  if (bias_data) {
    TFLITE_DCHECK_EQ(bias_shape.FlatSize(), output_depth);
  }

  // Check dimensions of the tensors.
  const int input_height = input_shape.Dims(1);
  const int input_width = input_shape.Dims(2);
  const int filter_height = filter_shape.Dims(1);
  const int filter_width = filter_shape.Dims(2);
  const int filter_input_depth = filter_shape.Dims(3);
  const int groups = input_depth / filter_input_depth;
  TFLITE_DCHECK_NE(groups, 0);
  TFLITE_DCHECK_EQ(input_depth % filter_input_depth, 0);
  const int filters_per_group = output_depth / groups;
  TFLITE_DCHECK_NE(filters_per_group, 0);
  const int output_height = output_shape.Dims(1);
  const int output_width = output_shape.Dims(2);

  const int n = batches;
  const int ic = input_depth;
  const int ih = input_height;
  const int iw = input_width;
  const int oc = output_depth;
  const int oh = output_height;
  const int ow = output_width;
  const int kh = filter_height;
  const int kw = filter_width;
  const int sh = stride_height;
  const int sw = stride_width;
  const int pt = pad_height;
  const int pl = pad_width;
  const int dh = dilation_height_factor;
  const int dw = dilation_width_factor;
  const int g = groups;

  // Conv2D<int8_t, int32_t> conv(ic, ih, iw, oc, kh, kw, sh, sw, pt, pl, dh,
  // dw,
  //                              n, g);

  Gemm<int8_t, int32_t> gemm(4, 4, 4);
  TiledGemm<int8_t, int32_t> tiledGemm(oc, n * oh * ow, kh * kw * ic, gemm);
  TiledConv2D<int8_t, int32_t> tiledConv(tiledGemm, ic, ih, iw, oc, kh, kw, sh,
                                         sw, pt, pl, dh, dw, n, g);

  adam::tensor::Tensor<int8_t> in_tensor({n, ih, iw, ic}, (int8_t *)input_data);
  adam::tensor::Tensor<int8_t> w_tensor({oc, kh, kw, ic / g},
                                        (int8_t *)filter_data);
  adam::tensor::Tensor<int32_t> b_tensor({oc}, (int32_t *)bias_data);
  adam::tensor::Tensor<int32_t> out_tensor({n, oh, ow, oc});

  QuantMulAcc<int8_t, int32_t> matMul(input_offset);
  // conv.run(in_tensor, w_tensor, b_tensor, out_tensor, matMul);
  // w_tensor.print();
  // std::printf("\n");

  tiledConv.run(in_tensor, w_tensor, b_tensor, out_tensor, matMul);
  // w_tensor.print();
  // std::printf("\n");

  // Output post-processing
  for (int batch = 0; batch < batches; ++batch) {
    for (int out_channel = 0; out_channel < output_depth; ++out_channel) {
      for (int out_y = 0; out_y < output_height; ++out_y) {
        for (int out_x = 0; out_x < output_width; ++out_x) {
          int32_t value = out_tensor(batch, out_y, out_x, out_channel);
          value = MultiplyByQuantizedMultiplier(
              value, output_multiplier[out_channel], output_shift[out_channel]);
          value += output_offset;
          value = std::max(value, output_activation_min);
          value = std::min(value, output_activation_max);
          output_data[Offset(output_shape, batch, out_y, out_x, out_channel)] =
              static_cast<int8_t>(value);
        }
      }
    }
  }

  return kTfLiteOk;
}

TFLMRegistration Register_GMSV_CONV_2D() {
  return tflite::micro::RegisterOp(tflite::ConvInit, tflite::ConvPrepare,
                                   GmsvConvEval);
}

} // namespace adam::tflm_ext
