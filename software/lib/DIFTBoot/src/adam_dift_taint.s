/* void adam_dift_taint_region(void *buf, size_t len, uint8_t tainted_zero);
 * ORs tainted_zero (value 0, tag 1) into each byte to set its tag in place.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

        .section .text
        .globl adam_dift_taint_region
        .type  adam_dift_taint_region, @function

adam_dift_taint_region:
        beqz    a1, .Ltaint_done
.Ltaint_loop:
        lb      t0, 0(a0)
        or      t0, t0, a2      # tag(t0) |= tag(a2)=1 ; value = t0|0 = t0
        sb      t0, 0(a0)
        addi    a0, a0, 1
        addi    a1, a1, -1
        bnez    a1, .Ltaint_loop
.Ltaint_done:
        ret

        .size adam_dift_taint_region, . - adam_dift_taint_region
