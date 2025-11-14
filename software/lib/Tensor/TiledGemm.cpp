#include <cstdint>
#include <cstring>

#include "adam/Tensor/TiledGemm.h"

namespace adam::tensor {

template <typename T, typename U>
TiledGemm<T, U>::TiledGemm(int m, int n, int k, const Gemm<T, U> &base)
    : Gemm<T, U>(m, n, k), base_(base) {}

template <typename T, typename U>
void TiledGemm<T, U>::run(const T *a, const T *b, const U *c, U *r) const {

  const int m = this->m_;
  const int n = this->n_;
  const int k = this->k_;

  const int bm = base_.m();
  const int bn = base_.n();
  const int bk = base_.k();

  const int m_tiles = (m + bm - 1) / bm;
  const int n_tiles = (n + bn - 1) / bn;
  const int k_tiles = (k + bk - 1) / bk;

  T *a_tile = new T[bm * bk];
  T *b_tile = new T[bk * bn];
  U *c_tile = new U[bm * bn];
  U *res_tile = new U[bm * bn];
  U *acc_tile = new U[bm * bn];

  std::memset(r, 0, m * n * sizeof(U));

  for (int ti = 0; ti < m_tiles; ++ti) {
    for (int tj = 0; tj < n_tiles; ++tj) {
      zeroPadTile(c_tile, bm, bn, c, m, n, ti * bm, tj * bn);
      std::memcpy(acc_tile, c_tile, bm * bn * sizeof(T));

      for (int tt = 0; tt < k_tiles; ++tt) {
        zeroPadTile(a_tile, bm, bk, a, m, k, ti * bm, tt * bk);
        zeroPadTile(b_tile, bk, bn, b, k, n, tt * bk, tj * bn);

        base_.run(a_tile, b_tile, acc_tile, res_tile);
        std::memcpy(acc_tile, res_tile, bm * bn * sizeof(T));
      }

      placeTile(acc_tile, bm, bn, r, m, n, ti * bm, tj * bn);
    }
  }

  delete[] a_tile;
  delete[] b_tile;
  delete[] c_tile;
  delete[] res_tile;
  delete[] acc_tile;
}

template <typename T, typename U>
template <typename V>
void TiledGemm<T, U>::zeroPadTile(V *tile, int rows, int cols, const V *src,
                               int src_rows, int src_cols, int start_row,
                               int start_col) {

  std::memset(tile, 0, rows * cols * sizeof(T));

  const int er = (start_row + rows < src_rows) ? start_row + rows : src_rows;
  const int ec = (start_col + cols < src_cols) ? start_col + cols : src_cols;

  for (int r = start_row; r < er; ++r) {
    for (int c = start_col; c < ec; ++c) {
      int tr = r - start_row;
      int tc = c - start_col;
      tile[tr * cols + tc] = src[r * src_cols + c];
    }
  }
}

template <typename T, typename U>
void TiledGemm<T, U>::placeTile(const U *tile, int rows, int cols, U *dst,
                             int dst_rows, int dst_cols, int start_row,
                             int start_col) {

  const int er = (start_row + rows < dst_rows) ? start_row + rows : dst_rows;
  const int ec = (start_col + cols < dst_cols) ? start_col + cols : dst_cols;

  for (int r = start_row; r < er; ++r) {
    for (int c = start_col; c < ec; ++c) {
      int tr = r - start_row;
      int tc = c - start_col;
      dst[r * dst_cols + c] = tile[tr * cols + tc];
    }
  }
}

template class TiledGemm<float, float>;
template class TiledGemm<int8_t, int32_t>;

} // namespace adam::tensor
