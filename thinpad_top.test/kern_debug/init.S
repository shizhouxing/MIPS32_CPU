    .section .text.init
    .globl START
START:
	ori $5, $3, 233
	mtc0 $5, $11
	mfc0 $30, $11
