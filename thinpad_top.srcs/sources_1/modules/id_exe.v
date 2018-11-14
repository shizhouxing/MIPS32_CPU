`timescale 1ns / 1ps

module id_exe(
    input wire clk,
    input wire rst,
    input wire[31:0] data_1,
    input wire[31:0] data_2,
    input wire[31:0] inst_in,
    input wire[31:0] pc_plus_4,

    // control signals
    input wire con_alu_immediate,
    input wire con_alu_signed,
    input wire con_alu_sa,
    input wire[1:0] con_reg_dst,
 
    // for exe
    input wire[3:0] con_alu_op_in,
    input wire con_reg_write_in,    
    input wire con_mov_cond_in,
    output reg[3:0] con_alu_op_out,
    output reg con_reg_write_out,
    output reg con_mov_cond_out,

    // for mem
    input wire[3:0] con_mem_mask_in,
    input wire con_mem_write_in,
    output reg[3:0] con_mem_mask_out, 
    output reg con_mem_write_out,
    input wire con_wb_src_in,
    output reg con_wb_src_out,

    output reg[31:0] data_A, // for alu
    output reg[31:0] data_B, // for alu
    output reg[4:0] reg_write_address,
    output reg[31:0] mem_write_data,
    output reg[31:0] pc_plus_8
); 

wire[15:0] immediate_16;
wire[31:0] immediate;
assign immediate_16 = inst_in[15:0];
assign immediate = con_alu_signed ? $signed(immediate_16) : immediate_16;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // TODO: reset the output control signals
    end
    else begin
        con_alu_op_out <= con_alu_op_in;
        con_reg_write_out <= con_reg_write_in;
        con_mov_cond_out <= con_mov_cond_in;

        con_mem_mask_out <= con_mem_mask_in;
        con_mem_write_out <= con_mem_write_in;

        con_wb_src_out <= con_wb_src_in;

        data_A <= con_alu_sa ? inst_in[10:6] : data_1;
        data_B <= con_alu_immediate ? immediate : data_2;
        pc_plus_8 <= pc_plus_4 + 4'h4;

        if (con_reg_dst[1])
            reg_write_address <= 5'b10000; // save $31 for jal
        else
            reg_write_address <= con_reg_dst[0] ? inst_in[20:16] : inst_in[15:11];

        mem_write_data <= data_2;
    end
end

endmodule