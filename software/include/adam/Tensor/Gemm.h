#ifndef ADAM_TENSOR_GEMM_H
#define ADAM_TENSOR_GEMM_H

#include <cstdlib>

namespace adam::tensor {

template <typename T, typename U> class Gemm {
protected:
  int m_; // rows of A and R
  int n_; // cols of B and R
  int k_; // cols of A / rows of B

public:
  Gemm(int m, int n, int k);
  virtual ~Gemm() = default;

  int m() const { return m_; }
  int n() const { return n_; }
  int k() const { return k_; }

  // Compute R = A * B + C
  // All matrices are row-major:
  // A: m_ x k_, B: k_ x n_, C: m_ x n_, R: m_ x n_
  virtual void run(const T *a, const T *b, const U *c, U *r) const;
};

} // namespace adam::tensor

#endif // ADAM_TENSOR_GEMM_H
