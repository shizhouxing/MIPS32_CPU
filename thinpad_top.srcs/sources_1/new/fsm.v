module fsm(
    input wire clk,
    input wire rst,
    input wire[31:0] inp,
    output wire[15:0] disp
);

reg[31:0] A, B, op;

parameter STATE_INPUT_A = 2'b00;
parameter STATE_INPUT_B = 2'b01;
parameter STATE_INPUT_OP = 2'b10;
parameter STATE_OUTPUT_FLAG = 2'b11;

reg[1:0] state = STATE_INPUT_A;
reg[1:0] next_state = STATE_INPUT_B;

always @(posedge clk or posedge clr)
begin
    if (clr) begin
        state <= STATE_INPUT_A;
        disp <= 16'h00000000;
    end
    else case (state)
        STATE_INPUT_A: begin
            next_state <= STATE_INPUT_B;
            A <= inp;
            disp <= A[15:0];
        end
        STATE_INPUT_B: begin
            next_state <= STATE_INPUT_OP;
            B <= inp;
            disp <= B[15:0];
        end
        STATE_INPUT_OP: begin
            next_state <= STATE_OUTPUT_FLAG;
            op <= inp;
            disp <= op[15:0];
        end
        STATE_OUTPUT_FLAG: begin
            next_state <= STATE_INPUT_A;
        end
    endcase
end

endmodule