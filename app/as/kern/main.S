#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
#include <hyper.h>
.set noreorder
.set noat

.section .bss
.p2align 2
    .global post_raw
    post_raw:
        .rept 512
        .byte 0
        .endr
    .global input
    input:
        .rept DIM_EMBED
        .long 0
        .endr        
    .global state
    state:
        .rept NUM_UNITS
        .long 0
        .endr
    .global input_and_state
    input_and_state:
        .rept DIM_INPUT_AND_STATE
        .long 0
        .endr
    .global gate_inputs
    gate_inputs:
        .rept NUM_UNITS
        .long 0
        .endr
    .global r_state
    r_state:
        .rept NUM_UNITS
        .long 0
        .endr
    .global candidate
    candidate:
        .rept NUM_UNITS
        .long 0
        .endr
    .global output
    output:
        .rept VOCAB_SIZE
        .long 0
        .endr

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
        jal encode
        nop
        jal decode
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