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

#ifndef ADAM_TENSOR_TILED_CONV2D_H
#define ADAM_TENSOR_TILED_CONV2D_H

#include <cassert>
#include <cstdint>

#include "adam/Tensor/Conv2D.h"
#include "adam/Tensor/Gemm.h"
#include "adam/Tensor/TiledGemm.h"

namespace adam::tensor {

template <typename T, typename AccT>
class TiledConv2D : public Conv2D<T, AccT> {
protected:
  const Gemm<T, AccT> &base_;

public:
  explicit TiledConv2D(const Gemm<T, AccT> &gemm_base, int ic, int ih, int iw,
                       int oc, int kh, int kw, int sh = 1, int sw = 1,
                       int pt = 0, int pl = 0, int dh = 1, int dw = 1,
                       int n = 1, int g = 1)
      : Conv2D<T, AccT>(ic, ih, iw, oc, kh, kw, sh, sw, pt, pl, dh, dw, n, g),
        base_(gemm_base) {}

  virtual void run(const Tensor<T> &input, const Tensor<T> &weight,
                   const Tensor<AccT> &bias, Tensor<AccT> &output,
                   const MulAcc<T, AccT> &mulAcc) const {

    assert(input.shape() == this->inputShape());
    assert(weight.shape() == this->weightShape());
    assert(bias.shape() == this->biasShape());
    assert(output.shape() == this->outputShape());

    int b = this->n();
    int oh = this->oh();
    int ow = this->ow();
    int kh = this->kh();
    int kw = this->kw();
    int icg = this->icg();
    int ocg = this->ocg();
    int g = this->g();

    int m = ocg;
    int n = b * oh * ow;
    int k = kh * kw * icg;

    Tensor<T> gemmB({k, n});
    Tensor<AccT> gemmC({m, n});
    Tensor<AccT> gemmR({m, n});

    for (int i_g = 0; i_g < g; ++i_g) {
      const int ic_off = i_g * icg;
      const int oc_off = i_g * ocg;

      this->im2col(input, gemmB, ic_off);

      for (int i_ocg = 0; i_ocg < ocg; ++i_ocg) {
        const AccT val = bias(i_ocg + oc_off);
        for (int i_n = 0; i_n < n; ++i_n) {
          gemmC(i_ocg, i_n) = val;
        }
      }

      Tensor<T> gemmA(Shape({m, k}), (T *)&weight(oc_off, 0, 0, 0));

      this->base().run(gemmA, gemmB, gemmC, gemmR, mulAcc);

      for (int i_b = 0; i_b < b; ++i_b) {
        for (int i_oh = 0; i_oh < oh; ++i_oh) {
          for (int i_ow = 0; i_ow < ow; ++i_ow) {
            for (int i_ocg = 0; i_ocg < ocg; ++i_ocg) {
              const int i_oc = i_ocg + oc_off;
              const int i_n = (i_b * oh + i_oh) * ow + i_ow;
              output(i_b, i_oh, i_ow, i_oc) = gemmR(i_ocg, i_n);
            }
          }
        }
      }
    }
  }

  const Gemm<T, AccT> &base() const { return base_; }

  int gemm_m() const { return this->ocg(); }
  int gemm_n() const { return this->n() * this->oh() * this->ow(); }
  int gemm_k() const { return this->kh() * this->kw() * this->icg(); }

private:
  void im2col(const Tensor<T> &input, Tensor<T> &col, int ic_off) const {
    const int b = this->n();
    const int ih = this->ih();
    const int iw = this->iw();
    const int ic = this->ic();
    const int oh = this->oh();
    const int ow = this->ow();
    const int kh = this->kh();
    const int kw = this->kw();
    const int sh = this->sh();
    const int sw = this->sw();
    const int pt = this->pt();
    const int pl = this->pl();
    const int dh = this->dh();
    const int dw = this->dw();
    const int icg = this->icg();

    const int ch = this->gemm_k();
    const int cw = this->gemm_n();

    assert(input.shape() == Shape({b, ih, iw, ic}));
    assert(col.shape() == Shape({ch, cw}));

    for (int i_b = 0; i_b < b; ++i_b) {
      for (int i_oh = 0; i_oh < oh; ++i_oh) {
        for (int i_ow = 0; i_ow < ow; ++i_ow) {
          for (int i_kh = 0; i_kh < kh; ++i_kh) {
            for (int i_kw = 0; i_kw < kw; ++i_kw) {
              for (int i_icg = 0; i_icg < icg; ++i_icg) {

                const int i_ch = (i_kh * kw + i_kw) * icg + i_icg;
                const int i_cw = (i_b * oh + i_oh) * ow + i_ow;

                const int i_ih = i_oh * sh + i_kh * dh - pt;
                const int i_iw = i_ow * sw + i_kw * dw - pl;
                const int i_ic = i_icg + ic_off;

                if (i_ih >= 0 && i_ih < ih && i_iw >= 0 && i_iw < iw) {
                  col(i_ch, i_cw) = input(i_b, i_ih, i_iw, i_ic);
                } else {
                  col(i_ch, i_cw) = static_cast<T>(0);
                }
              }
            }
          }
        }
      }
    }
  }
};

} // namespace adam::tensor

#endif // ADAM_TENSOR_TILED_CONV2D_H
