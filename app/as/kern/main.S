#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
.set noreorder
.set noat

.section .bss
.p2align 2
    .global post_raw
    .global post_raw_len
    post_raw:
        .rept 512
        .byte 0
        .endr
    post_raw_len:
        .long 0

.section .text
.p2align 2
    welcome_message:
        .asciz "Welcome to Thin-Chatbot!"  

.p2align 2
    .global START
    START: 
        // initialize stack
        lui sp, %hi(KERNEL_STACK_INIT)
        addiu sp, %lo(KERNEL_STACK_INIT)
        or fp, sp, zero

        // print welcome message
        lui a0, %hi(welcome_message)
        addiu a0, %lo(welcome_message)
        jal puts
        nop

    turn:
        ori a0, $0, '>'
        jal WRITESERIAL
        nop
        ori a0, $0, '>'
        jal WRITESERIAL
        nop
        jal read_sentence
        nop
        jal write_sentence
        nop
        j turn
        nop

.section .text.init
    .global INITLOCATE
    INITLOCATE:   
        lui k0, %hi(START)
        addiu k0, %lo(START)
        jr k0
        nop