`ifndef CONSTANTS
`define CONSTANTS 0
    `define ALU_OP_ADD 5'b00000
    `define ALU_OP_SUB 5'b00001
    `define ALU_OP_AND 5'b00010
    `define ALU_OP_OR  5'b00011
    `define ALU_OP_XOR 5'b00100 
    `define ALU_OP_NOT 5'b00101
    `define ALU_OP_SLL 5'b00110
    `define ALU_OP_SRL 5'b00111
    `define ALU_OP_SRA 5'b01000
    `define ALU_OP_ROL 5'b01001
    `define ALU_OP_LUI 5'b01010
    `define ALU_OP_CLZ 5'b01011
    `define ALU_OP_B 5'b01100
    `define ALU_OP_MFC0 5'b01101
    `define ALU_OP_MTC0 5'b01110
    `define ALU_OP_SYSCALL 5'b01111
    `define ALU_OP_ERET 5'b10000

    `define WB_SRC_PC_PLUS_8 2'b00 
    `define WB_SRC_MOV 2'b01 
    `define WB_SRC_MEM 2'b10 
    `define WB_SRC_ALU 2'b11 
`endif