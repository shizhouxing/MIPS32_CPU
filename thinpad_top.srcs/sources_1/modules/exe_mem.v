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

    output reg[31:0] pc_plus_8_out,
    output reg[31:0] mem_address,
    output reg[4:0] reg_write_address,
    output reg[31:0] mem_write_data,
    output reg reg_write,
    output reg alu_res_out,
    output reg mov_data
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
    end
    else begin
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
