`timescale 1ns / 1ps

module pc(
    input wire clk,
    input wire rst,
    input wire[31:0] pc_in,
    output reg[31:0] pc_out
);

always @(posedge clk or posedge rst) begin
    if (rst)
        pc_out <= 32'h80000000; // default entry
    else begin
        pc_out <= pc_in;
    end
end

endmodule
