#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
#include <hyper.h>
.set noreorder
.set noat
.p2align 2
.text
.global encode
encode:
    addiu sp, -24
    sw ra, (sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s6, 16(sp)
    sw s7, 20(sp)

    lui t0, %hi(state)
    addiu t0, %lo(state)
    lui t1, 0
    ori t2, $0, NUM_UNITS
    .L_clear_state:
        beq t1, t2, .L_clear_state_done
        sw $0, (t0)
        addiu t0, 4
        addiu t1, 1
    .L_clear_state_done:

    ori s6, $0, ' '
    ori s7, $0, '\n' 
    lui s0, %hi(post_raw) 
    addiu s0, %lo(post_raw)
    .L0:
        lb s2, (s0)
        beq s2, zero, .encode_done
        addiu s1, s0, 1
        .L1:
            lb s2, (s1)
            beq s2, s6, .new_word
            nop
            beq s2, s7, .new_word
            nop
            addiu s1, 1
            j .L1
            nop
        .new_word: // a new word [s0, s1)
            ori a0, s0, 0
            ori a1, s1, 0
            jal encode_input
            nop
            addiu s0, s1, 1
            j .L0
            nop

    .encode_done:
    lw ra, (sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s6, 16(sp)
    lw s7, 20(sp)
    addiu sp, 24

    jr ra
    nop

encode_input: // input the word (a0)...(a1-1)
    addiu sp, -32
    sw ra, (sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    sw s5, 24(sp)
    sw s6, 28(sp)

    lui s0, 0 // word index
    ori s5, a0, 0
    ori s6, a1, 0    
    lui s1, %hi(vocab)
    addiu s1, %lo(vocab)
    ori s2, a0, 0
    .L_symbol2index:
        ori t0, $0, VOCAB_SIZE
        bne s0, t0, .L_check
        nop
        lui s0, 0
        j .symbol2index_done
        nop
        .L_check:
            beq s2, s6, .check_done
            nop
            lb s3, (s1)
            lb s4, (s2)
            bne s3, s4, .check_fail
            nop
            addiu s1, 1
            addiu s2, 1
            j .L_check
            nop
        .check_done:
            lb s3, (s1)
            bne s3, $0, .check_fail
            nop
        .check_ok:
            jal .symbol2index_done
            nop
        .check_fail:
            beq s3, $0, .check_next_word
            nop
            addiu s1, 1
            lb s3, (s1)
            j .check_fail
            nop
        .check_next_word:
            addiu s0, 1
            addiu s1, 1
            ori s2, s5, 0
            j .L_symbol2index
            nop

    .symbol2index_done:
    ori a0, s0, 0
    jal encode_input_word2vec
    nop

    lui a0, %hi(encoder_gates_kernel)
    addiu a0, %lo(encoder_gates_kernel)
    lui a1, %hi(encoder_gates_bias)
    addiu a1, %lo(encoder_gates_bias)
    lui a2, %hi(encoder_candidate_kernel)
    addiu a2, %lo(encoder_candidate_kernel)
    lui a3, %hi(encoder_candidate_bias)
    addiu a3, %lo(encoder_candidate_bias)
    jal gru_update
    nop

    lw ra, (sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    lw s5, 24(sp)
    lw s6, 28(sp)
    addiu sp, 32
    jr ra
    nop

encode_input_word2vec:
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
    ori a0, s1, 0
    jal write_int
    nop
    jal putnewline
    nop

    lui t0, %hi(input)
    addiu t0, %lo(input)
    ori t1, $0, 0
    ori t2, $0, DIM_EMBED
    .L_copy:
        beq t1, t2, .encode_input_word2vec_done
        nop
        lw t3, (s1)
        sw t3, (t0)
        addiu t0, 4
        addiu s1, 4
        addiu t1, 1

        j .L_copy
        nop

    .encode_input_word2vec_done:
    # lui t0, %hi(input)
    # addiu t0, %lo(input)
    # ori t1, $0, 0
    # ori t2, $0, DIM_EMBED
    # .L_disp_wordvec:
    #     beq t1, t2, .L_disp_wordvec_done
    #     nop
    #     ori a0, t1, 0

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

    #     lw a0, (t0)
    #     jal write_int
    #     nop
    #     jal putnewline
    #     nop

    #     lw t0, (sp)
    #     lw t1, 4(sp)
    #     lw t2, 8(sp)
    #     addiu sp, 12

    #     addiu t0, 4
    #     addiu t1, 1
    #     j .L_disp_wordvec
    #     nop
    # .L_disp_wordvec_done:
    # jal putnewline
    # nop

    lw ra, (sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addiu sp, 12
    jr ra
    nop

