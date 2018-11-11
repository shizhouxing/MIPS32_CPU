`timescale 1ns / 1ps

module pc(
    input wire clk,
    input wire rst,
    input wire stall,
    input wire pc_src,
    input wire[31:0] pc_in,
    output reg[31:0] pc_out
);

always @(posedge clk or posedge rst) begin
    if (rst)
        pc_out <= 32'h80000000; // default entry
    else begin
        if (~stall) begin
            if (~pc_src) 
                pc_out <= pc_out + 4'h4;
            else
                pc_out <= pc_in;
        end
    end
end

endmodule
