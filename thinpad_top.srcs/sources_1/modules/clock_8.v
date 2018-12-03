`timescale 1ns / 1ps

module clock_8(
    input wire clk,
    output reg clk_8
);

reg clk_2;
reg clk_4;

initial begin
    clk_2 <= 1'b0;
    clk_4 <= 1'b0;
    clk_8 <= 1'b0;
end

always @(posedge clk) begin
    clk_2 = ~clk_2;
end

always @(posedge clk_2) begin
    clk_4 = ~clk_4;
end

always @(posedge clk_4) begin
    clk_8 = ~clk_8;
end

endmodule
