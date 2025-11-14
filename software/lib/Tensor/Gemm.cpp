#include <cstdint>

#include "adam/Tensor/Gemm.h"

namespace adam::tensor {

template <typename T, typename U>
Gemm<T, U>::Gemm(int m, int n, int k) : m_(m), n_(n), k_(k) {}

template <typename T, typename U>
void Gemm<T, U>::run(const T *a, const T *b, const U *c, U *r) const {
  for (int i = 0; i < m_; ++i) {
    for (int j = 0; j < n_; ++j) {
      T sum = static_cast<T>(0);
      for (int p = 0; p < k_; ++p) {
        sum += a[i * k_ + p] * b[p * n_ + j];
      }
      r[i * n_ + j] = sum + c[i * n_ + j];
    }
  }
}

template class Gemm<float, float>;
template class Gemm<int8_t, int32_t>;

} // namespace adam::tensor
