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
