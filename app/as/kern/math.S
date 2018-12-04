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
	ori a2, $0, 0
	lui a2, 1

	// t0 loop variable
	ori t0, $0, 16

	// t2 loop variable(real number) (f10)
	ori t2, $0, 0
	lui t2, 1

	// t4 v (f12)
	ori t4, $0, 0
	lui t2, 1

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
	addiu t2, 0x8000
	addiu t2, 0x8000

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

	// a0 input x (f4)
	// v0 output tanh(x) (temp a2, f6)
	jal exp
	nop

	// t0 e^x (f8)
	ori t0, a2, 0

	// t2 e^(-x) (f10)
	ori t2, $0, 0
	lui t2, 1
	div.s $f10, $f10, $f8

	// t4 e^x - e^(-x) (f12)
	ori t4, $0, 0
	sub t4, t0, t2

	// t6 e^x + e^(-x) (f14)
	ori t6, $0, 0
	addu t4, t0, t2

	// a2 = t4 / t6
	div.s $f6, $f12, $f16

	ori v0, a2, 0

    sw ra, (sp)
    sw t0, 4(sp)
    sw t2, 8(sp)
    sw t4, 12(sp)
	sw t6, 16(sp)
    addiu sp, -20

	jr ra
	nop

sigmoid:
    addiu sp, -20
    sw ra, (sp)
    sw t0, 4(sp)
    sw t2, 8(sp)

	// a0 input x (f4)
	// v0 output tanh(x) (temp a2, f6)
	jal exp
	nop

	// t0 e^x (f8)
	ori t0, a2, 0

	// t2 1 (f10)
	ori t2, $0, 0
	lui t2, 1

	// t0 = t2 / t0 + 1  e^(-x) + 1
	div.s $f8, $f10, $f8
	addu t0, t0, t2

	// a2 = t2 / t0
	div.s $f6, $f10, $f8

	ori v0, a2, 0	

    sw ra, (sp)
    sw t0, 4(sp)
    sw t2, 8(sp)
    addiu sp, -20

	jr ra
	nop
