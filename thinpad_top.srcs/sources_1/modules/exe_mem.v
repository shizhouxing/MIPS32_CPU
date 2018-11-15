`timescale 1ns / 1ps

module exe_mem(
    input wire clk,
    input wire rst,
    input wire alu_z,
    input wire[31:0] alu_res,
    input wire[31:0] pc_plus_8_in,
    input wire[4:0] reg_write_address_in,
    input wire[31:0] mem_write_data_in,

    input wire[31:0] data_A,

    // control signals
    input wire con_reg_write,
    input wire con_mov_cond,

    // for mem
    input wire[3:0] con_mem_mask_in,
    input wire con_mem_write_in,
    input wire con_mem_signed_extend_in,
    output reg[3:0] con_mem_mask_out, 
    output reg con_mem_write_out,
    output reg con_mem_signed_extend_out,
    input wire[1:0] con_wb_src_in,
    output reg[1:0] con_wb_src_out,    

    output reg[31:0] pc_plus_8_out,
    output reg[31:0] mem_address,
    output reg[4:0] reg_write_address,
    output reg[31:0] mem_write_data,
    output reg[31:0] alu_res_out,
    output reg[31:0] mov_data,
    output reg reg_write
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        reg_write <= 1'b0;
        con_mem_write_out <= 1'b0;
    end
    else begin
        con_mem_mask_out <= con_mem_mask_in;
        con_mem_write_out <= con_mem_write_in;
        con_mem_signed_extend_out <= con_mem_signed_extend_in;

        con_wb_src_out <= con_wb_src_in;

        pc_plus_8_out <= pc_plus_8_in;
        mem_address <= alu_res;
        mem_write_data <= mem_write_data_in;
        reg_write_address <= reg_write_address_in;

        // decide reg write
        reg_write <= con_reg_write & (~con_mov_cond | alu_z);
        
        alu_res_out <= alu_res;
        mov_data <= data_A;
    end
end

endmodule
