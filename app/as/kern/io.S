#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
    .set noreorder
    .set noat
    .p2align 2
    .text
    .global read_sentence
    .global write_sentence
    .global puts

read_sentence:
    addiu sp, sp, -16
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)

    lui s0, %hi(post_raw) // address
    addiu s0, %lo(post_raw) 
    ori s1, $0, 0 // length
    ori s2, $0, '\n' // ending char '\n'

    read_char:
    jal READSERIAL 
    nop
    ori a0, v0, 0
    jal WRITESERIAL
    nop
    beq v0, s2, read_done // finish reading on '\n'
    nop
    sb v0, (s0)
    addiu s0, s0, 1
    addiu s1, s1, 1
    j read_char
    nop

    read_done:
    sb $0, (s0) // last '\0'
    lui s2, %hi(post_raw_len)
    addiu s2, %lo(post_raw_len)
    sw s1, (s2)
    lw ra, 0(sp) 
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    addiu sp, sp, 16
    jr ra
    nop

write_sentence:
    addiu sp, sp, -4
    sw ra, 0(sp)

    lui a0, %hi(post_raw)
    addiu a0, %lo(post_raw)
    jal puts
    nop

    lw ra, 0(sp)
    addiu sp, sp, 4
    jr ra
    nop 

puts:
    addiu sp, sp, -8
    sw ra, 0(sp)
    sw s0, 4(sp)

    ori s0, a0, 0
    .L0:
    lb a0, (s0)
    beq a0, zero, puts_done
    nop
    jal WRITESERIAL      
    nop
    addiu s0, s0, 1        
    j .L0
    nop

puts_done:
    ori a0, $0, '\n'
    jal WRITESERIAL
    nop

    lw ra, 0(sp)
    lw s0, 4(sp)
    addiu sp, sp, 8

    jr ra
    nop
