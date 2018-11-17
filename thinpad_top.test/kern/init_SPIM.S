    #.section .text.init
    .globl main
main:
    ori $20, $0, 0
    ori $21, $0, 10
    ori $2, $0, 0
    ori $3, $0, 0
    nop
    nop
loop:
    beq $20, $21, done
    nop
    nop
    addu $2, $2, $20
    addu $3, $3, $2
    ori $30, $3, 0
    addiu $20, $20, 1
    nop
    nop
    j loop
    nop
    nop
done:
    jr $31
    nop


#     ori $2, $0, 1
#     ori $3, $0, 2
#     nop
#     nop
#     sw $2, ($0)
#     sw $3, 4($0)
#     nop
#     nop   
#     ori $20, $0, 2    
#     ori $21, $0, 10    
#     ori $22, $0, 8
#     nop
#     nop
# loop:
#     beq $20, $21, done
#     nop
#     addu $4, $2, $3    
#     addiu $2, $3, 0
#     nop
#     nop
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
