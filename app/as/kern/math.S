#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
#include <hyper.h>
.set noreorder
.set noat
.p2align 2
.text

.global exp
.global tanh
.global sigmoid

exp:
    addiu sp, -16
    sw ra, (sp)
    sw t0, 4(sp)
    sw t2, 8(sp)
    sw t4, 12(sp)

	// a0 input x (f4)
	// v0 output e^x (temp a2, f6)
	lui a2, 1

	// t0 loop variable
	ori t0, $0, 32

	// t2 loop variable(real number) (f10)
	lui t2, 1

	// t4 v (f12)
	lui t4, 1
.exp_loop:
	// t0 = t0 - 1
	addiu t0, -1

	beq t0, $0, .exp_exit
	nop

	// v = v * x / i
	mul.s $f12, $f12, $f4

	div.s $f12, $f12, $f10

	// a2 = a2 + v
	addu $6, $6, $12

	// t2 = t2 + 1
    lui t3, 1
    addu t2, t2, t3

	j .exp_loop
	nop

.exp_exit:
	ori v0, a2, 0

    lw ra, (sp)
    lw t0, 4(sp)
    lw t2, 8(sp)
    lw t4, 12(sp)
    addiu sp, 16

	jr ra
	nop

tanh:
    addiu sp, -20
    sw ra, (sp)
    sw t0, 4(sp)
    sw t2, 8(sp)
    sw t4, 12(sp)
	sw t6, 16(sp)

	srl t3, a0, 31
	bgtz t3, .tanh_abs
	nop
	j .tanh_abs_done
	nop
	.tanh_abs:
		lui t5, 0xffff
		ori t5, t5, 0xffff
		xor t5, t5, a0
		addiu t3, t5, 1
	.tanh_abs_done:

	lui t4, 10
	sub t3, t3, t4

	bgtz t3, .tanh_overflow
	nop
	j .tanh_normal
	nop

	.tanh_overflow:
	bgtz a0, .tanh_pos
	nop

	.tanh_neg:
	lui v0, 0xffff
	j .tanh_done
	nop

	.tanh_pos:
	lui v0, 1
	j .tanh_done
	nop

	.tanh_normal:

	// a0 input x (f4)
	// v0 output tanh(x) (temp a2, f6)
	jal exp
	nop

	// t0 e^x (f8)
	ori t0, v0, 0

	// t2 e^(-x) (f10)
	lui t5, 0xffff
	ori t5, t5, 0xffff
	xor t5, t5, a0
	addiu a0, t5, 1
	jal exp
	nop
	ori t2, v0, 0

	// t4 e^x - e^(-x) (f12)
	sub t4, t0, t2

	// t6 e^x + e^(-x) (f14)
	addu t6, t0, t2

	// a2 = t4 / t6
	div.s $f6, $f12, $f14

	ori v0, a2, 0

	.tanh_done:

    lw ra, (sp)
    lw t0, 4(sp)
    lw t2, 8(sp)
    lw t4, 12(sp)
	lw t6, 16(sp)
    addiu sp, 20

	jr ra
	nop

sigmoid:
    addiu sp, -20
    sw ra, (sp)
    sw t0, 4(sp)
    sw t2, 8(sp)

	// a0 input x (f4)
	// v0 output tanh(x) (temp a2, f6)

	srl t3, a0, 31
	bgtz t3, .sigmoid_abs
	nop
	j .sigmoid_abs_done
	nop
	.sigmoid_abs:
		lui t5, 0xffff
		ori t5, t5, 0xffff
		xor t5, t5, a0
		addiu t3, t5, 1
	.sigmoid_abs_done:

	lui t4, 10
	sub t3, t3, t4
	bgtz t3, .sigmoid_overflow
	nop
	j .sigmoid_normal
	nop

	.sigmoid_overflow:
	bgtz a0, .sigmoid_pos
	nop

	.sigmoid_neg:
	lui v0, 0
	j .sigmoid_done
	nop

	.sigmoid_pos:
	lui v0, 1
	j .sigmoid_done
	nop

	.sigmoid_normal:

	// t0 e^(-x) (f8)
	lui t5, 0xffff
	ori t5, t5, 0xffff
	xor t5, t5, a0
	addiu a0, t5, 1
	jal exp
	nop
	ori t0, v0, 0

	// t2 1 (f10)
	lui t2, 1

	// 1 + exp(-x)
	addu t0, t0, t2

	// a2 = t2 / t0
	div.s $f6, $f10, $f8

	ori v0, a2, 0	

	.sigmoid_done:

	lw ra, (sp)
    lw t0, 4(sp)
    lw t2, 8(sp)
    addiu sp, 20

	jr ra
	nop
