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

#ifndef ADAM_TENSOR_TILED_GEMM_H
#define ADAM_TENSOR_TILED_GEMM_H

#include <cassert>
#include <cstring>

#include "adam/Tensor/MulAcc.h"
#include "adam/Tensor/Tensor.h"

namespace adam::tensor {

template <typename T, typename AccT> class TiledGemm : public Gemm<T, AccT> {
protected:
  const Gemm<T, AccT> &base_;

public:
  explicit TiledGemm(int m, int n, int k, const Gemm<T, AccT> &base)
      : Gemm<T, AccT>(m, n, k), base_(base) {}

  virtual void run(const Tensor<T> &a, const Tensor<T> &b,
                   const Tensor<AccT> &c, Tensor<AccT> &r,
                   const MulAcc<T, AccT> &mulAcc) const override {

    assert(a.shape() == this->aShape());
    assert(b.shape() == this->bShape());
    assert(c.shape() == this->cShape());
    assert(r.shape() == this->rShape());

    const int m = this->m_;
    const int n = this->n_;
    const int k = this->k_;

    const int bm = base_.m();
    const int bn = base_.n();
    const int bk = base_.k();

    const int m_tiles = (m + bm - 1) / bm;
    const int n_tiles = (n + bn - 1) / bn;
    const int k_tiles = (k + bk - 1) / bk;

    Tensor<T> a_tile({bm, bk});
    Tensor<T> b_tile({bk, bn});
    Tensor<AccT> c_tile({bm, bn});
    Tensor<AccT> res_tile({bm, bn});
    Tensor<AccT> acc_tile({bm, bn});

    r.fill_scalar(0);

    std::printf("Test\n");

    for (int ti = 0; ti < m_tiles; ++ti) {
      for (int tj = 0; tj < n_tiles; ++tj) {
        zeroPadTile(c_tile, bm, bn, c, m, n, ti * bm, tj * bn);
        std::memcpy(acc_tile.data(), c_tile.data(), bm * bn * sizeof(AccT));

        for (int tt = 0; tt < k_tiles; ++tt) {
          zeroPadTile(a_tile, bm, bk, a, m, k, ti * bm, tt * bk);
          zeroPadTile(b_tile, bk, bn, b, k, n, tt * bk, tj * bn);

          base_.run(a_tile, b_tile, acc_tile, res_tile, mulAcc);

          std::memcpy(acc_tile.data(), res_tile.data(), bm * bn * sizeof(AccT));
        }

        placeTile(acc_tile, bm, bn, r, m, n, ti * bm, tj * bn);
      }
    }
  }

private:
  template <typename U>
  static void zeroPadTile(Tensor<U> &tile, int rows, int cols,
                          const Tensor<U> &src, int src_rows, int src_cols,
                          int start_row, int start_col) {

    tile.fill_scalar(0);

    const int er = (start_row + rows < src_rows) ? start_row + rows : src_rows;
    const int ec = (start_col + cols < src_cols) ? start_col + cols : src_cols;

    for (int r = start_row; r < er; ++r) {
      for (int c = start_col; c < ec; ++c) {
        int tr = r - start_row;
        int tc = c - start_col;
        tile(tr, tc) = src(r, c);
      }
    }
  }

  static void placeTile(const Tensor<AccT> &tile, int rows, int cols,
                        Tensor<AccT> &dst, int dst_rows, int dst_cols,
                        int start_row, int start_col) {

    const int er = (start_row + rows < dst_rows) ? start_row + rows : dst_rows;
    const int ec = (start_col + cols < dst_cols) ? start_col + cols : dst_cols;

    for (int r = start_row; r < er; ++r) {
      for (int c = start_col; c < ec; ++c) {
        int tr = r - start_row;
        int tc = c - start_col;
        dst(r, c) = tile(tr, tc);
      }
    }
  }
};

} // namespace adam::tensor

#endif // ADAM_TENSOR_TILED_GEMM_H
