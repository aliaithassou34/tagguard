        .section .text.default_handler, "ax"
        .balign 256
        .globl  default_handler
        .type   default_handler, %function

        .equ    TF_SIZE,   160
        .equ    TF_TCR,    128
        .equ    TF_MEPC,   132
        .equ    TF_MCAUSE, 136
        .equ    TF_INSN,   140
        .equ    TF_ENTRY_CYCLE, 144

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

        csrr    t0, mcycle
        sw      t0, TF_ENTRY_CYCLE(sp)

        csrr    t1, mepc
        sw      t1, TF_MEPC(sp)
        sw      zero, TF_INSN(sp)

        csrr    t1, mcause
        sw      t1, TF_MCAUSE(sp)
        li      t2, 2
        bne     t1, t2, .Ladam_dift_attack

        lw      t1, TF_MEPC(sp)
        lhu     t2, 0(t1)
        andi    t3, t2, 3
        li      t4, 1
        bne     t3, t4, .Ladam_dift_try_b_raw_at_mepc
        srli    t3, t2, 13
        andi    t3, t3, 7
        li      t4, 6
        beq     t3, t4, .Ladam_dift_branch_candidate
        li      t4, 7
        beq     t3, t4, .Ladam_dift_branch_candidate

.Ladam_dift_try_b_raw_at_mepc:
        andi    t3, t2, 3
        li      t4, 3
        bne     t3, t4, .Ladam_dift_try_b_m2
        lw      t2, 0(t1)
        andi    t3, t2, 0x7f
        li      t4, 0x63
        beq     t3, t4, .Ladam_dift_branch_candidate

.Ladam_dift_try_b_m2:
        lw      t1, TF_MEPC(sp)
        addi    t1, t1, -2
        lhu     t2, 0(t1)
        andi    t3, t2, 3
        li      t4, 1
        bne     t3, t4, .Ladam_dift_try_b_m4
        srli    t3, t2, 13
        andi    t3, t3, 7
        li      t4, 6
        beq     t3, t4, .Ladam_dift_branch_candidate
        li      t4, 7
        beq     t3, t4, .Ladam_dift_branch_candidate

.Ladam_dift_try_b_m4:
        lw      t1, TF_MEPC(sp)
        addi    t1, t1, -4
        lw      t2, 0(t1)
        andi    t3, t2, 0x7f
        li      t4, 0x63
        beq     t3, t4, .Ladam_dift_branch_candidate

        j       .Ladam_dift_attack

.Ladam_dift_branch_candidate:
        sw      t1, TF_MEPC(sp)
        sw      t2, TF_INSN(sp)

        mv      a0, t1
        call    adam_dift_should_emulate_branch
        beqz    a0, .Ladam_dift_attack

        lw      t1, TF_MEPC(sp)
        lw      t2, TF_INSN(sp)

        andi    t3, t2, 3
        li      t4, 3
        bne     t3, t4, .Ladam_dift_cbranch

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
        beq     t3, zero, .Ladam_dift_beq
        li      t4, 1
        beq     t3, t4, .Ladam_dift_bne
        li      t4, 4
        beq     t3, t4, .Ladam_dift_blt
        li      t4, 5
        beq     t3, t4, .Ladam_dift_bge
        li      t4, 6
        beq     t3, t4, .Ladam_dift_bltu
        li      t4, 7
        beq     t3, t4, .Ladam_dift_bgeu
        j       .Ladam_dift_attack

.Ladam_dift_beq:
        beq     a0, a1, .Ladam_dift_taken
        j       .Ladam_dift_not_taken
.Ladam_dift_bne:
        bne     a0, a1, .Ladam_dift_taken
        j       .Ladam_dift_not_taken
.Ladam_dift_blt:
        blt     a0, a1, .Ladam_dift_taken
        j       .Ladam_dift_not_taken
.Ladam_dift_bge:
        bge     a0, a1, .Ladam_dift_taken
        j       .Ladam_dift_not_taken
.Ladam_dift_bltu:
        bltu    a0, a1, .Ladam_dift_taken
        j       .Ladam_dift_not_taken
.Ladam_dift_bgeu:
        bgeu    a0, a1, .Ladam_dift_taken
        j       .Ladam_dift_not_taken

.Ladam_dift_cbranch:
        srli    t3, t2, 7
        andi    t3, t3, 7
        addi    t3, t3, 8
        slli    t3, t3, 2
        add     t3, sp, t3
        lw      a0, 0(t3)

        li      t5, 0
        srli    t6, t2, 12
        andi    t6, t6, 1
        slli    t6, t6, 8
        or      t5, t5, t6
        srli    t6, t2, 10
        andi    t6, t6, 3
        slli    t6, t6, 3
        or      t5, t5, t6
        srli    t6, t2, 5
        andi    t6, t6, 3
        slli    t6, t6, 6
        or      t5, t5, t6
        srli    t6, t2, 3
        andi    t6, t6, 3
        slli    t6, t6, 1
        or      t5, t5, t6
        srli    t6, t2, 2
        andi    t6, t6, 1
        slli    t6, t6, 5
        or      t5, t5, t6
        slli    t5, t5, 23
        srai    t5, t5, 23

        srli    t3, t2, 13
        andi    t3, t3, 7
        li      t4, 6
        beq     t3, t4, .Ladam_dift_cbeqz
        li      t4, 7
        beq     t3, t4, .Ladam_dift_cbnez
        j       .Ladam_dift_attack

.Ladam_dift_cbeqz:
        beq     a0, zero, .Ladam_dift_taken
        j       .Ladam_dift_c_not_taken
.Ladam_dift_cbnez:
        bne     a0, zero, .Ladam_dift_taken
        j       .Ladam_dift_c_not_taken

.Ladam_dift_c_not_taken:
        addi    t1, t1, 2
        j       .Ladam_dift_set_mepc

.Ladam_dift_taken:
        add     t1, t1, t5
        j       .Ladam_dift_set_mepc
.Ladam_dift_not_taken:
        addi    t1, t1, 4

.Ladam_dift_set_mepc:
        csrw    mepc, t1
        la      t0, adam_dift_runtime_emulated
        lw      t1, 0(t0)
        addi    t1, t1, 1
        sw      t1, 0(t0)
        li      t1, 0xE001
        la      t0, adam_dift_runtime_status
        sw      t1, 0(t0)
        j       .Ladam_dift_restore

.Ladam_dift_attack:
        lw      t2, TF_MEPC(sp)
        la      t0, adam_dift_runtime_fault_mepc
        sw      t2, 0(t0)
        csrr    t2, mcause
        la      t0, adam_dift_runtime_fault_mcause
        sw      t2, 0(t0)
        lw      t2, TF_INSN(sp)
        la      t0, adam_dift_runtime_fault_insn
        sw      t2, 0(t0)
        li      t1, 0xD1F70002
        la      t0, adam_dift_runtime_status
        sw      t1, 0(t0)
1:
        j       1b

.Ladam_dift_restore:
        csrr    t0, mcycle
        lw      t1, TF_ENTRY_CYCLE(sp)
        sub     t0, t0, t1
        la      t1, adam_dift_runtime_emulation_cycles
        lw      t2, 0(t1)
        add     t2, t2, t0
        sw      t2, 0(t1)

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
