#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
.set noreorder
.set noat
.section .text.init
.global START
START:
    lui $14, 0x2
    ori $14, $14, 0x8000

    lui $16, 0x5
    ori $16, $16, 0x8000

    mul.s $f14, $f14, $f16
    ori $30, $14, 0




dead:
j dead
nop