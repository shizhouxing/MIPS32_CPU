`timescale 1ns / 1ps

module fsm(
    input wire clk,
    input wire rst,
    input wire[31:0] inp,
    output reg[15:0] disp
);

reg[31:0] op, A, B;
wire[31:0] res;
wire flag;

parameter STATE_INPUT_A = 2'b00;
parameter STATE_INPUT_B = 2'b01;
parameter STATE_INPUT_OP = 2'b10;
parameter STATE_OUTPUT_FLAG = 2'b11;

reg[1:0] state = STATE_INPUT_A;

always @(posedge clk or posedge rst)
begin
    if (rst) begin
        state <= STATE_INPUT_A;
        disp <= 16'h0000;
    end
    else case (state)
        STATE_INPUT_A: begin
            state <= STATE_INPUT_B;
            A <= inp;
            disp <= inp[15:0];
        end
        STATE_INPUT_B: begin
            state <= STATE_INPUT_OP;
            B <= inp;
            disp <= inp[15:0];
        end
        STATE_INPUT_OP: begin
            state <= STATE_OUTPUT_FLAG;
            op <= inp;
            disp <= res[15:0];
        end
        STATE_OUTPUT_FLAG: begin
            state <= STATE_INPUT_A;
            disp <= {12'h000, 3'b000, flag};
        end
    endcase
end

alu _alu(op[3:0], A, B, res, flag);

endmodule