.org 0x0
.set noat
.set noreorder
.set nomacro
.global _start
_start:
	ori $30, $0, 0x8000
	lui $4, 2
	div.s $f30, $f30, $f4
