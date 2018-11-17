`timescale 1ns / 1ps

module if_id(
    input wire clk,
    input wire rst,
    input wire stall,
    input wire nop,
    input wire[31:0] inst_in,
    input wire[31:0] pc_plus_4_in,
    output reg[31:0] inst_out,
    output reg[31:0] pc_plus_4_out
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        inst_out <= 32'b0;
        pc_plus_4_out <= 32'b0;
    end
    else begin
        if (~stall) begin
            if (nop) begin
                inst_out <= 32'b0;
                pc_plus_4_out <= 32'b0;
            end
            else begin
                inst_out <= inst_in;
                pc_plus_4_out <= pc_plus_4_in;
            end
        end
    end
end

endmodule
