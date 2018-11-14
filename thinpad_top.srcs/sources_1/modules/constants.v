`ifndef CONSTANTS
    `define CONSTANTS 0

    parameter ALU_OP_ADD = 4'h0;
    parameter ALU_OP_SUB = 4'h1;
    parameter ALU_OP_AND = 4'h2;
    parameter ALU_OP_OR  = 4'h3;
    parameter ALU_OP_XOR = 4'h4;
    parameter ALU_OP_NOT = 4'h5;
    parameter ALU_OP_SLL = 4'h6;
    parameter ALU_OP_SRL = 4'h7;
    parameter ALU_OP_SRA = 4'h8;
    parameter ALU_OP_ROL = 4'h9;
    parameter ALU_OP_LUI = 4'ha;
    parameter ALU_OP_CLZ = 4'hb;

    parameter WB_SRC_PC_PLUS_8 = 2'b00;
    parameter WB_SRC_MOV = 2'b01;
    parameter WB_SRC_MEM = 2'b10;
    parameter WB_SRC_ALU = 2'b11;
`endif