`timescale 1ns / 1ps

module alu( 
    input wire[3:0] op,
    input wire[31:0] A,
    input wire[31:0] B,
    output reg[31:0] res,
    output reg C, S, Z, V
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
        OP_ADD: {C, res} = {1'b0, A} + {1'b0, B};
        OP_SUB: {C, res} = {1'b0, A} - {1'b1, B};
        OP_AND: res = A & B;
        OP_OR:  res = A | B;
        OP_XOR: res = A ^ B;
        OP_NOT: res = ~A;
        OP_SLL: res = A << B;
        OP_SRL: res = A >> B;
        OP_SRA: res = ($signed(A)) >>> B;
        OP_ROL: res = (A << B) | (A >> (32'h00000020 - B));
    endcase
    S <= res[31];
    Z <= res == 32'h00000000;
    if (op == OP_ADD)
        V <= (A[31] & B[31] & ~res[31]) | (~A[31] & ~B[31] & res[31]);
    else if (op == OP_SUB) 
        V <= (A[31] & ~B[31] & ~res[31]) | (~A[31] & B[31] & res[31]);
    else begin
        C <= 32'h00000000;
        V <= 32'h00000000;
    end
end

endmodule
