        .section .text.dift_branch_probe, "ax"
        .align  2
        .globl  __dift_branch_emulate_trusted_start
        .globl  __dift_branch_emulate_trusted_end
        .globl  trusted_branch_probe
        .type   trusted_branch_probe, %function
trusted_branch_probe:
__dift_branch_emulate_trusted_start:
        li      t0, 0
        beq     a0, t0, 1f
        li      a0, 1
        ret
1:
        li      a0, 0
        ret
__dift_branch_emulate_trusted_end:
        .size   trusted_branch_probe, . - trusted_branch_probe

        .section .text.default_handler, "ax"
        .balign 256
        .globl  default_handler
        .type   default_handler, %function

        .equ    TF_SIZE,   160
        .equ    TF_TCR,    128
        .equ    TF_MEPC,   132
        .equ    TF_MCAUSE, 136
        .equ    TF_INSN,   140

default_handler:
        addi    sp, sp, -TF_SIZE

        sw      zero,   0(sp)
        sw      ra,     4(sp)
        sw      t0,    20(sp)
        addi    t0, sp, TF_SIZE
        sw      t0,     8(sp)
        sw      gp,    12(sp)
        sw      tp,    16(sp)
        sw      t1,    24(sp)
        sw      t2,    28(sp)
        sw      s0,    32(sp)
        sw      s1,    36(sp)
        sw      a0,    40(sp)
        sw      a1,    44(sp)
        sw      a2,    48(sp)
        sw      a3,    52(sp)
        sw      a4,    56(sp)
        sw      a5,    60(sp)
        sw      a6,    64(sp)
        sw      a7,    68(sp)
        sw      s2,    72(sp)
        sw      s3,    76(sp)
        sw      s4,    80(sp)
        sw      s5,    84(sp)
        sw      s6,    88(sp)
        sw      s7,    92(sp)
        sw      s8,    96(sp)
        sw      s9,   100(sp)
        sw      s10,  104(sp)
        sw      s11,  108(sp)
        sw      t3,   112(sp)
        sw      t4,   116(sp)
        sw      t5,   120(sp)
        sw      t6,   124(sp)

        csrr    t0, 0x7C1
        sw      t0, TF_TCR(sp)
        csrw    0x7C1, zero

        csrr    t1, mepc
        sw      t1, TF_MEPC(sp)
        sw      zero, TF_INSN(sp)

        csrr    t1, mcause
        sw      t1, TF_MCAUSE(sp)
        li      t2, 2
        bne     t1, t2, .Ldift_attack

        lw      t1, TF_MEPC(sp)
        addi    t1, t1, -4
        lw      t2, 0(t1)
        andi    t3, t2, 0x7f
        li      t4, 0x63
        beq     t3, t4, .Ldift_branch_candidate

        lw      t1, TF_MEPC(sp)
        lw      t2, 0(t1)
        andi    t3, t2, 0x7f
        bne     t3, t4, .Ldift_attack

.Ldift_branch_candidate:
        sw      t1, TF_MEPC(sp)
        sw      t2, TF_INSN(sp)

        la      t3, __dift_branch_emulate_trusted_start
        bltu    t1, t3, .Ldift_attack
        la      t4, __dift_branch_emulate_trusted_end
        bgeu    t1, t4, .Ldift_attack

        srli    t3, t2, 15
        andi    t3, t3, 31
        slli    t3, t3, 2
        add     t3, sp, t3
        lw      a0, 0(t3)

        srli    t4, t2, 20
        andi    t4, t4, 31
        slli    t4, t4, 2
        add     t4, sp, t4
        lw      a1, 0(t4)

        li      t5, 0
        srli    t6, t2, 31
        slli    t6, t6, 12
        or      t5, t5, t6
        srli    t6, t2, 25
        andi    t6, t6, 0x3f
        slli    t6, t6, 5
        or      t5, t5, t6
        srli    t6, t2, 8
        andi    t6, t6, 0xf
        slli    t6, t6, 1
        or      t5, t5, t6
        srli    t6, t2, 7
        andi    t6, t6, 1
        slli    t6, t6, 11
        or      t5, t5, t6
        slli    t5, t5, 19
        srai    t5, t5, 19

        srli    t3, t2, 12
        andi    t3, t3, 7
        beq     t3, zero, .Ldift_beq
        li      t4, 1
        beq     t3, t4, .Ldift_bne
        li      t4, 4
        beq     t3, t4, .Ldift_blt
        li      t4, 5
        beq     t3, t4, .Ldift_bge
        li      t4, 6
        beq     t3, t4, .Ldift_bltu
        li      t4, 7
        beq     t3, t4, .Ldift_bgeu
        j       .Ldift_attack

.Ldift_beq:
        beq     a0, a1, .Ldift_taken
        j       .Ldift_not_taken
.Ldift_bne:
        bne     a0, a1, .Ldift_taken
        j       .Ldift_not_taken
.Ldift_blt:
        blt     a0, a1, .Ldift_taken
        j       .Ldift_not_taken
.Ldift_bge:
        bge     a0, a1, .Ldift_taken
        j       .Ldift_not_taken
.Ldift_bltu:
        bltu    a0, a1, .Ldift_taken
        j       .Ldift_not_taken
.Ldift_bgeu:
        bgeu    a0, a1, .Ldift_taken
        j       .Ldift_not_taken

.Ldift_taken:
        add     t1, t1, t5
        j       .Ldift_set_mepc
.Ldift_not_taken:
        addi    t1, t1, 4

.Ldift_set_mepc:
        csrw    mepc, t1
        la      t0, dift_branch_emulate_emulated
        lw      t1, 0(t0)
        addi    t1, t1, 1
        sw      t1, 0(t0)
        li      t1, 0xE001
        la      t0, dift_branch_emulate_status
        sw      t1, 0(t0)
        j       .Ldift_restore

.Ldift_attack:
        lw      t2, TF_MEPC(sp)
        la      t0, dift_branch_emulate_fault_mepc
        sw      t2, 0(t0)
        csrr    t2, mcause
        la      t0, dift_branch_emulate_fault_mcause
        sw      t2, 0(t0)
        lw      t2, TF_INSN(sp)
        la      t0, dift_branch_emulate_fault_insn
        sw      t2, 0(t0)
        li      t1, 0xD1F70002
        la      t0, dift_branch_emulate_status
        sw      t1, 0(t0)
1:
        j       1b

.Ldift_restore:
        lw      t0, TF_TCR(sp)
        csrw    0x7C1, t0

        lw      ra,     4(sp)
        lw      gp,    12(sp)
        lw      tp,    16(sp)
        lw      t0,    20(sp)
        lw      t1,    24(sp)
        lw      t2,    28(sp)
        lw      s0,    32(sp)
        lw      s1,    36(sp)
        lw      a0,    40(sp)
        lw      a1,    44(sp)
        lw      a2,    48(sp)
        lw      a3,    52(sp)
        lw      a4,    56(sp)
        lw      a5,    60(sp)
        lw      a6,    64(sp)
        lw      a7,    68(sp)
        lw      s2,    72(sp)
        lw      s3,    76(sp)
        lw      s4,    80(sp)
        lw      s5,    84(sp)
        lw      s6,    88(sp)
        lw      s7,    92(sp)
        lw      s8,    96(sp)
        lw      s9,   100(sp)
        lw      s10,  104(sp)
        lw      s11,  108(sp)
        lw      t3,   112(sp)
        lw      t4,   116(sp)
        lw      t5,   120(sp)
        lw      t6,   124(sp)
        lw      sp,     8(sp)
        mret