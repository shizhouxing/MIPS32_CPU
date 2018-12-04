.org 0x0
.set noat
.set noreorder
.set nomacro
.global START
START:
	lui $4, 0x0002
	ori $4, $4, 0x1999
	ori $6, $0, 0x3333
	div.s $f4, $f4, $f6
