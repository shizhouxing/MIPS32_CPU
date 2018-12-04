`timescale 1ns / 1ps

`include "constants.v"

module alu( 
    input wire[4:0] op,
    input wire[31:0] A,
    input wire[31:0] B,
    output reg[31:0] res,
    
    input wire[31:0] inst_in,
    
    // cp0
    input wire mem_cp0_we,
    input wire[4:0] mem_cp0_write_addr,
    input wire[31:0] mem_cp0_data,
    input wire wb_cp0_we,
    input wire[4:0] wb_cp0_write_addr,
    input wire[31:0] wb_cp0_data,
    input wire[31:0] cp0_data_in,
    output reg[4:0] cp0_read_addr,
    output reg cp0_we_out,
    output reg[4:0] cp0_write_addr_out,
    output reg[31:0] cp0_data_out,
    
    // exception
    input wire[31:0] exception_in,
    input wire[31:0] exception_address_in,
    /*
        [10:10] trap
        [11:11] overflow
    */
    output reg[31:0] exception_out,
    output reg[31:0] exception_address_out,
    
    // delayslot
    input wire this_delayslot_in,
    output reg this_delayslot_out,
    
    // div
    input wire div_ready_in,
    input wire[31:0] div_result_in,
    output reg[31:0] div_opdata1_out,
    output reg[31:0] div_opdata2_out,
    output reg div_start_out,
    output reg div_signed_out,
    output reg div_stall_out,
    
    output reg C, S, Z, V
);

wire[31:0] B_complement;
wire[31:0] A_mul;
wire[31:0] B_mul;
wire[63:0] mulres_tmp;

reg[63:0] mulres;

assign B_complement = op == `ALU_OP_SUB ? ((~B) + 1) : B;

assign A_mul = (op == `ALU_OP_MULS && A[31] == 1'b1) ? ((~A) + 1) : A;

assign B_mul = (op == `ALU_OP_MULS && B[31] == 1'b1) ? ((~B) + 1) : B;

assign mulres_tmp = A_mul * B_mul;

always @(*) begin
    cp0_we_out <= 1'b0;
    exception_out <= exception_in;
    exception_address_out <= exception_address_in;
    this_delayslot_out <= this_delayslot_in;
    div_opdata1_out <= 32'b0;
    div_opdata2_out <= 32'b0;
    div_start_out <= 1'b0;
    div_signed_out <= 1'b0;
    div_stall_out <= 1'b0;
    case (op)
         `ALU_OP_MFC0: begin
             cp0_read_addr <= inst_in[15:11];
             res <= cp0_data_in;
             if (mem_cp0_we == 1'b1 && mem_cp0_write_addr == inst_in[15:11]) begin
                 res <= mem_cp0_data;
             end
             else if (wb_cp0_we == 1'b1 && wb_cp0_write_addr == inst_in[15:11]) begin
                 res <= wb_cp0_data;
             end
         end
         `ALU_OP_MTC0: begin
             cp0_we_out <= 1'b1;
             cp0_write_addr_out <= inst_in[15:11];
             cp0_data_out <= B;
         end
         `ALU_OP_MULS: begin
             if (A[31] ^ B[31] == 1'b1) begin
                res = ~{1'b0, mulres_tmp[46:16]} + 1;
             end
             else begin
                res = {1'b0, mulres_tmp[46:16]};
             end
         end
         `ALU_OP_DIVS: begin
            if (div_ready_in == 1'b0) begin
                div_opdata1_out <= B;
                div_opdata2_out <= A;
                div_start_out <= 1'b1;
                div_signed_out <= 1'b1;
                div_stall_out <= 1'b1;
            end
            else if (div_ready_in == 1'b1) begin
                div_opdata1_out <= B;
                div_opdata2_out <= A;
                div_start_out <= 1'b0;
                div_signed_out <= 1'b1;
                res = div_result_in;
                div_stall_out <= 1'b0;
            end
            else begin
                div_opdata1_out <= 32'b0;
                div_opdata2_out <= 32'b0;
                div_start_out <= 1'b0;
                div_signed_out <= 1'b0;
                div_stall_out <= 1'b0;
            end
         end
         `ALU_OP_ADD: begin
             {C, res} = {1'b0, A} + {1'b0, B};
             //exception_out[11] <= (!A[31] && !B_complement[31] && res[31]) || (A[31] && B_complement[31] && !res[31]);
         end
         `ALU_OP_SUB: begin
             {C, res} = {1'b0, A} - {1'b1, B};
             //exception_out[11] <= (!A[31] && !B_complement[31] && res[31]) || (A[31] && B_complement[31] && !res[31]);
         end
         `ALU_OP_AND: res = A & B;
         `ALU_OP_OR:  res = A | B;
         `ALU_OP_XOR: res = A ^ B;
         `ALU_OP_NOT: res = ~A;
         `ALU_OP_SLL: res = B << A;
         `ALU_OP_SRL: res = B >> A;
         `ALU_OP_SRA: res = ($signed(A)) >>> B;
         `ALU_OP_ROL: res = (A << B) | (A >> (32'h00000020 - B));
         `ALU_OP_CLZ: res = (A[31] & 6'b000000) | 
            (~A[31] & A[30] & 6'b000001) | 
            (~A[31] & ~A[30] & A[29] & 6'b000010) | 
            (~A[31] & ~A[30] & ~A[29] & A[28] & 6'b000011) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & A[27] & 6'b000100) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & A[26] & 6'b000101) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & A[25] & 6'b000110) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & A[24] & 6'b000111) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & A[23] & 6'b001000) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & A[22] & 6'b001001) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & A[21] & 6'b001010) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & A[20] & 6'b001011) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & A[19] & 6'b001100) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & ~A[19] & A[18] & 6'b001101) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & ~A[19] & ~A[18] & A[17] & 6'b001110) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & ~A[19] & ~A[18] & ~A[17] & A[16] & 6'b001111) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & ~A[19] & ~A[18] & ~A[17] & ~A[16] & A[15] & 6'b010000) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & ~A[19] & ~A[18] & ~A[17] & ~A[16] & ~A[15] & A[14] & 6'b010001) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & ~A[19] & ~A[18] & ~A[17] & ~A[16] & ~A[15] & ~A[14] & A[13] & 6'b010010) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & ~A[19] & ~A[18] & ~A[17] & ~A[16] & ~A[15] & ~A[14] & ~A[13] & A[12] & 6'b010011) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & ~A[19] & ~A[18] & ~A[17] & ~A[16] & ~A[15] & ~A[14] & ~A[13] & ~A[12] & A[11] & 6'b010100) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & ~A[19] & ~A[18] & ~A[17] & ~A[16] & ~A[15] & ~A[14] & ~A[13] & ~A[12] & ~A[11] & A[10] & 6'b010101) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & ~A[19] & ~A[18] & ~A[17] & ~A[16] & ~A[15] & ~A[14] & ~A[13] & ~A[12] & ~A[11] & ~A[10] & A[9] & 6'b010110) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & ~A[19] & ~A[18] & ~A[17] & ~A[16] & ~A[15] & ~A[14] & ~A[13] & ~A[12] & ~A[11] & ~A[10] & ~A[9] & A[8] & 6'b010111) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & ~A[19] & ~A[18] & ~A[17] & ~A[16] & ~A[15] & ~A[14] & ~A[13] & ~A[12] & ~A[11] & ~A[10] & ~A[9] & ~A[8] & A[7] & 6'b011000) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & ~A[19] & ~A[18] & ~A[17] & ~A[16] & ~A[15] & ~A[14] & ~A[13] & ~A[12] & ~A[11] & ~A[10] & ~A[9] & ~A[8] & ~A[7] & A[6] & 6'b011001) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & ~A[19] & ~A[18] & ~A[17] & ~A[16] & ~A[15] & ~A[14] & ~A[13] & ~A[12] & ~A[11] & ~A[10] & ~A[9] & ~A[8] & ~A[7] & ~A[6] & A[5] & 6'b011010) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & ~A[19] & ~A[18] & ~A[17] & ~A[16] & ~A[15] & ~A[14] & ~A[13] & ~A[12] & ~A[11] & ~A[10] & ~A[9] & ~A[8] & ~A[7] & ~A[6] & ~A[5] & A[4] & 6'b011011) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & ~A[19] & ~A[18] & ~A[17] & ~A[16] & ~A[15] & ~A[14] & ~A[13] & ~A[12] & ~A[11] & ~A[10] & ~A[9] & ~A[8] & ~A[7] & ~A[6] & ~A[5] & ~A[4] & A[3] & 6'b011100) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & ~A[19] & ~A[18] & ~A[17] & ~A[16] & ~A[15] & ~A[14] & ~A[13] & ~A[12] & ~A[11] & ~A[10] & ~A[9] & ~A[8] & ~A[7] & ~A[6] & ~A[5] & ~A[4] & ~A[3] & A[2] & 6'b011101) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & ~A[19] & ~A[18] & ~A[17] & ~A[16] & ~A[15] & ~A[14] & ~A[13] & ~A[12] & ~A[11] & ~A[10] & ~A[9] & ~A[8] & ~A[7] & ~A[6] & ~A[5] & ~A[4] & ~A[3] & ~A[2] & A[1] & 6'b011110) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & ~A[19] & ~A[18] & ~A[17] & ~A[16] & ~A[15] & ~A[14] & ~A[13] & ~A[12] & ~A[11] & ~A[10] & ~A[9] & ~A[8] & ~A[7] & ~A[6] & ~A[5] & ~A[4] & ~A[3] & ~A[2] & ~A[1] & A[0] & 6'b011111) | 
            (~A[31] & ~A[30] & ~A[29] & ~A[28] & ~A[27] & ~A[26] & ~A[25] & ~A[24] & ~A[23] & ~A[22] & ~A[21] & ~A[20] & ~A[19] & ~A[18] & ~A[17] & ~A[16] & ~A[15] & ~A[14] & ~A[13] & ~A[12] & ~A[11] & ~A[10] & ~A[9] & ~A[8] & ~A[7] & ~A[6] & ~A[5] & ~A[4] & ~A[3] & ~A[2] & ~A[1] & ~A[0] & 6'b100000);
        `ALU_OP_LUI: res = { B[15:0], 16'b0};
        `ALU_OP_B: res = B;
    endcase
    S <= res[31];
    Z <= res == 32'h00000000;
    if (op ==  `ALU_OP_ADD)
        V <= (A[31] & B[31] & ~res[31]) | (~A[31] & ~B[31] & res[31]);
    else if (op == `ALU_OP_SUB) 
        V <= (A[31] & ~B[31] & ~res[31]) | (~A[31] & B[31] & res[31]);
    else begin
        C = 32'h00000000;
        V <= 32'h00000000;
    end
end

endmodule
