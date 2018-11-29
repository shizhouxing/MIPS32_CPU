#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
#include <exception.h>
    .section .text.init
    .set noat
    .set noreorder
    .set nomacro
    .globl START

START:

ori a0, $0, 97

    lui t1, 0xBFD0
.TESTW:
    lb t0, 0x03FC(t1)      // 查看串口状态
    andi t0, t0, 0x0001             // 截取写状态位
    bne t0, zero, .WSERIAL          // 状态位非零可写进入写
    nop
    j .TESTW                        // 检测验证，忙等待
    nop
.WSERIAL:
    lui t1, (0xBFD0)
    sb a0, 0x03F8(t1)      // 写入

    DEBUG:
        ori $30, a0, 0
        j DEBUG
        nop

# ori $8, $0, 2
# ori $9, $0, 10
# sub $29, $29, 40
# ori $10, $0, 0
# sw $10, ($29)
# ori $11, $0, 1
# sw $11, 4($29)
# ori $13, $29, 0
# addiu $13, $13, 8

# LOOP:
# 	addu $12, $10, $11
# 	movz $10, $11, $0
# 	movz $11, $12, $0
# 	sw $12, ($13)
# 	addiu $13, $13, 4
# 	addiu $8, $8, 1
# 	ori $30, $8, 0
# 	bne $8, $9, LOOP
# 	nop

# ori $30, $12, 0
# DEBUG:
# 	j DEBUG
# 	nop

# 	ori $1, $0, 0x100
# 	jr $1
# 	syscall
# 	ori $30, $0, 0x30

# .org 0x40
# 	mfc0 $1, $14
# 	addiu $1, $1, 0x4
# 	mtc0 $1, $14
# 	ori $30, $0, 0x20
# 	eret
# 	nop

# .org 0x100
# 	nop
