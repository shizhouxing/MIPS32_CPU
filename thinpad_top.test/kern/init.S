    .section .text.init
    .globl START
START:
#test forward_mem 
    ori $2, $0, 0x233
    sw $2, ($0)
    lw $30, ($0)
done:
    j done
    nop

#fib

#     ori $2, $0, 1
#     ori $3, $0, 2
#     nop
#     sw $2, ($0)
#     sw $3, 4($0)   
#     ori $20, $0, 2    
#     ori $21, $0, 10    
#     ori $22, $0, 8
#     nop
# loop:
#     beq $20, $21, done
#     nop
#     addu $4, $2, $3    
#     addiu $2, $3, 0
#     addiu $3, $4, 0
#     sw $4, ($22)   
#     addiu $20, $20, 1
#     addiu $22, $22, 4
#     addiu $30, $4, 0
#     j loop
#     nop
# done:
#     lw $30, 36($0)
#     j done
#     nop


# test forward_exe
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
