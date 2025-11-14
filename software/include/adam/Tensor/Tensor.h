#ifndef ADAM_TENSOR_TENSOR_H
#define ADAM_TENSOR_TENSOR_H

#include <initializer_list>
#include <random>

#include "adam/Tensor/Shape.h"

namespace adam::tensor {

template <typename T> class Tensor {
public:
  Tensor(const Shape &shape);
  Tensor(std::initializer_list<int> dims);
  ~Tensor();

  int size() const;
  void print() const;
  void fill_random(T min_val, T max_val, std::mt19937 &rng);
  void fill_scalar(T scalar);

  bool operator==(const Tensor<T> &other) const;
  bool operator!=(const Tensor<T> &other) const;

  Shape &shape() { return shape_; };
  T *data() { return data_; }

private:
  void print_flat() const;
  void print_matrix() const;
  void print_scalar(T scalar) const;

  Shape shape_;
  T *data_;
};

} // namespace adam::tensor

#endif // ADAM_TENSOR_TENSOR_H
