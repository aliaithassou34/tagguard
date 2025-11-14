#ifndef ADAM_TENSOR_CONV2D_H
#define ADAM_TENSOR_CONV2D_H

namespace adam::tensor {

// NCHW layout, grouped convolution.
// input:  [B, IC, IH, IW]
// weight: [OC, IC / G, KH, KW]
// bias:   [OC] (optional; may be nullptr)
// output: [B, OC, OH, OW]
template <typename T, typename U> class Conv2D {
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
         int pt = 0, int pl = 0, int dh = 1, int dw = 1, int n = 1, int g = 1);

  virtual ~Conv2D() = default;

  virtual void run(const T *input, const T *weights, const U *bias,
                   U *output) const;

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

  // output height
  int oh() const {
    const int eff_kh = (kh_ - 1) * dh_ + 1;
    return (ih_ + 2 * pt_ - eff_kh) / sh_ + 1;
  }

  // output width
  int ow() const {
    const int eff_kw = (kw_ - 1) * dw_ + 1;
    return (iw_ + 2 * pl_ - eff_kw) / sw_ + 1;
  }

  int icg() const { return ic_ / g_; }
  int ihw() const { return ih_ * iw_; }
  int ichw() const { return ic_ * ihw(); }
  int ocg() const { return oc_ / g_; }
  int ohw() const { return oh() * ow(); }
  int ochw() const { return oc_ * ohw(); }
  int khw() const { return kh_ * kw_; }
  int kchw() const { return icg() * khw(); }
};

} // namespace adam::tensor

#endif // ADAM_TENSOR_CONV2D_H
