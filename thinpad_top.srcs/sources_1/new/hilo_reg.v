`timescale 1ns / 1ps

module hilo_reg(
    input wire clk,
    input wire rst,
    
    input wire we_in,
    input wire hi_in,
    input wire lo_in,
    
    output reg[31:0] hi_out,
    output reg[31:0] lo_out,
    output reg[31:0] mul_out
);

always @(posedge clk) begin
    if (rst == 1'b1) begin
        hi_out <= 32'b0;
        lo_out <= 32'b0;
        mul_out <= 32'b0;
    end else begin
        if (we_in == 1'b1) begin
            hi_out <= hi_in;
            lo_out <= lo_out;
            mul_out <= {hi_out[15:0], lo_out[31:16]};
        end
    end
end

endmodule
