#ifndef ADAM_TENSOR_TILED_GEMM_H
#define ADAM_TENSOR_TILED_GEMM_H

#include "adam/Tensor/Gemm.h"

namespace adam::tensor {

template <typename T, typename U> class TiledGemm : public Gemm<T, U> {
protected:
  const Gemm<T, U> &base_;

public:
  explicit TiledGemm(int m, int n, int k, const Gemm<T, U> &base);

  void run(const T *a, const T *b, const U *c, U *r) const override;

private:
  template <typename V>
  static void zeroPadTile(V *tile, int rows, int cols, const V *src,
                          int src_rows, int src_cols, int start_row,
                          int start_col);

  static void placeTile(const U *tile, int rows, int cols, U *dst, int dst_rows,
                        int dst_cols, int start_row, int start_col);
};

} // namespace adam::tensor

#endif // ADAM_TENSOR_TILED_GEMM_H
