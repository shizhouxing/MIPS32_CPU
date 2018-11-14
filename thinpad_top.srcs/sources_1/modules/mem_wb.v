`timescale 1ns / 1ps

`include "constants.v"

module mem_wb(
    input wire clk,
    input wire rst,
    input wire reg_write_in,
    input wire[4:0] reg_write_address_in,
    input wire[31:0] pc_plus_8,
    input wire[31:0] mov_data,
    input wire[31:0] mem_read_data,
    input wire[31:0] alu_res,

    input wire[1:0] con_wb_src,

    output reg reg_write_out,
    output reg[4:0] reg_write_address_out,
    output reg[31:0] reg_write_data
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        reg_write_out <= 1'b0;
    end
    else begin
        reg_write_out <= reg_write_in;
        reg_write_address_out <= reg_write_address_in;
        case (con_wb_src)
            `WB_SRC_PC_PLUS_8:
                reg_write_data <= pc_plus_8;
            `WB_SRC_MOV:
                reg_write_data <= mov_data;
            `WB_SRC_MEM:
                reg_write_data <= mem_read_data;
            `WB_SRC_ALU:
                reg_write_data <= alu_res;
        endcase
    end
end

endmodule
