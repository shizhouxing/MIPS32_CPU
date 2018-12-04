#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
.set noreorder
.set noat
.section .text.init
.global START
START:

    lui a0, 2
    ori a0, a0, 0x8000

exp:
	// a0 input x (f4)
	// v0 output e^x (temp a2, f6)
	lui a2, 1

	// t0 loop variable
	ori t0, $0, 16

	// t2 loop variable(real number) (f10)
	lui t2, 1

	// t4 v (f12)
	lui t4, 1

ori $30, $0, 255

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
