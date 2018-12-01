#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
    .set noreorder
    .set noat

    .bss
    .p2align 2

    .text
    .p2align 2
welcome_message:
    .asciz "Welcome to Thin-Chatbot!\n"

    .section .text.main
    .global START
START: 
    lui s0, %hi(welcome_message)    // 装入启动信息
    addiu s0, %lo(welcome_message)
    lb a0, 0(s0)
    .L0:
        addiu s0, s0, 0x1

        jal WRITESERIAL      
        nop
        lb a0, 0(s0)
        bne a0, zero, .L0 
        nop

DONE:
    ori $30, $0, 0xf
    j DONE
    nop    