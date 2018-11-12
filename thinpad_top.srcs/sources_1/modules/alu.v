`timescale 1ns / 1ps

module alu( 
    input wire[3:0] op,
    input wire[31:0] A,
    input wire[31:0] B,
    output reg[31:0] res,
    output reg C, S, Z, V
);

parameter ALU_OP_ADD = 4'h0;
parameter ALU_OP_SUB = 4'h1;
parameter ALU_OP_AND = 4'h2;
parameter ALU_OP_OR  = 4'h3;
parameter ALU_OP_XOR = 4'h4;
parameter ALU_OP_NOT = 4'h5;
parameter ALU_OP_SLL = 4'h6;
parameter ALU_OP_SRL = 4'h7;
parameter ALU_OP_SRA = 4'h8;
parameter ALU_OP_ROL = 4'h9;
parameter ALU_OP_LUI = 4'ha;
parameter ALU_OP_CLZ = 4'hb;

always @(op or A or B) begin
    case (op)
        ALU_OP_ADD: {C, res} = {1'b0, A} + {1'b0, B};
        ALU_OP_SUB: {C, res} = {1'b0, A} - {1'b1, B};
        ALU_OP_AND: res = A & B;
        ALU_OP_OR:  res = A | B;
        ALU_OP_XOR: res = A ^ B;
        ALU_OP_NOT: res = ~A;
        ALU_OP_SLL: res = A << B;
        ALU_OP_SRL: res = A >> B;
        ALU_OP_SRA: res = ($signed(A)) >>> B;
        ALU_OP_ROL: res = (A << B) | (A >> (32'h00000020 - B));
        ALU_OP_LUI: res = B << 16;
        ALU_OP_CLZ: res = 32'h00000000; // TODO: CLZ 


//(A[31] & 32'h0) | 
//(~A[31] & A[30] & 32'h1 ) |





    endcase
    S <= res[31];
    Z <= res == 32'h00000000;
    if (op == ALU_OP_ADD)
        V <= (A[31] & B[31] & ~res[31]) | (~A[31] & ~B[31] & res[31]);
    else if (op == ALU_OP_SUB) 
        V <= (A[31] & ~B[31] & ~res[31]) | (~A[31] & B[31] & res[31]);
    else begin
        C <= 32'h00000000;
        V <= 32'h00000000;
    end
end

endmodule
