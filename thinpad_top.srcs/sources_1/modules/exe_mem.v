`timescale 1ns / 1ps

module exe_mem(
    input wire clk,
    input wire[31:0] alu_res,
    input wire alu_s,
    input wire alu_z,
    input wire[31:0] inst_in,
    input wire[4:0] reg_write_address_in,
    input wire[31:0] mem_write_data_in,
    input wire[31:0] pc_plus_4,
    input wire[31:0] data_A, 
    input wire[31:0] pc_jump_in,

    // control signals
    input wire[1:0] con_reg_data,
    input wire con_branch, 
    input wire con_branch_rev, // ne
    input wire con_branch_s, // s or z
    input wire con_jump,

    output reg[31:0] mem_address,
    output reg[31:0] mem_write_data,
    output reg[4:0] reg_write_address,
    output reg[31:0] reg_write_data,
    output reg alu_z_out,
    output reg[31:0] pc_jump,
    output reg pc_src
);

// whether should branch if it is a branch instruction
wire alu_b;
assign alu_b = con_branch_s ? alu_s : (alu_z ^ con_branch_rev);

always @(posedge clk) begin
    mem_address <= alu_res;
    mem_write_data <= mem_write_data_in;
    reg_write_address <= reg_write_address_in;
    alu_z_out <= alu_z;
    pc_jump <= pc_jump_in;

    if (con_reg_data[1]) 
        reg_write_data <= pc_plus_4;
    else
        // data_A is for mov 
        reg_write_data <= con_reg_data[0] ? alu_res : data_A; 

    // should branch or jump?
    pc_src <= (alu_b & con_branch) | con_jump;
end

endmodule
