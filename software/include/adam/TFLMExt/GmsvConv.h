#ifndef ADAM_TFLMEXT_GMSVCONV_H
#define ADAM_TFLMEXT_GMSVCONV_H

#include <cstdint>

#include "tensorflow/lite/c/builtin_op_data.h"
#include "tensorflow/lite/c/common.h"
#include "tensorflow/lite/kernels/internal/types.h"
#include "tensorflow/lite/micro/micro_common.h"

namespace adam::tflm_ext {

TfLiteStatus GmsvConvEval(TfLiteContext *context, TfLiteNode *node);

TFLMRegistration Register_GMSV_CONV_2D();

} // namespace adam::tflm_ext

#endif // ADAM_TFLMEXT_GMSVCONV_H
