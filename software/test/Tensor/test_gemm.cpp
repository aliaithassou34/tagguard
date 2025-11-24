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

#include <cstdio>
#include <random>
#include <typeinfo>

#include "CppUTest/TestHarness.h"

#include "adam/Tensor/Gemm.h"
#include "adam/Tensor/MulAcc.h"
#include "adam/Tensor/Tensor.h"

using namespace adam::tensor;

TEST_GROUP(Gemm){void setup(){} void teardown(){}};

template <typename T, typename AccT> void test_gemm(int seed) {
  std::minstd_rand rng(seed);
  std::uniform_int_distribution<> dist(1, 5);

  int m = dist(rng);
  int n = dist(rng);
  int k = dist(rng);

  Tensor<T> A({m, k});
  Tensor<T> B({k, n});
  Tensor<AccT> C({m, n});
  Tensor<AccT> R({m, n});

  MulAcc<T, AccT> mulAcc;

  A.fill_random(-5, 5, rng);
  B.fill_random(-5, 5, rng);
  C.fill_random(-5, 5, rng);

  Gemm<T, AccT> gemm(m, n, k);

  gemm.run(A, B, C, R, mulAcc);

  // A.print();
  // B.print();
  // C.print();
  // R.print();
}

TEST(Gemm, FirstTest) {
  int seed = 42;
  test_gemm<float, float>(seed);
  test_gemm<int, int>(seed);
}
