    .section .text.init
    .globl START
START:
    jal mem
#    jal fib
#    jal stall
    nop
done:
    j done
    nop

mem:
    addiu $30, $0, 0x233
    lui $10, 0x8040
    ori $2, $0, 255
    sw $2, ($10)
    lw $3, ($10)
    addiu $30, $3, 0
    jr $31
    nop

stall:
    ori $2, $0, 1
    ori $3, $0, 1
    beq $2, $3, stall_1
    nop
    ori $30, $0, 0x233
    jr $31
    nop
    stall_1:
        ori $30, $0, 0x666
        jr $31
        nop

fib:
        lui $10, 0x8040
        ori $2, $0, 1
        ori $3, $0, 2
        nop
        sw $2, ($10)
        sw $3, 4($10)   
        ori $20, $0, 2    
        ori $21, $0, 10  
        addu $22, $10, 8
        nop
    fib_loop:
        beq $20, $21, fib_done
        nop
        addu $4, $2, $3    
        addiu $2, $3, 0
        addiu $3, $4, 0
        sw $4, ($22)   
        addiu $20, $20, 1
        addiu $22, $22, 4
        addiu $30, $4, 0
        j fib_loop
        nop
    fib_done:
        lw $30, 36($10)
        jr $31
        nop

# test forward to id
#     ori $2, $0, 1
#     ori $3, $0, 1
#     nop
#     beq $2, $3, p1
#     nop
#     j p2
#     nop
# p1:
#     ori $30, $0, 0x233
# p2:
#     j p2
#     nop

# test forward to exe
# correct result: 0xa5
#     ori $20, $0, 0
#     ori $21, $0, 10
#     ori $2, $0, 0
#     ori $3, $0, 0
# loop:
#     beq $20, $21, done
#     nop    
#     addu $2, $2, $20
#     addu $3, $3, $2
#     ori $30, $3, 0
#     addiu $20, $20, 1
#     j loop
#     nop
# done:
#     j done
#     nop

# test forward to mem 
#     ori $2, $0, 0x233
#     sw $2, ($0)
#     lw $30, ($0)
# done:
#     j done
#     nop

