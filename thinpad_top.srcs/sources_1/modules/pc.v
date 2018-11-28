`timescale 1ns / 1ps

module pc(
    input wire clk,
    input wire rst,
    input wire stall,
    input wire[31:0] inst,
    input wire[31:0] pc_jump,
    input wire con_pc_jump,
    
    input wire flush,
    input wire[31:0] pc_flush,
    
    output wire[31:0] pc_plus_4,
    output reg[31:0] pc_current
);

assign pc_plus_4 = pc_current + 4'h4;

always @(posedge clk or posedge rst) begin
    if (rst)
        pc_current <= 32'h80000000; // default entry
    else begin
        if (flush == 1'b1) begin
            pc_current <= pc_flush - 4'h4;
        end else if (~stall) begin
            // using branch delay slot
            if (con_pc_jump) 
                pc_current <= pc_jump;
            else
                pc_current <= pc_current + 4'h4;

            // if (con_pc_jump && pc_jump != pc_current) begin // the last prediction is incorrect
            //     pc_current <= pc_jump;
            // end
            // else begin
            //     pc_current <= pc_current + 4'h4; // TODO: predict for branch
            // end
        end
    end
end

endmodule
