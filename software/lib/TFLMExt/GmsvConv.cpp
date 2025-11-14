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
#include "adam/Tensor/Conv2D.h"

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

  Conv2D<int32_t, int32_t> conv(
      input_depth, input_height, input_width, output_depth, filter_height,
      filter_width, stride_height, stride_width, pad_height, pad_width,
      dilation_height_factor, dilation_width_factor, batches, groups);

  int in_size = batches * input_depth * input_height * input_width;
  int w_size = output_depth * filter_input_depth * filter_height * filter_width;
  int out_size = batches * output_depth * output_height * output_width;

  int32_t *in_data = new int32_t[in_size];
  int32_t *w_data = new int32_t[w_size];
  int32_t *out_data = new int32_t[out_size];

  // Input data copy with proper indexing
  for (int batch = 0; batch < batches; ++batch) {
    for (int in_channel = 0; in_channel < input_depth; ++in_channel) {
      for (int in_y = 0; in_y < input_height; ++in_y) {
        for (int in_x = 0; in_x < input_width; ++in_x) {

          int32_t value =
              input_data[Offset(input_shape, batch, in_y, in_x,
                                in_channel + 0 * filter_input_depth)];

          int index =
              ((batch * input_depth + in_channel) * input_height + in_y) *
                  input_width +
              in_x;

          in_data[index] = value + input_offset;
        }
      }
    }
  }

  // Weights copy with explicit 4D indexing
  for (int out_channel = 0; out_channel < output_depth; ++out_channel) {
    for (int in_channel = 0; in_channel < filter_input_depth; ++in_channel) {
      for (int filter_y = 0; filter_y < filter_height; ++filter_y) {
        for (int filter_x = 0; filter_x < filter_width; ++filter_x) {
          int32_t value = filter_data[Offset(filter_shape, out_channel,
                                             filter_y, filter_x, in_channel)];

          int index =
              ((out_channel * filter_input_depth + in_channel) * filter_height +
               filter_y) *
                  filter_width +
              filter_x;

          w_data[index] = value;
        }
      }
    }
  }

  // Run the convolution
  conv.run(in_data, w_data, bias_data, out_data);

  // Output post-processing with structured indexing
  for (int batch = 0; batch < batches; ++batch) {
    for (int out_channel = 0; out_channel < output_depth; ++out_channel) {
      for (int out_y = 0; out_y < output_height; ++out_y) {
        for (int out_x = 0; out_x < output_width; ++out_x) {
          int index =
              ((batch * output_depth + out_channel) * output_height + out_y) *
                  output_width +
              out_x;

          int32_t value = out_data[index];
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

  delete[] out_data;

  // for (int batch = 0; batch < batches; ++batch) {
  //   for (int out_y = 0; out_y < output_height; ++out_y) {
  //     const int in_y_origin = (out_y * stride_height) - pad_height;
  //     for (int out_x = 0; out_x < output_width; ++out_x) {
  //       const int in_x_origin = (out_x * stride_width) - pad_width;
  //       for (int out_channel = 0; out_channel < output_depth; ++out_channel)
  //       {
  //         auto group = out_channel / filters_per_group;
  //         int32_t acc = 0;
  //         for (int filter_y = 0; filter_y < filter_height; ++filter_y) {
  //           const int in_y = in_y_origin + dilation_height_factor * filter_y;
  //           for (int filter_x = 0; filter_x < filter_width; ++filter_x) {
  //             const int in_x = in_x_origin + dilation_width_factor *
  //             filter_x;
  //
  //             // Zero padding by omitting the areas outside the image.
  //             const bool is_point_inside_image =
  //                 (in_x >= 0) && (in_x < input_width) && (in_y >= 0) &&
  //                 (in_y < input_height);
  //
  //             if (!is_point_inside_image) {
  //               continue;
  //             }
  //
  //             for (int in_channel = 0; in_channel < filter_input_depth;
  //                  ++in_channel) {
  //               int32_t input_val =
  //                   input_data[Offset(input_shape, batch, in_y, in_x,
  //                                     in_channel + group *
  //                                     filter_input_depth)];
  //               int32_t filter_val = filter_data[Offset(
  //                   filter_shape, out_channel, filter_y, filter_x,
  //                   in_channel)];
  //               // Accumulate with 32 bits accumulator.
  //               // In the nudging process during model quantization, we force
  //               // real value of 0.0 be represented by a quantized value.
  //               This
  //               // guarantees that the input_offset is a int8_t, even though
  //               // it is represented using int32_t. int32_t += int8_t *
  //               // (int8_t - int8_t) so the highest value we can get from
  //               each
  //               // accumulation is [-127, 127] * ([-128, 127] -
  //               // [-128, 127]), which is [-32512, 32512]. log2(32512)
  //               // = 14.98, which means we can accumulate at least 2^16
  //               // multiplications without overflow. The accumulator is
  //               // applied to a filter so the accumulation logic will hold as
  //               // long as the filter size (filter_y * filter_x * in_channel)
  //               // does not exceed 2^16, which is the case in all the models
  //               // we have seen so far.
  //               // TODO(b/174275578): Add a check to make sure the
  //               // accumulator depth is smaller than 2^16.
  //               acc += filter_val * (input_val + input_offset);
  //             }
  //           }
  //         }
  //
  //         if (bias_data) {
  //           acc += bias_data[out_channel];
  //         }
  //         acc = MultiplyByQuantizedMultiplier(
  //             acc, output_multiplier[out_channel],
  //             output_shift[out_channel]);
  //         acc += output_offset;
  //         acc = std::max(acc, output_activation_min);
  //         acc = std::min(acc, output_activation_max);
  //         output_data[Offset(output_shape, batch, out_y, out_x, out_channel)]
  //         =
  //             static_cast<int8_t>(acc);
  //       }
  //     }
  //   }
  // }

  return kTfLiteOk;
}

TFLMRegistration Register_GMSV_CONV_2D() {
  return tflite::micro::RegisterOp(tflite::ConvInit, tflite::ConvPrepare,
                                   GmsvConvEval);
}

} // namespace adam::tflm_ext
