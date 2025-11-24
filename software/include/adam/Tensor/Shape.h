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

#ifndef ADAM_TENSOR_SHAPE_H
#define ADAM_TENSOR_SHAPE_H

#include <initializer_list>

namespace adam::tensor {

class Shape {
public:
  Shape(int ndim, const int *dims);
  Shape(std::initializer_list<int> dims);
  Shape(const Shape &other);
  ~Shape();

  int size() const;
  void print() const;
  void assert_equal(const Shape &other) const;

  int ndim() const { return ndim_; }
  int *dims() const { return dims_; }

  Shape &operator=(const Shape &other) = delete;
  int operator[](int i) const { return dims_[i]; }
  bool operator==(const Shape &other) const;
  bool operator!=(const Shape &other) const;

private:
  int ndim_;
  int *dims_;
};

} // namespace adam::tensor

#endif // ADAM_TENSOR_SHAPE_H
