`timescale 1ns / 1ps

`include "constants.v"

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
    case (inst[31:26])
        6'b001001: begin // ADDIU 001001ssssstttttiiiiiiiiiiiiiiii
            { con_alu_immediate, con_alu_signed, con_alu_sa } <= 3'b110;
            con_reg_dst <= 2'b00;
            con_alu_op <= `ALU_OP_ADD;
            { con_reg_write, con_mov_cond } <= 2'b10;
            con_mem_mask <= 4'b0000;
            con_mem_write <= 1'b0;
            con_wb_src <= `WB_SRC_ALU;
        end
    endcase
end

endmodule
