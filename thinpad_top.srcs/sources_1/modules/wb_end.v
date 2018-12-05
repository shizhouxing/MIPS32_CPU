`timescale 1ns / 1ps

module wb_end(
    input wire clk,
    input wire rst,
    input wire stall,
    input wire[4:0] reg_write_address_in,
    input wire[31:0] reg_write_data_in,
    input wire reg_write_in,
    output reg[4:0] reg_write_address_out,
    output reg[31:0] reg_write_data_out,
    output reg reg_write_out
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        reg_write_out <= 1'b0;
    end
    else begin
        if (~stall) begin
            reg_write_address_out <= reg_write_address_in;
            reg_write_data_out <= reg_write_data_in;
            reg_write_out <= reg_write_in;
        end
    end
end

endmodule