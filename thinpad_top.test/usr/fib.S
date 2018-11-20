ori $8, $0, 2
ori $9, $0, 10
sub $29, $29, 40
ori $10, $0, 0
sw $10, ($29)
ori $11, $0, 1
sw $11, 4($29)
ori $13, $29, 0
addiu $13, $13, 8
addu $12, $10, $11
addiu $10, $11, 0
addiu $11, $12, 0
sw $12, ($13)
addiu $13, $13, 4
addiu $8, $8, 1
bne $8, $9, -28
nop
jr $31
nop

#movz $10, $11, $0
#movz $11, $12, $0