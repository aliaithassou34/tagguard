#include <cstdint>

#include "adam/Tensor/Conv2D.h"

namespace adam::tensor {

template <typename T, typename U>
Conv2D<T, U>::Conv2D(int ic, int ih, int iw, int oc, int kh, int kw, int sh,
                  int sw, int pt, int pl, int dh, int dw, int n, int g)
    : ic_(ic), ih_(ih), iw_(iw), oc_(oc), kh_(kh), kw_(kw), sh_(sh), sw_(sw),
      pt_(pt), pl_(pl), dh_(dh), dw_(dw), n_(n), g_(g) {}

template <typename T, typename U>
void Conv2D<T, U>::run(const T *input, const T *weights, const U *bias,
                    U *output) const {

  const int ic = this->ic();
  const int oc = this->oc();
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

  const int ihw = this->ihw();
  const int ichw = this->ichw();
  const int ohw = this->ohw();
  const int ochw = this->ochw();

  const int khw = kh * kw;    // weights per kernel
  const int kchw = icg * khw; // weights per output channel

  for (int i_n = 0; i_n < n; ++i_n) {
    const int in_off = i_n * ichw;
    const int out_off = i_n * ochw;

    for (int i_g = 0; i_g < g; ++i_g) {
      const int ic_base = i_g * icg;
      const int oc_base = i_g * ocg;

      for (int i_oc = 0; i_oc < ocg; ++i_oc) {
        const int oc_idx = oc_base + i_oc;

        for (int i_oh = 0; i_oh < oh; ++i_oh) {
          const int ih_start = i_oh * sh - pt;

          for (int i_ow = 0; i_ow < ow; ++i_ow) {
            const int iw_start = i_ow * sw - pl;
            U sum = static_cast<U>(0);

            for (int i_ic = 0; i_ic < icg; ++i_ic) {
              const int ic_idx = ic_base + i_ic;
              const int w_base = oc_idx * kchw + i_ic * khw;

              for (int i_kh = 0; i_kh < kh; ++i_kh) {
                const int ih_idx = ih_start + i_kh * dh;
                if (ih_idx < 0 || ih_idx >= ih)
                  continue;

                for (int i_kw = 0; i_kw < kw; ++i_kw) {
                  const int iw_idx = iw_start + i_kw * dw;
                  if (iw_idx < 0 || iw_idx >= iw)
                    continue;

                  const T in_val =
                      input[in_off + ic_idx * ihw + ih_idx * iw + iw_idx];
                  const T w_val = weights[w_base + i_kh * kw + i_kw];

                  sum += in_val * w_val;
                }
              }
            }

            if (bias)
              sum += bias[oc_idx];

            output[out_off + oc_idx * ohw + i_oh * ow + i_ow] = sum;
          }
        }
      }
    }
  }
}

template class Conv2D<float, float>;
template class Conv2D<int32_t, int32_t>;

} // namespace adam::tensor
