#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
.set noreorder
.set noat
.section .text.init
.global START
START:
    mul.s $f24, $f14, $f24
    ori $30, $0, 0xff00
    nop
    nop
    nop
    nop
    addu $24, $24, t3
    nop
    nop
    nop
    nop
    ori $30, $0, 0xfff0
    dead:
    j dead
    nop