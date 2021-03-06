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
        .rept NUM_UNITS_2
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
    .p2align 2
    .global screen
    screen:
        .rept SCREEN_SIZE
        .byte 0
        .endr
    .p2align 2
    .global screen_row
    screen_row:
        .long 0
    .global screen_col
    screen_col:
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

        // reset screen
        lui t1, %hi(screen_row)
        addiu t1, %lo(screen_row)
        sw $0, (t1)
        lui t1, %hi(screen_col)
        addiu t1, %lo(screen_col)
        sw $0, (t1)  
        lui t0, %hi(screen)
        addiu t0, %lo(screen)
        ori t1, $0, 0
        ori t2, $0, SCREEN_SIZE
        ori t3, $0, 0x20
        .L_clear_screen:
            sb t3, (t0)
            addiu t0, 1
            addiu t1, 1
            bne t1, t2, .L_clear_screen
            nop

        // print welcome message
        lui a0, %hi(welcome_message)
        addiu a0, %lo(welcome_message)
        jal puts
        nop

    turn:
        ori a0, $0, '>'
        jal putchar
        nop
        ori a0, $0, '>'
        jal putchar
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
