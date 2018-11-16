    .section .text.init
    .globl START
START:
    ori $2, $0, 1
    nop
    nop
    nop
    nop
    ori $3, $0, 2
    nop
    nop
    nop
    nop    
    sw $2, ($0)
    nop
    nop
    nop
    nop        
    sw $3, 4($0)
    nop
    nop
    nop
    nop     
    ori $20, $0, 2
    nop
    nop
    nop
    nop    
    ori $21, $0, 10
    nop
    nop
    nop
    nop    
    ori $22, $0, 8
    nop
    nop
    nop
    nop        
loop:
    beq $20, $21, done
    nop
    nop
    nop
    nop    
    addu $4, $2, $3
    nop
    nop
    nop
    nop    
    addiu $2, $3, 0
    nop
    nop
    nop
    nop    
    addiu $3, $4, 0
    nop
    nop
    nop
    nop    
    sw $4, ($22)
    nop
    nop
    nop
    nop    
    addiu $20, $20, 1
    nop
    nop
    nop
    nop  
    addiu $22, $22, 4
    nop
    nop
    nop
    nop        
    addiu $30, $4, 0
    nop
    nop
    nop
    nop            
    j loop
    nop
    nop
    nop
    nop    
done:
    lw $30, 36($0)
    nop
    nop
    nop
    nop