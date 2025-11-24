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

#ifndef ADAM_TENSOR_QUANTMULACC_H
#define ADAM_TENSOR_QUANTMULACC_H

#include "adam/Tensor/MulAcc.h"

namespace adam::tensor {

template <typename T, typename AccT>
class QuantMulAcc : public MulAcc<T, AccT> {
protected:
  AccT aOffset_;

public:
  QuantMulAcc(AccT aOffset = 0) : aOffset_(aOffset) {}
  virtual ~QuantMulAcc() = default;

  virtual AccT mulAcc(const T a, const T b, const AccT c) const {
    AccT a_acc = static_cast<AccT>(a) + aOffset_;
    AccT b_acc = static_cast<AccT>(b);
    return a_acc * b_acc + c;
  }
};

} // namespace adam::tensor

#endif // ADAM_TENSOR_QUANTMULACC_H
