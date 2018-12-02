#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
.set noreorder
.set noat
.p2align 2
.text
.global decode
decode:
    jr ra
    nop