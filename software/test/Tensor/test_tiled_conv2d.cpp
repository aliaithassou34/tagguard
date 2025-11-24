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
#include "adam/Tensor/QuantMulAcc.h"
#include "adam/Tensor/Tensor.h"
#include "adam/Tensor/TiledConv2D.h"
#include "adam/Tensor/TiledGemm.h"

using namespace adam::tensor;

typedef struct {
  const char *name;
  int ih;
  int iw;
  int ic;
  int oc;
  int kh;
  int kw;
  int sh;
  int sw;
  int pt;
  int pl;
  int dh;
  int dw;
  int n;
  int g;
} param_t;

static param_t params[11] = {
    {"base", 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1},
    {"kernel", 4, 6, 1, 1, 2, 3, 1, 1, 0, 0, 1, 1, 1, 1},
    {"channel", 1, 1, 2, 3, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1},
    {"stride", 4, 6, 1, 1, 1, 1, 2, 3, 0, 0, 1, 1, 1, 1},
    {"dilation", 4, 6, 1, 1, 1, 1, 1, 1, 0, 0, 2, 3, 1, 1},
    {"padding", 4, 6, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1},
    {"batch", 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 2, 1},
    {"group", 1, 1, 2, 4, 1, 1, 1, 1, 0, 0, 1, 1, 1, 2},
    {"full", 4, 6, 2, 4, 2, 3, 2, 3, 1, 2, 2, 3, 2, 2},
    {"lenet0", 28, 28, 1, 6, 5, 5, 1, 1, 0, 0, 1, 1, 1, 1},
    {"lenet1", 12, 12, 6, 16, 5, 5, 1, 1, 0, 0, 1, 1, 1, 1}};

TEST_GROUP(TiledConv2D){void setup(){} void teardown(){}};

TEST(TiledConv2D, FirstTest) {
  std::printf("\n");

  std::minstd_rand rng(42);

  for (int j = 0; j < 11; ++j) {
    param_t p = params[j];

    std::printf("Case: %s\n", p.name);

    Conv2D<int8_t, int32_t> conv(p.ic, p.ih, p.iw, p.oc, p.kh, p.kw, p.sh, p.sw,
                                 p.pt, p.pl, p.dh, p.dw, p.n, p.g);

    Gemm<int8_t, int32_t> base(2, 2, 2);
    TiledGemm<int8_t, int32_t> tiledGemm(conv.ocg(),
                                         p.n * conv.oh() * conv.ow(),
                                         p.kh * p.kw * conv.icg(), base);

    TiledConv2D<int8_t, int32_t> tiledConv(tiledGemm, p.ic, p.ih, p.iw, p.oc,
                                           p.kh, p.kw, p.sh, p.sw, p.pt, p.pl,
                                           p.dh, p.dw, p.n, p.g);

    Tensor<int8_t> I(conv.inputShape());
    Tensor<int8_t> W(conv.weightShape());
    Tensor<int32_t> B(conv.biasShape());
    Tensor<int32_t> O(conv.outputShape());
    Tensor<int32_t> O_ref(conv.outputShape());

    I.fill_random(-128, 127, rng);
    I.fill_scalar(-128);
    W.fill_random(-128, 127, rng);
    I.fill_scalar(-128);
    B.fill_random(-128, 127, rng);

    QuantMulAcc<int8_t, int32_t> mulAcc(1);
    conv.run(I, W, B, O_ref, mulAcc);
    tiledConv.run(I, W, B, O, mulAcc);

    // std::printf("O: ");
    // O.print();
    // std::printf("\n");
    //
    // std::printf("O_ref: ");
    // O_ref.print();
    // std::printf("\n");

    assert(O == O_ref);
  }
}
