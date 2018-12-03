.org 0x0
.set noat
.set noreorder
.set nomacro
.global _start
_start:
	ori $8, $0, 0x100
	ori $30, $0, 0x0
	lui $30, 0x9000
	jr $8
	nop

.org 0x20
	mfc0 $8, $14
	addiu $8, $8, 0x4
	mtc0 $8, $14

	ori $6, $0, 0x11

	sw $5, ($30)
	addiu $30, $30, 0x1

ret:
	eret
	nop

.org 0x100
	ori $4, $0, 0x11
	ori $5, $0, 0x50
	syscall

	ori $4, $0, 0x11
	ori $5, $0, 0x47
	syscall
