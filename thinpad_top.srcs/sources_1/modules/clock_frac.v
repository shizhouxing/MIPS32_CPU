`timescale 1ns / 1ps

module clock_frac(
    input wire rst,
    input wire clk_in,
    output reg clk_out
);

integer count;

always @(posedge clk_in or posedge rst) begin
    if (rst) begin
        count = 0;
        clk_out <= 1'b0;
    end
    else begin
        if (count == 50000) begin
            count = 0;
            clk_out <= ~clk_out;
        end
        else
            count = count + 1;
    end
end

endmodule