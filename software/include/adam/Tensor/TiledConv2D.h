#ifndef ADAM_TENSOR_TILED_CONV2D_H
#define ADAM_TENSOR_TILED_CONV2D_H

#include "adam/Tensor/Conv2D.h"
#include "adam/Tensor/Gemm.h"
#include "adam/Tensor/TiledGemm.h"

namespace adam::tensor {

template <typename T, typename U> class TiledConv2D : public Conv2D<T, U> {
protected:
  const Gemm<T, U> &base_;

public:
  explicit TiledConv2D(const Gemm<T, U> &base, int ic, int ih, int iw, int oc,
                       int kh, int kw, int sh = 1, int sw = 1, int pt = 0,
                       int pl = 0, int dh = 1, int dw = 1, int n = 1,
                       int g = 1);

  void run(const T *input, const T *weights, const U *bias,
           U *output) const override;

  const Gemm<T, U> &base() const { return base_; }

  int colH() const {
    const int kernel_size = this->kh() * this->kw();
    return this->icg() * kernel_size;
  }

  int colW() const { return this->oh() * this->ow(); }

private:
  void im2colGroup(const T *input, int input_batch_offset, int in_chan_base,
                   T *col) const;
};

} // namespace adam::tensor

#endif // ADAM_TENSOR_TILED_CONV2D_H
