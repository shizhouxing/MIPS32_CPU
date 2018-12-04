#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
.set noreorder
.set noat
.section .text.init
.global START
START:

lui sp, 0x8070


lui $4, 0x0002
ori $4, $4, 0x8000
ori a0, $4, 0
j tanh
nop

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
	ori t0, $0, 16

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

	// a0 input x (f4)
	// v0 output tanh(x) (temp a2, f6)
	jal exp
	nop

    ori $30, $0, 255

	// t0 e^x (f8)
	ori t0, v0, 0

	// t2 e^(-x) (f10)
	lui t2, 1
	div.s $f10, $f10, $f8

	// t4 e^x - e^(-x) (f12)
	sub t4, t0, t2

	// t6 e^x + e^(-x) (f14)
	addu t6, t0, t2

	// a2 = t4 / t6
	div.s $f6, $f12, $f14

	ori v0, a2, 0

    lw ra, (sp)
    lw t0, 4(sp)
    lw t2, 8(sp)
    lw t4, 12(sp)
	lw t6, 16(sp)
    addiu sp, 20

	jr ra
	nop