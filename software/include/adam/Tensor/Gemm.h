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

#ifndef ADAM_TENSOR_GEMM_H
#define ADAM_TENSOR_GEMM_H

#include <cassert>

#include "adam/Tensor/MulAcc.h"
#include "adam/Tensor/Tensor.h"

namespace adam::tensor {

template <typename T, typename AccT> class Gemm {
protected:
  int m_; // rows of A and R
  int n_; // cols of B and R
  int k_; // cols of A / rows of B

public:
  Gemm(int m, int n, int k) : m_(m), n_(n), k_(k) {}
  virtual ~Gemm() = default;

  // Compute R = A * B + C
  // All matrices are row-major:
  // A: m x k, B: k x n, C: m x n, R: m x n
  virtual void run(const Tensor<T> &a, const Tensor<T> &b,
                   const Tensor<AccT> &c, Tensor<AccT> &r,
                   const MulAcc<T, AccT> &mulAcc) const {

    assert(a.shape() == this->aShape());
    assert(b.shape() == this->bShape());
    assert(c.shape() == this->cShape());
    assert(r.shape() == this->rShape());

    // printf("%d\n", mulAcc(1, 1, 0));

    for (int i = 0; i < m_; ++i) {
      for (int j = 0; j < n_; ++j) {
        AccT sum = static_cast<AccT>(0);
        for (int p = 0; p < k_; ++p) {
          sum = mulAcc(b(p, j), a(i, p), sum);
        }
        r(i, j) = sum + c(i, j);
      }
    }
  }

  int m() const { return m_; }
  int n() const { return n_; }
  int k() const { return k_; }

  const Shape aShape() const { return Shape({m_, k_}); }

  const Shape bShape() const { return Shape({k_, n_}); }

  const Shape cShape() const { return Shape({m_, n_}); }

  const Shape rShape() const { return Shape({m_, n_}); }
};

} // namespace adam::tensor

#endif // ADAM_TENSOR_GEMM_H
