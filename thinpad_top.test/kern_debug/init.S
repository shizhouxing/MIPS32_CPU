#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
.set noreorder
.set noat
.section .text.init
.global START
START:
    ori $16, $0, 0xffff
    clz $15, $16

dead:
j dead
nop