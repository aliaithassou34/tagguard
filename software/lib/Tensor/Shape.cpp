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

#include "adam/Tensor/Shape.h"

#include <cstdio>

namespace adam::tensor {

Shape::Shape(int ndim, const int *dims) : ndim_(0), dims_(nullptr) {
  if (ndim > 0) {
    dims_ = new int[ndim];
    for (int i = 0; i < ndim; ++i)
      dims_[i] = dims[i];
    ndim_ = ndim;
  } else {
    dims_ = nullptr;
    ndim_ = 0;
  }
}

Shape::Shape(std::initializer_list<int> dims)
    : Shape(dims.size(), dims.begin()) {}

Shape::Shape(const Shape &other) : Shape(other.ndim_, other.dims_) {}

Shape::~Shape() {
  delete[] dims_;
  dims_ = nullptr;
  ndim_ = 0;
}

int Shape::size() const {
  int total = (ndim_ > 0) ? 1 : 0;
  for (int i = 0; i < ndim_; ++i)
    total *= dims_[i];
  return total;
}

void Shape::print() const {
  std::printf("(");
  for (int i = 0; i < ndim_; ++i) {
    std::printf("%d", dims_[i]);
    if (i < ndim_ - 1)
      std::printf(", ");
  }
  std::printf(")");
}

bool Shape::operator==(const Shape &other) const {
  if (ndim_ != other.ndim_)
    return false;
  for (int i = 0; i < ndim_; ++i) {
    if (dims_[i] != other.dims_[i])
      return false;
  }
  return true;
}

bool Shape::operator!=(const Shape &other) const { return !(*this == other); }

} // namespace adam::tensor
