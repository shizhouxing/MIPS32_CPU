`timescale 1ns / 1ps

module jump_control(
    input wire[31:0] inst,
    input wire[31:0] pc_plus_4,

    input wire[31:0] data_a,
    input wire[31:0] data_b,

    output reg con_pc_jump,
    output reg[31:0] pc_jump
);

// BEQ 000100ssssstttttoooooooooooooooo
// BGTZ 000111sssss00000oooooooooooooooo
// BNE 000101ssssstttttoooooooooooooooo

// J 000010iiiiiiiiiiiiiiiiiiiiiiiiii
// JAL 000011iiiiiiiiiiiiiiiiiiiiiiiiii
// JR 000000sssss0000000000hhhhh001000

always @(*) begin
    case (inst[31:26])
        6'b000100: // BEQ
            con_pc_jump <= data_a == data_b;
        6'b000111: // BGTZ
            con_pc_jump <= ~data_a[31] & (data_a != 32'b0);
        6'b000101: // BNE
            con_pc_jump <= data_a != data_b;
        6'b000010: // J
            con_pc_jump <= 1'b1;
        6'b000011: // JAL
            con_pc_jump <= 1'b1;
        6'b000000:
            con_pc_jump <= inst[5:0] == 6'b001000;  // JR
        default:
            con_pc_jump <= 1'b0;
    endcase

    // branch
    if (inst[31:26] == 6'b000100 || inst[31:26] == 6'b000111 || inst[31:26] == 6'b000101)
        pc_jump <= $signed(pc_plus_4) + $signed({ inst[15:0], 2'b00 });
    // J or JAL
    else if (inst[31:26] == 6'b000010 || inst[31:26] == 6'b000011) 
        pc_jump <= { pc_plus_4[31:28], inst[25:0], 2'b00 };
    // JR
    else
        pc_jump <= data_a;
end

endmodule