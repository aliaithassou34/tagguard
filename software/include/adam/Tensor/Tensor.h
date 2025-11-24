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

#ifndef ADAM_TENSOR_TENSOR_H
#define ADAM_TENSOR_TENSOR_H

#include <cmath>
#include <cstdio>
#include <initializer_list>
#include <random>
#include <type_traits>

#include "adam/Tensor/Shape.h"

namespace adam::tensor {

template <typename T> class Tensor {
public:
  Tensor(const Shape &shape, T *ptr = nullptr)
      : shape_(shape), data_(ptr ? ptr : new T[shape.size()]),
        owns_data_(ptr == nullptr) {}

  Tensor(std::initializer_list<int> dims, T *ptr = nullptr)
      : Tensor(Shape(dims), ptr) {}

  ~Tensor() {
    if (owns_data_) {
      delete[] data_;
      data_ = nullptr;
    }
  }

  int size() const { return shape_.size(); }

  void print() const {
    if (shape_.ndim() != 2)
      print_flat();
    else
      print_matrix();
  }

  template <typename RngT> void fill_random(T min_val, T max_val, RngT &rng) {
    int len = shape_.size();
    if constexpr (std::is_floating_point_v<T>) {
      std::uniform_real_distribution<T> dist(min_val, max_val);
      for (int i = 0; i < len; ++i)
        data_[i] = dist(rng);
    } else if constexpr (std::is_integral_v<T>) {
      std::uniform_int_distribution<T> dist(min_val, max_val);
      for (int i = 0; i < len; ++i)
        data_[i] = dist(rng);
    }
  }

  void fill_scalar(T scalar) {
    int len = size();
    for (int i = 0; i < len; ++i)
      data_[i] = scalar;
  }

  int index(const int *idx) const {
    int ndim = shape_.ndim();
    const int *dims = shape_.dims();
    int flat = idx[0];
    for (int i = 1; i < ndim; ++i)
      flat = dims[i] * flat + idx[i];
    return flat;
  }

  bool operator==(const Tensor<T> &other) const {
    if (shape_ != other.shape_)
      return false;

    int len = size();
    if constexpr (std::is_floating_point_v<T>) {
      constexpr T eps = static_cast<T>(1e-5);
      for (int i = 0; i < len; ++i) {
        if (std::fabs(data_[i] - other.data_[i]) > eps)
          return false;
      }
    } else {
      for (int i = 0; i < len; ++i) {
        if (data_[i] != other.data_[i])
          return false;
      }
    }
    return true;
  }

  bool operator!=(const Tensor<T> &other) const { return !(*this == other); }

  template <typename... Args> T &operator()(Args... args) {
    int ix[] = {args...};
    return data_[index(ix)];
  }

  template <typename... Args> const T &operator()(Args... args) const {
    int ix[] = {args...};
    return data_[index(ix)];
  }

  const Shape &shape() const { return shape_; }
  T *data() const { return data_; }

private:
  void print_scalar(T v) const {
    if constexpr (std::is_integral_v<T>)
      std::printf("%3d", static_cast<int>(v));
    else
      std::printf("%7.2f", static_cast<double>(v));
  }

  void print_flat() const {
    int len = size();
    shape_.print();
    std::printf(" {");
    for (int i = 0; i < len; ++i) {
      print_scalar(data_[i]);
      if (i < len - 1)
        std::printf(", ");
    }
    std::printf("}");
  }

  void print_matrix() const {
    int rows = shape_[0];
    int cols = shape_[1];
    shape_.print();
    std::printf("\n{");
    for (int i = 0; i < rows; ++i) {
      for (int j = 0; j < cols; ++j) {
        print_scalar(data_[i * cols + j]);
        if (j < cols - 1)
          std::printf(", ");
      }
      if (i < rows - 1)
        std::printf(",\n ");
    }
    std::printf("}\n");
  }

  Shape shape_;
  T *data_;
  bool owns_data_;
};

} // namespace adam::tensor

#endif // ADAM_TENSOR_TENSOR_H
