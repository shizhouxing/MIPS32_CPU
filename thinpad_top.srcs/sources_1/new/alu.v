`timescale 1ns / 1ps

module alu( 
    input wire[3:0] op,
    input wire[31:0] A,
    input wire[31:0] B,
    output reg[31:0] res,
    output reg flag
);

parameter OP_ADD = 4'h0;
parameter OP_SUB = 4'h1;
parameter OP_AND = 4'h2;
parameter OP_OR  = 4'h3;
parameter OP_XOR = 4'h4;
parameter OP_NOT = 4'h5;
parameter OP_SLL = 4'h6;
parameter OP_SRL = 4'h7;
parameter OP_SRA = 4'h8;
parameter OP_ROL = 4'h9;

always @(op or A or B)
begin
    case (op)
        OP_ADD: {flag, res} <= A + B;
        OP_SUB: {flag, res} <= A - B;
        OP_AND: {flag, res} <= {1'b0, A & B};
        OP_OR:  {flag, res} <= {1'b0, A | B};
        OP_XOR: {flag, res} <= {1'b0, A ^ B};
        OP_NOT: {flag, res} <= {1'b0, ~A};
        OP_SLL: {flag, res} <= {1'b0, A << B};
        OP_SRL: {flag, res} <= {1'b0, A >> B};
        OP_SRA: {flag, res} <= {1'b0, ($signed(A)) >>> B};
        OP_ROL: {flag, res} <= {1'b0, (A << B) | (A >> (32'h00000020 - B))};
    endcase
end

endmodule
