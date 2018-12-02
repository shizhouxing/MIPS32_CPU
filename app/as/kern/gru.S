#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
#include <hyper.h>
.set noreorder
.set noat
.p2align 2
.text

.global gru_update
gru_update:
    addiu sp, -20
    sw ra, (sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)

    ori s0, a0, 0 // gates_kernel
    ori s1, a1, 0 // gates_bias
    ori s2, a2, 0 // candidate_kernel
    ori s3, s3, 0 // candidate_bias

    lui a0, %hi(input)
    addiu a0, %lo(input)
    ori a1, s0, 0
    lui a2, %hi(gate_inputs)
    addiu a2, %lo(gate_inputs)
    ori a3, $0, NUM_UNITS
    sll a3, a3, 1
    jal vector_mul_matrix
    nop
    
    lui a0, %hi(gate_inputs)
    addiu a0, %lo(gate_inputs)
    ori a1, s1, 0
    ori a2, $0, NUM_UNITS
    sll a2, a2, 1
    jal vector_add_bias
    nop

    lui a0, %hi(gate_inputs)
    addiu a0, %lo(gate_inputs)
    ori a1, $0, NUM_UNITS
    sll a1, a1, 1    
    jal vector_sigmoid
    nop

    lui t0, %hi(gate_inputs)
    addiu t0, %lo(gate_inputs)
    lui t1, %hi(state)
    addiu t1, %lo(state)
    lui t2, %hi(r_state)
    addiu t2, %lo(r_state)
    ori t3, $0, 0
    ori t4, $0, NUM_UNITS
    .L_get_r_state:
        beq t3, t4, .L_get_r_state_done
        lw $14, (t0)
        lw $24, (t1)
        mul.s $f14, $f14, $f24
        sw $14, (t2)
        addiu t0, 4
        addiu t1, 4
        addiu t2, 4
        addiu t3, 1
        j .L_get_r_state
        nop
    .L_get_r_state_done:

    lui t0, %hi(input)
    addiu t0, %lo(input)
    lui t1, %hi(input_and_state)
    addiu t1, %lo(input_and_state)
    ori t2, $0, 0
    ori t3, $0, DIM_EMBED
    .L_copy_input:
        beq t2, t3, .L_copy_input_done
        lw $14, (t0)
        sw $14, (t1)
        addiu t0, 4
        addiu t1, 4
        addiu t2, 1
        j .L_copy_input
        nop
    .L_copy_input_done:
    lui t0, %hi(state)
    addiu t0, %lo(state)
    ori t2, $0, 0
    ori t3, $0, NUM_UNITS
    .L_copy_state:
        beq t2, t3, .L_copy_state_done
        lw $14, (t0)
        sw $14, (t1)
        addiu t0, 4
        addiu t1, 4
        addiu t2, 1
        j .L_copy_state
        nop
    .L_copy_state_done:

    lui a0, %hi(input_and_state)
    addiu a0, %lo(input_and_state)
    ori a1, s2, 0
    lui a2, %hi(candidate)
    addiu a2, %lo(candidate)
    ori a3, $0, NUM_UNITS
    jal vector_mul_matrix
    nop          

    lui a0, %hi(candidate)
    addiu a0, %lo(candidate)
    ori a1, s3, 0
    ori a2, $0, NUM_UNITS
    jal vector_add_bias
    nop

    lui a0, %hi(candidate)
    addiu a0, %lo(candidate)
    ori a1, $0, NUM_UNITS  
    jal vector_tanh
    nop

    lui t0, %hi(gate_inputs)
    addiu t0, %lo(gate_inputs)
    addiu t0, NUM_UNITS
    lui t1, %hi(state)
    addiu t1, %lo(state)
    ori t3, $0, 0
    ori t4, $0, NUM_UNITS
    .L_update_state_1:
        beq t3, t4, .L_update_state_1_done
        lw $14, (t0)
        lw $24, (t1)
        mul.s $f14, $f14, $f24
        sw $14, (t1)
        addiu t0, 4
        addiu t1, 4
        addiu t3, 1
        j .L_update_state_1
        nop
    .L_update_state_1_done:

    lui t0, %hi(gate_inputs)
    addiu t0, %lo(gate_inputs)
    addiu t0, NUM_UNITS
    lui t1, %hi(candidate)
    addiu t1, %lo(candidate)
    lui t2, %hi(state)
    addiu t2, %lo(state)    
    ori t3, $0, 0
    ori t4, $0, NUM_UNITS
    ori t5, $0, 1 // constant 1
    .L_update_state_2:
        beq t3, t4, .L_update_state_2_done
        lw $14, (t0)
        lw $24, (t1)
        lw t7, (t2)
        sub $14, t5, $14 // 1 - u
        mul.s $f14, $f14, $f24
        addu $14, $14, t7
        sw $14, (t2)
        addiu t0, 4
        addiu t1, 4
        addiu t2, 4
        addiu t3, 1
        j .L_update_state_2
        nop
    .L_update_state_2_done:
   
    lw ra, (sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    addiu sp, 20
    jr ra
    nop

vector_mul_matrix:

vector_add_bias:

vector_sigmoid:

vector_tanh: