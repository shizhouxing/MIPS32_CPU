`timescale 1ns / 1ps

module id_exe(
    input wire clk,
    input wire[31:0] data_1,
    input wire[31:0] data_2,
    input wire[31:0] inst_in,
    input wire[31:0] pc_plus_4_in,

    // control signals
    input wire con_alu_immediate,
    input wire[1:0] con_reg_dst,

    output reg[31:0] inst_out,
    output reg[31:0] pc_plus_4_out,
    output reg[31:0] pc_jump,
    output reg[31:0] data_A, // for alu
    output reg[31:0] data_B, // for alu
    output reg[4:0] reg_write_address,
    output reg[31:0] mem_write_data
); 

wire[15:0] immediate_16;
wire[31:0] immediate_sign_extend;
assign immediate_16 = inst_in[15:0];
assign immediate_sign_extend = { immediate_16[15] ? 16'hffff : 16'h0, immediate_16 };

// TODO: data_B maybe a 5-bit immediate number

always @(posedge clk) begin
    inst_out <= inst_in;
    pc_plus_4_out <= pc_plus_4_in;
    pc_jump <= pc_plus_4_in + (immediate_sign_extend << 2'b10);
    data_A <= data_1;
    data_B <= con_alu_immediate ? immediate_sign_extend : data_2;

    if (con_reg_dst[1])
        reg_write_address <= 5'b10000; // save $31 for jal
    else
        reg_write_address <= con_reg_dst[0] ? inst_in[20:16] : inst_in[15:11];

    mem_write_data <= data_2;
end

endmodule