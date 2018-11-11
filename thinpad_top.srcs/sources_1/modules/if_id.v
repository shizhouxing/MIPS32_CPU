`timescale 1ns / 1ps

module if_id(
    input wire clk,
    input wire stall,
    input wire[31:0] inst_in,
    input wire[31:0] pc_plus_4_in,
    output reg[31:0] inst_out,
    output reg[31:0] pc_plus_4_out
);

// TODO: rst ?
always @(posedge clk) begin
    if (stall) 
        inst_out <= 32'h00000000;
    else
        inst_out <= inst_in;
    pc_plus_4_out <= pc_plus_4_in;
end

endmodule
