`timescale 1ns / 1ps

module alu( 
    input wire[3:0] op,
    input wire[31:0] A,
    input wire[31:0] B,
    output reg[31:0] res,
    output reg flag
);

parameter OP_ADD = 4'b0000;
parameter OP_SUB = 4'b0001;
parameter OP_AND = 4'b0010;
parameter OP_OR  = 4'b0011;
parameter OP_XOR = 4'b0100;
parameter OP_NOT = 4'b0101;
parameter OP_SLL = 4'b0110;
parameter OP_SRL = 4'b0111;
parameter OP_SRA = 4'b1000;
parameter OP_ROL = 4'b1001;

always (op or A or B)
begin
    case (op)
        OP_ADD: begin
            {flag, res} <= A + B;
        end
        OP_SUB: begin
            {flag, res} <= A - B;
        end
        OP_AND: begin   
            {flag, res} <= {1'b0, A & B};
        end
        OP_OR: begin
            {flag, res} <= {1'b0, A | B};
        end
        OP_XOR: begin
            {flag, res} <= {1'b0, A ^ B};
        end
        OP_NOT: begin
            {flag, res} <= {1'b0, ~A};
        end
        OP_SLL: begin
            {flag, res} <= {1'b0, A << B};
        end
        OP_SRL: begin
            {flag, res} <= {1'b0, A >> B};
        end
        OP_SRA: begin
            {flag res} <= {1'b0, ($signed(A)) >>> B};
        end
        OP_ROL: begin
            {flag, res} <= {
                1'b0, 
                ({32'H00000000, A} << B)[31:0] 
                | ({32'H00000000, A} << B)[63:32]
            };
        end
    endcase
end

endmodule
