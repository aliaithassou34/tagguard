#include <cstdint>

#include "adam/Tensor/TiledConv2D.h"

namespace adam::tensor {

template <typename T, typename U>
TiledConv2D<T, U>::TiledConv2D(const Gemm<T, U> &base, int ic, int ih, int iw, int oc,
                            int kh, int kw, int sh, int sw, int pt, int pl,
                            int dh, int dw, int n, int g)
    : Conv2D<T, U>(ic, ih, iw, oc, kh, kw, sh, sw, pt, pl, dh, dw, n, g),
      base_(base) {}

template <typename T, typename U>
void TiledConv2D<T, U>::run(const T *input, const T *weights, const U *bias,
                         U *output) const {
  const int n = this->n();
  const int g = this->g();
  const int ocg = this->ocg();
  const int icg = this->icg();

  const int ichw = this->ichw();
  const int ochw = this->ochw();
  const int ohw = this->ohw();
  const int kchw = this->kchw();

  const TiledGemm<T, U> tiled_gemm(ocg, ohw, kchw, this->base());

  T *col = new T[kchw * ohw];
  U *gemm_in = new U[ochw];
  U *gemm_out = new U[ochw];

  for (int i_n = 0; i_n < n; ++i_n) {
    const int in_off = i_n * ichw;
    const int out_off = i_n * ochw;

    for (int i_g = 0; i_g < g; ++i_g) {
      const int ic_base = i_g * icg;
      const int oc_base = i_g * ocg;

      // 1) im2col for this (batch, group)
      this->im2colGroup(input, in_off, ic_base, col);

      // 2) Initialize gemm_in
      for (int i_oc = 0; i_oc < ocg; ++i_oc) {
        const U val = bias ? bias[oc_base + i_oc] : static_cast<U>(0);
        for (int i_ohw = 0; i_ohw < ohw; ++i_ohw) {
          gemm_in[i_oc * ohw + i_ohw] = val;
        }
      }

      // 2) GEMM: (OCg x kchw) * (kchw x ohw) -> (OCg x ohw)
      const T *Wg = weights + oc_base * kchw;

      tiled_gemm.run(Wg, col, gemm_in, gemm_out);

      U *Yg = output + out_off + oc_base * ohw;
      for (int i = 0; i < ocg * ohw; i++) {
        Yg[i] = gemm_out[i];
      }
    }
  }

  delete[] col;
  delete[] gemm_in;
  delete[] gemm_out;
}

template <typename T, typename U>
void TiledConv2D<T, U>::im2colGroup(const T *input, int in_off, int ic_base,
                                 T *col) const {
  const int ih = this->ih();
  const int iw = this->iw();
  const int kh = this->kh();
  const int kw = this->kw();
  const int sh = this->sh();
  const int sw = this->sw();
  const int pt = this->pt();
  const int pl = this->pl();
  const int dh = this->dh();
  const int dw = this->dw();
  const int oh = this->oh();
  const int ow = this->ow();
  const int icg = this->icg();
  const int ihw = this->ihw();
  const int ohw = this->ohw();
  const int khw = this->khw();

  for (int i_ic = 0; i_ic < icg; ++i_ic) {
    const int ic = ic_base + i_ic;
    const int input_c_offset = in_off + ic * ihw;

    for (int i_kh = 0; i_kh < kh; ++i_kh) {
      const int kH = i_kh * dh;

      for (int i_kw = 0; i_kw < kw; ++i_kw) {
        const int kW = i_kw * dw;
        const int col_row = i_ic * khw + i_kh * kw + i_kw;
        T *row_ptr = col + col_row * ohw;

        for (int i_oh = 0; i_oh < oh; ++i_oh) {
          const int ih_idx = i_oh * sh - pt + kH;
          const bool h_valid = (ih_idx >= 0 && ih_idx < ih);
          const int out_col_base = i_oh * ow;

          if (!h_valid) {
            for (int i_ow = 0; i_ow < ow; ++i_ow)
              row_ptr[out_col_base + i_ow] = static_cast<T>(0);
            continue;
          }

          for (int i_ow = 0; i_ow < ow; ++i_ow) {
            const int iw_idx = i_ow * sw - pl + kW;
            if (iw_idx < 0 || iw_idx >= iw)
              row_ptr[out_col_base + i_ow] = static_cast<T>(0);
            else
              row_ptr[out_col_base + i_ow] =
                  input[input_c_offset + ih_idx * iw + iw_idx];
          }
        }
      }
    }
  }
}

template class TiledConv2D<float, float>;
template class TiledConv2D<int8_t, int32_t>;

} // namespace adam::tensor
