    .section .text.init
    .set noat
    .set noreorder
    .set nomacro
    .globl START

START:
	ori $1, $0, 0x100
	jr $1
	syscall
	ori $30, $0, 0x30

.org 0x40
	mfc0 $1, $14
	addiu $1, $1, 0x4
	mtc0 $1, $14
	ori $30, $0, 0x20
	eret
	nop

.org 0x100
	nop
