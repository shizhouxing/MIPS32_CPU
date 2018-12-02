#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>

    .set noreorder
    .set noat
    .p2align 2
    .text
    .global WRITESERIAL
    .global READSERIAL
    .global READSERIALWORD

WRITESERIAL:  
    lui t1, %hi(SerialStat)
.TESTW:
    lb t0, %lo(SerialStat)(t1)      // 查看串口状态
    andi t0, t0, 0x0001             // 截取写状态位
    bne t0, zero, .WSERIAL          // 状态位非零可写进入写
    nop
    j .TESTW                        // 检测验证，忙等待
    nop
.WSERIAL:
    lui t1, %hi(SerialData)
    sb a0, %lo(SerialData)(t1)      // 写入
    jr ra
    nop

READSERIAL:                         // 读串口：将读到的数据写入v0低八位
    lui t1, %hi(SerialStat)
.TESTR:
    lb t0, %lo(SerialStat)(t1)      // 查看串口状态
    andi t0, t0, 0x0002             // 截取读状态位
    bne t0, zero, .RSERIAL          // 状态位非零可读进入读
    nop
    j .TESTR                        // 检测验证
    nop
.RSERIAL:
    lui t1, %hi(SerialData)
    lb v0, %lo(SerialData)(t1)      // 读出
    jr ra
    nop

