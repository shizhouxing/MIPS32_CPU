`ifndef CONSTANTS
`define CONSTANTS 0
    `define ALU_OP_ADD 4'h0 
    `define ALU_OP_SUB 4'h1 
    `define ALU_OP_AND 4'h2 
    `define ALU_OP_OR  4'h3 
    `define ALU_OP_XOR 4'h4 
    `define ALU_OP_NOT 4'h5 
    `define ALU_OP_SLL 4'h6 
    `define ALU_OP_SRL 4'h7 
    `define ALU_OP_SRA 4'h8 
    `define ALU_OP_ROL 4'h9 
    `define ALU_OP_LUI 4'ha 
    `define ALU_OP_CLZ 4'hb 
    `define ALU_OP_B 4'hc
    `define ALU_OP_MFC0 4'hd
    `define ALU_OP_MTC0 4'he

    `define WB_SRC_PC_PLUS_8 2'b00 
    `define WB_SRC_MOV 2'b01 
    `define WB_SRC_MEM 2'b10 
    `define WB_SRC_ALU 2'b11 
`endif