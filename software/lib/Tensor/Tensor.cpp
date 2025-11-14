#include <cstdio>
#include <random>

#include "adam/Tensor/Shape.h"
#include "adam/Tensor/Tensor.h"

namespace adam::tensor {

template <typename T>
Tensor<T>::Tensor(const Shape &shape) : shape_(shape), data_(nullptr) {
  data_ = new T[shape.size()];
}

template <typename T>
Tensor<T>::Tensor(std::initializer_list<int> dims) : Tensor(Shape(dims)) {}

template <typename T> Tensor<T>::~Tensor() {
  delete[] data_;
  data_ = nullptr;
}

template <typename T> int Tensor<T>::size() const { return shape_.size(); }

template <typename T> void Tensor<T>::print() const {
  if (shape_.ndim() != 2) {
    print_flat();
  } else {
    print_matrix();
  }
}

template <typename T>
void Tensor<T>::fill_random(T min_val, T max_val, std::mt19937 &rng) {
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

template <typename T> void Tensor<T>::fill_scalar(T scalar) {
  int len = size();
  for (int i = 0; i < len; ++i)
    data_[i] = scalar;
}

template <typename T> bool Tensor<T>::operator==(const Tensor<T> &other) const {
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

template <typename T> bool Tensor<T>::operator!=(const Tensor<T> &other) const {
  return !(*this == other);
}

template <typename T> void Tensor<T>::print_flat() const {
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

template <typename T> void Tensor<T>::print_matrix() const {
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

template <typename T> void Tensor<T>::print_scalar(T scalar) const {
  if constexpr (std::is_integral_v<T>) {
    std::printf("%3d", static_cast<int>(scalar));
  } else {
    std::printf("%7.2f", static_cast<double>(scalar));
  }
}

template class Tensor<float>;
template class Tensor<int>;

} // namespace adam::tensor
