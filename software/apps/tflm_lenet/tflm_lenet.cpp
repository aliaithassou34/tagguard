#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
#include "tensorflow/lite/micro/kernels/conv.h"
#include "tensorflow/lite/core/c/common.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/micro/micro_mutable_op_resolver.h"

#pragma clang diagnostic pop

#include "adam/Binary/lenet_tflite.h"
#include "adam/Binary/mnist_test_1064_bmp.h"
#include "adam/TFLMExt/GmsvConv.h"

#include <cstdint>
#include <cstdio>

#define RETURN_IF_ERROR(expr)                                                  \
  do {                                                                         \
    TfLiteStatus _status = (expr);                                             \
    if (_status != kTfLiteOk)                                                  \
      return _status;                                                          \
  } while (0)

using namespace adam::tflm_ext;
using namespace tflite;

constexpr int kCategoryCount = 10;
constexpr size_t kArenaSize = 28584;

alignas(16) static uint8_t gArena[kArenaSize];
static MicroMutableOpResolver<5> gOpResolver;
static MicroInterpreter *gInterpreter = nullptr;

volatile float gScore[kCategoryCount];

static TfLiteStatus RegisterOps(MicroMutableOpResolver<5> &resolver) {
  RETURN_IF_ERROR(resolver.AddConv2D(Register_GMSV_CONV_2D()));
  RETURN_IF_ERROR(resolver.AddAveragePool2D());
  RETURN_IF_ERROR(resolver.AddQuantize());
  RETURN_IF_ERROR(resolver.AddReshape());
  RETURN_IF_ERROR(resolver.AddFullyConnected());
  return kTfLiteOk;
}

static TfLiteStatus LoadModel(const Model **model) {
  *model = GetModel(adam_binary_lenet_tflite_start);
  if ((*model)->version() != TFLITE_SCHEMA_VERSION) {
    printf("Model version mismatch\n");
    return kTfLiteError;
  }
  return kTfLiteOk;
}

static TfLiteStatus InitInterpreter(const Model *model) {
  RETURN_IF_ERROR(RegisterOps(gOpResolver));

  gInterpreter = new MicroInterpreter(model, gOpResolver, gArena, kArenaSize);
  if (!gInterpreter) {
    printf("Failed to create interpreter\n");
    return kTfLiteError;
  }

  if (gInterpreter->AllocateTensors() != kTfLiteOk) {
    printf("Failed to allocate tensors\n");
    return kTfLiteError;
  }

  return kTfLiteOk;
}

static TfLiteStatus LoadInputImage() {
  const uint8_t *bmp_data = &adam_binary_mnist_test_1064_bmp_start[1078];
  TfLiteTensor *input = gInterpreter->input(0);
  if (!input)
    return kTfLiteError;

  int8_t *data = GetTensorData<int8_t>(input);
  const float scale = input->params.scale;
  const int zero_point = input->params.zero_point;

  for (int y = 0; y < 28; ++y) {
    for (int x = 0; x < 28; ++x) {
      float value = bmp_data[28 * y + x] / 255.0f;
      data[28 * (27 - y) + x] = static_cast<int8_t>(value / scale + zero_point);
    }
  }

  return kTfLiteOk;
}

static TfLiteStatus RunInference() {
  if (gInterpreter->Invoke() != kTfLiteOk) {
    printf("Inference failed\n");
    return kTfLiteError;
  }
  return kTfLiteOk;
}

static TfLiteStatus ReadOutput() {
  TfLiteTensor *output = gInterpreter->output(0);
  if (!output)
    return kTfLiteError;

  const float scale = output->params.scale;
  const int zero_point = output->params.zero_point;
  const int8_t *data = GetTensorData<int8_t>(output);

  for (int i = 0; i < kCategoryCount; ++i)
    gScore[i] = (data[i] - zero_point) * scale;

  return kTfLiteOk;
}

TfLiteStatus RunModel() {
  const Model *model = nullptr;
  RETURN_IF_ERROR(LoadModel(&model));
  RETURN_IF_ERROR(InitInterpreter(model));
  RETURN_IF_ERROR(LoadInputImage());
  RETURN_IF_ERROR(RunInference());
  RETURN_IF_ERROR(ReadOutput());
  return kTfLiteOk;
}

int main() {
  TfLiteStatus status = RunModel();
  if (status != kTfLiteOk)
    printf("Model execution failed\n");

  while (true)
    ;
  return 0;
}
