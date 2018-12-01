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
        .long 0
        .endr
    post_raw_len:
        .long 0

.section .text
.p2align 2
    welcome_message:
        .asciz "Welcome to Thin-Chatbot!\n"    

.p2align 2
    .global START
    START: 
        // initialize stack
        lui sp, %hi(KERNEL_STACK_INIT)
        addiu sp, %lo(KERNEL_STACK_INIT)
        or fp, sp, zero

        // initialize bss
        lui k0, %hi(_sbss)
        addiu k0, %lo(_sbss)
        lui k1, %hi(_ebss)
        addiu k1, %lo(_ebss)
        bss_init:
            beq k0, k1, bss_init_done
            nop
            sw  zero, 0(k0)
            addiu k0, k0, 4
            b   bss_init
            nop    
        bss_init_done:

        // print welcome message
        lui s0, %hi(welcome_message)
        addiu s0, %lo(welcome_message)
        lb a0, 0(s0)
        .L0:
            addiu s0, s0, 0x1

            jal WRITESERIAL      
            nop
            lb a0, 0(s0)
            bne a0, zero, .L0 
            nop


.section .text.init
    .global INITLOCATE
    INITLOCATE:   
        lui k0, %hi(START)
        addiu k0, %lo(START)
        jr k0
        nop