    .section .text.init
    .set noat
    .set noreorder
    .set nomacro
    .globl START

START:
	ori $12, $0, 0x3000
	mul.s $f30, $f12, $f12
	nop
