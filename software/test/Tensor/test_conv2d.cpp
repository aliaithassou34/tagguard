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

#include <cassert>
#include <cstdio>
#include <random>
#include <typeinfo>

#include "CppUTest/TestHarness.h"

#include "adam/Tensor/Conv2D.h"
#include "adam/Tensor/MulAcc.h"
#include "adam/Tensor/Tensor.h"

using namespace adam::tensor;

TEST_GROUP(Conv2D){void setup(){} void teardown(){}};

TEST(Conv2D, FirstTest) {
  std::printf("\n");

  FILE *fp = std::fopen("lib/Binary/oracle_conv2d.txt", "r");
  CHECK_TRUE(fp != nullptr);

  char name[20];
  int ic, ih, iw, oc, kh, kw;
  int sh, sw, pt, pl, dh, dw, n, g, oh, ow;

  while (true) {
    int nread =
        std::fscanf(fp, "%19s %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d",
                    name, &ih, &iw, &ic, &oc, &kh, &kw, &sh, &sw, &pt, &pl, &dh,
                    &dw, &n, &g, &oh, &ow);
    if (nread != 17)
      break; // EOF reached

    std::printf("Case: %s\n", name);

    Conv2D<float, float> conv(ic, ih, iw, oc, kh, kw, sh, sw, pt, pl, dh, dw, n,
                              g);

    Tensor<float> I(conv.inputShape());
    Tensor<float> W(conv.weightShape());
    Tensor<float> B(conv.biasShape());
    Tensor<float> O(conv.outputShape());
    Tensor<float> O_ref(conv.outputShape());

    // Read oracle tensors (floats)
    for (int i = 0; i < I.size(); ++i)
      assert(fscanf(fp, "%f", &I.data()[i]) == 1);
    for (int i = 0; i < W.size(); ++i)
      assert(fscanf(fp, "%f", &W.data()[i]) == 1);
    for (int i = 0; i < B.size(); ++i)
      assert(fscanf(fp, "%f", &B.data()[i]) == 1);
    for (int i = 0; i < O_ref.size(); ++i)
      assert(fscanf(fp, "%f", &O_ref.data()[i]) == 1);

    MulAcc<float, float> mulAcc;
    conv.run(I, W, B, O, mulAcc);

    // std::printf("O: ");
    // O.print();
    // std::printf("\n");
    //
    // std::printf("O_ref: ");
    // O_ref.print();
    // std::printf("\n");

    assert(O == O_ref);
  }

  std::fclose(fp);
}
