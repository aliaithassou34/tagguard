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

#ifndef ADAM_TENSOR_CONV2D_H
#define ADAM_TENSOR_CONV2D_H

#include "adam/Tensor/MulAcc.h"
#include "adam/Tensor/Tensor.h"

namespace adam::tensor {

// NCHW layout, grouped convolution.
// input:  [B, IH, IW, IC]
// weight: [OC, KH, KW, IC / G]
// bias:   [OC] (optional; may be nullptr)
// output: [B, OH, OW, OC]
template <typename T, typename AccT> class Conv2D {
protected:
  int ic_; // input channels
  int ih_; // input height
  int iw_; // input width
  int oc_; // output channels
  int kh_; // kernel height
  int kw_; // kernel width
  int sh_; // stride height
  int sw_; // stride width
  int pt_; // padding top
  int pl_; // padding left
  int dh_; // dilation height
  int dw_; // dilation width
  int n_;  // batches
  int g_;  // groups

public:
  Conv2D(int ic, int ih, int iw, int oc, int kh, int kw, int sh = 1, int sw = 1,
         int pt = 0, int pl = 0, int dh = 1, int dw = 1, int n = 1, int g = 1)
      : ic_(ic), ih_(ih), iw_(iw), oc_(oc), kh_(kh), kw_(kw), sh_(sh), sw_(sw),
        pt_(pt), pl_(pl), dh_(dh), dw_(dw), n_(n), g_(g) {}

  virtual ~Conv2D() = default;

  virtual void run(const Tensor<T> &input, const Tensor<T> &weight,
                   const Tensor<AccT> &bias, Tensor<AccT> &output,
                   const MulAcc<T, AccT> &mulAcc) const {

    assert(input.shape() == this->inputShape());
    assert(weight.shape() == this->weightShape());
    assert(bias.shape() == this->biasShape());
    assert(output.shape() == this->outputShape());

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
    const int n = this->n();
    const int g = this->g();
    const int oh = this->oh();
    const int ow = this->ow();
    const int icg = this->icg();
    const int ocg = this->ocg();

    for (int i_n = 0; i_n < n; ++i_n) {
      for (int i_g = 0; i_g < g; ++i_g) {
        const int ic_base = i_g * icg;
        const int oc_base = i_g * ocg;

        for (int i_oc = 0; i_oc < ocg; ++i_oc) {
          const int oc_idx = oc_base + i_oc;

          for (int i_oh = 0; i_oh < oh; ++i_oh) {
            const int ih_start = i_oh * sh - pt;

            for (int i_ow = 0; i_ow < ow; ++i_ow) {
              const int iw_start = i_ow * sw - pl;
              AccT sum = static_cast<AccT>(0);

              for (int i_ic = 0; i_ic < icg; ++i_ic) {
                const int ic_idx = ic_base + i_ic;

                for (int i_kh = 0; i_kh < kh; ++i_kh) {
                  const int ih_idx = ih_start + i_kh * dh;
                  if (ih_idx < 0 || ih_idx >= ih)
                    continue;

                  for (int i_kw = 0; i_kw < kw; ++i_kw) {
                    const int iw_idx = iw_start + i_kw * dw;
                    if (iw_idx < 0 || iw_idx >= iw)
                      continue;

                    const T in_val = input(i_n, ih_idx, iw_idx, ic_idx);
                    const T w_val = weight(oc_idx, i_kh, i_kw, i_ic);
                    sum = mulAcc(in_val, w_val, sum);
                  }
                }
              }

              // if (bias)
              sum += bias(oc_idx);

              output(i_n, i_oh, i_ow, oc_idx) = sum;
            }
          }
        }
      }
    }
  }

  void print() const {
    std::printf("Conv2D(ih: %d, iw: %d, ic: %d, oc: %d, kh: %d, kw: %d, sh: "
                "%d, sw: %d, "
                "pt: %d, pl: %d, dh: %d, dw: %d, n: %d, g: %d)\n",
                ih_, iw_, ic_, oc_, kh_, kw_, sh_, sw_, pt_, pl_, dh_, dw_, n_,
                g_);
  }

  int ic() const { return ic_; }
  int ih() const { return ih_; }
  int iw() const { return iw_; }
  int oc() const { return oc_; }
  int kh() const { return kh_; }
  int kw() const { return kw_; }
  int sh() const { return sh_; }
  int sw() const { return sw_; }
  int pt() const { return pt_; }
  int pl() const { return pl_; }
  int dh() const { return dh_; }
  int dw() const { return dw_; }
  int n() const { return n_; }
  int g() const { return g_; }

  // Output Height
  int oh() const {
    const int eff_kh = (kh_ - 1) * dh_ + 1;
    return (ih_ + 2 * pt_ - eff_kh) / sh_ + 1;
  }

  // Output Width
  int ow() const {
    const int eff_kw = (kw_ - 1) * dw_ + 1;
    return (iw_ + 2 * pl_ - eff_kw) / sw_ + 1;
  }

  // Input Channels per Group
  int icg() const { return ic_ / g_; }

  // Output Channels per Group
  int ocg() const { return oc_ / g_; }

  const Shape inputShape() const { return Shape({n_, ih_, iw_, ic_}); }

  const Shape weightShape() const { return Shape({oc_, kh_, kw_, icg()}); }

  const Shape biasShape() const { return Shape({oc_}); }

  const Shape outputShape() const { return Shape({n_, oh(), ow(), oc_}); }

  int ihw() const { return ih_ * iw_; }
  int ichw() const { return ic_ * ihw(); }

  int ohw() const { return oh() * ow(); }
  int ochw() const { return oc_ * ohw(); }
  int khw() const { return kh_ * kw_; }
  int kchw() const { return icg() * khw(); }
};

} // namespace adam::tensor

#endif // ADAM_TENSOR_CONV2D_H
