#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
#include <hyper.h>
.set noreorder
.set noat
.p2align 2
.text
.global decode
decode:
    addiu sp, -20
    sw ra, (sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    
    ori a0, $0, GO_ID
    jal gru_input_word2vec
    nop
    
    ori s0, $0, EOS_ID
    ori s1, $0, 0 // step
    ori s2, $0, MAX_DECODE_LENGTH

    .L_decode_step:
        lui a0, %hi(decoder_gates_kernel)
        addiu a0, %lo(decoder_gates_kernel)
        lui a1, %hi(decoder_gates_bias)
        addiu a1, %lo(decoder_gates_bias)
        lui a2, %hi(decoder_candidate_kernel)
        addiu a2, %lo(decoder_candidate_kernel)
        lui a3, %hi(decoder_candidate_bias)
        addiu a3, %lo(decoder_candidate_bias)
        jal gru_update
        nop
        jal gru_output
        nop
        beq v0, s0, .L_decode_step_done // EOS
        nop
        ori s3, v0, 0
        ori a0, v0, 0
        jal decode_output
        nop
        ori a0, s3, 0
        jal gru_input_word2vec
        nop
        addiu s1, 1

        bne s1, s2, .L_decode_step
        nop
    .L_decode_step_done:
    ori a0, $0, '\n'
    jal putchar
    nop

    lw ra, (sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    addiu sp, 20
    jr ra
    nop

decode_output:
    // a0: id of the word
    addiu sp, -4
    sw ra, (sp)
    
    lui t0, %hi(vocab)
    addiu t0, %lo(vocab)
    ori t1, a0, 0
    .L_find_word_start:
        beq t1, $0, .L_find_word_start_done
        nop
        lb t2, (t0)
        addiu t0, 1
        bne t2, $0, .L_find_word_start
        nop
        addiu t1, -1
        j .L_find_word_start
        nop

    .L_find_word_start_done:
    ori a0, t0, 0
    jal write_string
    nop
    ori a0, $0, ' '
    jal putchar
    nop

    lw ra, (sp)
    addiu sp, 4
    jr ra
    nop