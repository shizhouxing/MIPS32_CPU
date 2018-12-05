#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
#include <hyper.h>
.set noreorder
.set noat
.p2align 2
.text

.global gru_update
.global gru_output
.global gru_input_word2vec

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
    ori s3, a3, 0 // candidate_bias

    lui a0, %hi(input)
    addiu a0, %lo(input)
    ori a1, s0, 0
    lui a2, %hi(gate_inputs)
    addiu a2, %lo(gate_inputs)
    ori a3, $0, DIM_INPUT_AND_STATE
    addiu sp, -4
    ori t0, $0, NUM_UNITS_2
    sw t0, (sp)

    jal vector_mul_matrix
    nop
    addiu sp, 4

    lui a0, %hi(gate_inputs)
    addiu a0, %lo(gate_inputs)
    ori a1, s1, 0
    ori a2, $0, NUM_UNITS_2
    jal vector_add_bias
    nop

    lui a0, %hi(gate_inputs)
    addiu a0, %lo(gate_inputs)
    ori a1, $0, NUM_UNITS_2
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
        nop
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
        nop
        lw $14, (t0)
        sw $14, (t1)
        addiu t0, 4
        addiu t1, 4
        addiu t2, 1
        j .L_copy_input
        nop
    .L_copy_input_done:
    lui t0, %hi(r_state)
    addiu t0, %lo(r_state)
    ori t2, $0, 0
    ori t3, $0, NUM_UNITS
    .L_copy_state:
        beq t2, t3, .L_copy_state_done
        nop
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
    ori a3, $0, DIM_INPUT_AND_STATE
    addiu sp, -4
    ori t0, $0, NUM_UNITS
    sw t0, (sp)
    jal vector_mul_matrix
    nop        
    addiu sp, 4

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
    ori t5, $0, NUM_UNITS
    sll t5, t5, 2
    addu t0, t0, t5
    lui t1, %hi(state)
    addiu t1, %lo(state)
    ori t3, $0, 0
    ori t4, $0, NUM_UNITS
    .L_update_state_1:
        beq t3, t4, .L_update_state_1_done
        nop
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
    ori t3, $0, NUM_UNITS
    sll t3, t3, 2
    addu t0, t0, t3
    lui t1, %hi(candidate)
    addiu t1, %lo(candidate)
    lui t2, %hi(state)
    addiu t2, %lo(state)    
    ori t3, $0, 0
    ori t4, $0, NUM_UNITS
    lui t5, 1 // constant 1
    .L_update_state_2:
        beq t3, t4, .L_update_state_2_done
        nop
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

gru_output:
    addiu sp, -4
    sw ra, (sp)

    lui a0, %hi(state)
    addiu a0, %lo(state)
    lui a1, %hi(decoder_dense_kernel)
    addiu a1, %lo(decoder_dense_kernel)
    lui a2, %hi(output)
    addiu a2, %lo(output)
    ori a3, $0, NUM_UNITS
    addiu sp, -4
    ori t0, $0, VOCAB_SIZE
    sw t0, (sp)
    jal vector_mul_matrix
    nop        
    addiu sp, 4

    lui a0, %hi(output)
    addiu a0, %lo(output)
    lui a1, %hi(decoder_dense_bias)
    addiu a1, %lo(decoder_dense_bias)
    ori a2, $0, VOCAB_SIZE
    jal vector_add_bias
    nop

    ori t0, $0, 1
    ori t1, $0, VOCAB_SIZE
    lui t2, %hi(output)
    addiu t2, %lo(output)
    addiu t2, 4
    ori v0, $0, 1
    lw v1, (t2)
    .L_find_max_output:
        beq t0, t1, .L_find_max_output_done
        nop
        lw t3, (t2)
        sub t4, t3, v1
        addiu t2, 4
        bgtz t4, .L_update_max_output
        nop
        addiu t0, 1        
        j .L_find_max_output
        nop
        .L_update_max_output:
        ori v0, t0, 0
        addiu t0, 1
        ori v1, t3, 0
        j .L_find_max_output
        nop
    .L_find_max_output_done:

    lw ra, (sp)
    addiu sp, 4
    jr ra
    nop


gru_input_word2vec:
    addiu sp, -12
    sw ra, (sp)
    sw s0, 4(sp)
    sw s1, 8(sp)

    ori s0, a0, 0
    lui s1, %hi(word_embedding)
    addiu s1, %lo(word_embedding)

    ori t0, s0, 0
    ori t1, $0, DIM_EMBED // offset per word
    sll t1, t1, 2

    .L_find_embedding_start:
        beq t0, $0, .copy_word_embedding
        nop
        addu s1, s1, t1
        addiu t0, -1
        j .L_find_embedding_start
        nop

    .copy_word_embedding:
    lui t0, %hi(input)
    addiu t0, %lo(input)
    ori t1, $0, 0
    ori t2, $0, DIM_EMBED
    .L_copy:
        beq t1, t2, .input_word2vec_done
        nop
        lw t3, (s1)
        nop
        nop
        sw t3, (t0)
        addiu t0, 4
        addiu s1, 4
        addiu t1, 1
        j .L_copy
        nop

    .input_word2vec_done:

        # ori s1, t5, 0


        # // debug
        # lui t0, %hi(input)
        # addiu t0, %lo(input)
        # ori t1, $0, 0
        # ori t2, $0, DIM_EMBED
        # .L_print_state:
        #     beq t1, t2, .L_print_state_done
        #     nop
        #     lw a0, (t0)
        #     addiu sp, -12
        #     sw t0, (sp)
        #     sw t1, 4(sp)
        #     sw t2, 8(sp)
        #     jal write_int
        #     nop
        #     jal putspace
        #     nop
        #     lw t0, (sp)
        #     lw t1, 4(sp)
        #     lw t2, 8(sp)
        #     addiu sp, 12
        #     addiu t1, 1
        #     addiu s1, 4
        #     addiu t0, 4
        #     j .L_print_state
        #     nop
        # .L_print_state_done:
        # jal putnewline
        # nop

    lw ra, (sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addiu sp, 12
    jr ra
    nop    

vector_mul_matrix:
    // a0 input vector
    // a1 matrix
    // a2 output vector
    // a3 matrix rows
    // (sp) matrix columns
    addiu sp, -24
    sw ra, (sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    
    ori s0, a0, 0
    ori s1, a1, 0
    ori s2, a2, 0
    ori s3, a3, 0
    lw s4, 24(sp)
    sll s4, s4, 2

    addu t0, s2, s4
    .L_vector_matrix_clear:
        sw $0, (s2)
        addiu s2, 4
        bne s2, t0, .L_vector_matrix_clear
        nop

    ori s2, a2, 0
    ori t1, $0, 0

    .L_vector_mul_matrix_i:
        lw $14, (s0)
        .L_vector_mul_matrix_j:        
            lw $24, (s1)
            lw t3, (s2)
            mul.s $f12, $f14, $f24
            addu t3, t3, $12
            sw t3, (s2)      
            addiu s1, 4
            addiu s2, 4
            bne s2, t0, .L_vector_mul_matrix_j
            nop
        addiu s0, 4            
        ori s2, a2, 0
        addiu t1, 1
        bne t1, s3, .L_vector_mul_matrix_i
        nop
    
    lw ra, (sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    addiu sp, 24
    jr ra
    nop

vector_add_bias:
    // a0: vector
    // a1: bias
    // a2: dimension
    addiu sp, -12 
    sw ra, (sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    
    ori s0, a0, 0
    ori s1, a1, 0
    ori t0, $0, 0
    ori t1, a2, 0
    .L_vector_add_bias:
        beq t0, t1, .L_vector_add_bias_done
        lw t2, (s0)
        lw t3, (s1)
        addu t2, t2, t3
        sw t2, (s0)
        addiu s0, 4
        addiu s1, 4
        addiu t0, 1
        j .L_vector_add_bias
        nop
    .L_vector_add_bias_done:

    lw ra, (sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addiu sp, 12
    jr ra
    nop

vector_sigmoid:
    // a0: vector
    // a1: dimension
    // a2: func
    addiu sp, -12
    sw ra, (sp)
    sw s0, 4(sp)
    sw s1, 8(sp)

    ori s0, a0, 0
    ori s1, a2, 0
    ori t0, $0, 0
    ori t1, a1, 0 
    .L_vector_sigmoid:
        beq t0, t1, .L_vector_sigmoid_done
        nop
        lw a0, (s0)
        jal sigmoid
        nop
        sw v0, (s0)
        addiu s0, 4
        addiu t0, 1
        j .L_vector_sigmoid
        nop
    .L_vector_sigmoid_done:

    lw ra, (sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addiu sp, 12
    jr ra
    nop

vector_tanh:
    // a0: vector
    // a1: dimension
    // a2: func
    addiu sp, -12
    sw ra, (sp)
    sw s0, 4(sp)
    sw s1, 8(sp)

    ori s0, a0, 0
    ori s1, a2, 0
    ori t0, $0, 0
    ori t1, a1, 0
    .L_vector_tanh:
        beq t0, t1, .L_vector_tanh_done
        nop
        lw a0, (s0)
        jal tanh
        nop
        sw v0, (s0)
        addiu s0, 4
        addiu t0, 1
        j .L_vector_tanh
        nop
    .L_vector_tanh_done:

    lw ra, (sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addiu sp, 12
    jr ra
    nop    