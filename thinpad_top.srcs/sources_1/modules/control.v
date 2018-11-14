`timescale 1ns / 1ps

// generate control signals
module control(
    input wire[31:0] inst,

    // id
    output reg con_alu_immediate,
    output reg con_alu_signed,
    output reg con_alu_sa,
    output reg[1:0] con_reg_dst,

    // exe
    output reg[3:0] con_alu_op,
    output reg con_reg_write,    
    output reg con_mov_cond,

    // mem
    output reg[3:0] con_mem_mask,
    output reg con_mem_write,
    output reg[1:0] con_wb_src
);

always @(*) begin
    // case (inst[31:26]) begin
        
    // endcase
    con_alu_sa = 1'b1;
end


endmodule
