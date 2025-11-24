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

#ifndef ADAM_TENSOR_GMSV_GEMM_H
#define ADAM_TENSOR_GMSV_GEMM_H

#include <cassert>
#include <cstdint>
#include <cstring>

#include "adam/Tensor/MulAcc.h"
#include "adam/Tensor/Tensor.h"

#define CSR_WRITE(CSR, VALUE)                                                  \
  asm volatile("csrrw x0, " #CSR ", %0" ::"r"(VALUE))

#define MVIN(RS1, RS2, CFG)                                                    \
  asm volatile(                                                                \
      ".insn r CUSTOM_0, 0, %c0, x0, %1, %2" ::"i"(((CFG) & 0x3) << 5),        \
      "r"(RS1), "r"(RS2))

#define MVOUT(RS1, RS2, CFG)                                                   \
  asm volatile(                                                                \
      ".insn r CUSTOM_0, 0, %c0, x0, %1, %2" ::"i"((((CFG) & 0x3) << 5) | 1),  \
      "r"(RS1), "r"(RS2))

#define FENCE(CFG)                                                             \
  asm volatile(                                                                \
      ".insn r CUSTOM_0, 0, %c0, x0, x0, x0" ::"i"((((CFG) & 0x3) << 5) | 1))

#define MATMUL_PRELOAD(RS1, RS2, CFG)                                          \
  asm volatile(                                                                \
      ".insn r CUSTOM_0, 1, %c0, x0, %1, %2" ::"i"(((CFG) & 0x3) << 5),        \
      "r"(RS1), "r"(RS2))

#define MATMUL_COMPUTE(RS1, RS2, END, CFG)                                     \
  asm volatile(".insn r CUSTOM_0, 1, %c0, x0, %1, %2" ::"i"(                   \
                   ((((CFG) & 0x3) << 5) | (((END) & 0x1) << 2) | 1)),         \
               "r"(RS1), "r"(RS2))

#define MATMUL(MAT_A, MAT_B, MAT_C, MAT_R, CFG)                                \
  do {                                                                         \
    MATMUL_PRELOAD(MAT_C, MAT_R, CFG);                                         \
    MATMUL_COMPUTE(MAT_A, MAT_B, 1, CFG);                                      \
  } while (0)

namespace adam::tensor {

template <typename T, typename AccT> class GmsvGemm : public Gemm<T, AccT> {

public:
  explicit GmsvGemm(int m, int n, int k) : Gemm<T, AccT>(m, n, k) {
    printf("Init\n");
  }

  virtual void run(const Tensor<T> &a, const Tensor<T> &b,
                   const Tensor<AccT> &c, Tensor<AccT> &r,
                   const MulAcc<T, AccT> &mulAcc) const override {

    std::printf("Hello\n");

    assert(a.shape() == this->aShape());
    assert(b.shape() == this->bShape());
    assert(c.shape() == this->cShape());
    assert(r.shape() == this->rShape());

    assert(this->m() == 4);
    assert(this->n() == 4);
    assert(this->k() == 4);

    uint32_t spad_a = 0x00;
    uint32_t spad_b = 0x08;
    uint32_t spad_c = 0x10;
    uint32_t spad_r = 0x18;

    CSR_WRITE(0x800, 0);
    CSR_WRITE(0x801, 4);
    CSR_WRITE(0x802, 4);
    CSR_WRITE(0x803, 4);

    MVIN(a.data(), spad_a, 0);
    MVIN(b.data(), spad_b, 0);
    MVIN(c.data(), spad_c, 0);
    MATMUL(spad_a, spad_b, spad_c, spad_r, 0);

    for (volatile int i = 0; i < 100; i++)
      ;

    MVOUT(r.data(), spad_r, 0);
  }
};

} // namespace adam::tensor

#endif // ADAM_TENSOR_GMSV_GEMM_H
