#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
    .set noreorder
    .set noat
    .p2align 2
    .text
    .global READ_SENTENCE

READ_SENTENCE:
    addiu sp, sp, 8
    sw ra, 0(sp)
    sw s0, 4(sp)

    //sw $0, (post_raw_len)

    jal READSERIAL 
    nop
    or s0, zero, v0
