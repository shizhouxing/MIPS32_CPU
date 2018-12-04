#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
.set noreorder
.set noat
.section .text.init
.global START
START:
    lui t2, 0x8040
    sub $14, t5, $14 // 1 - u
    mul.s $f14, $f14, $f24
    addu $14, $14, t7
    sw $14, (t2)
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop            