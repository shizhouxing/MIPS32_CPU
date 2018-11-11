`timescale 1ns / 1ps

module mem_wb(
    input wire clk,
    input wire alu_z,
    input wire[4:0] reg_write_address_in,
    input wire[4:0] reg_write_address_ext_in,
    input wire[31:0] reg_write_data_in,
    input wire[31:0] mem_data,

    // control signals
    input wire con_wb_memory,
    input wire con_reg_write,
    input wire con_mov_cond,

    output reg[4:0] reg_write_address,
    output reg[4:0] reg_write_address_ext,
    output reg[31:0] reg_write_data,
    output reg reg_write
);

always @(posedge clk) begin
    reg_write_address <= reg_write_address_in;
    reg_write_address_ext <= reg_write_address_ext_in;
    reg_write_data <=  con_wb_memory ? mem_data : reg_write_data_in;
    reg_write <= con_reg_write & (~con_mov_cond | alu_z);
end

endmodule
