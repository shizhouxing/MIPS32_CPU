.org 0x0
.set noat
.set noreorder
.set nomacro
.global START
START:
	lui $1, 0x9000
	ori $30, $0, 0x48
	sw $30, ($1)

	addiu $1, $1, 1
	ori $30, $0, 0x50
	sw $30, ($1)
	
	addiu $1, $1, 1
	ori $30, $0, 0x54
	sw $30, ($1)

	addiu $1, $1, 1
	ori $30, $0, 0x52
	sw $30, ($1)

	.loop:
	j .loop
