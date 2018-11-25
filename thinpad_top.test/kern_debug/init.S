    .section .text.init
    .globl START
START:
	ori $3, $0, 255
	movz $2, $3, $0
	ori $30, $2, 1024
