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
    addiu sp, 20

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

    lw ra, (sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    lw s5, 24(sp)
    lw s6, 28(sp)
    addiu sp, 28
    jr ra
    nop

encode_input_word2vec:
    // debug
    j encode_input_word2vec
    nop
    jr ra
    nop