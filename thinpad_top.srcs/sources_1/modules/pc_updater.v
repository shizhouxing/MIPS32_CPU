`timescale 1ns / 1ps

module pc_updater(
    input wire clk,
    input wire rst,
    input wire stall,
    input wire[31:0] pc_current,
    input wire[31:0] inst,
    input wire[31:0] pc_jump,
    input wire con_pc_jump,

    output wire[31:0] pc_plus_4, 
    output reg[31:0] pc_next
);

assign pc_plus_4 = pc_current + 4'h4;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        pc_next <= 32'b0;
    end
    else begin
        if (!stall) begin
            if (con_pc_jump && pc_jump != pc_next) begin // the last prediction is incorrect
                pc_next <= pc_jump;
            end
            else begin
                pc_next <= pc_plus_4; // TODO: predict for branch
            end
        end
    end
end

endmodule