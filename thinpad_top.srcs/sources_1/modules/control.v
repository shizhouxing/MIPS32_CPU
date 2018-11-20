`timescale 1ns / 1ps

`include "constants.v"

// generate control signals
module control(
    input wire[31:0] inst,

    // id
    output reg con_alu_immediate,
    output reg con_alu_signed,
    output reg con_alu_sa,
    output reg con_jal,

    // exe
    output reg[3:0] con_alu_op,
    output reg con_reg_write,    
    output reg con_mov_cond,

    // mem
    output reg con_mem_byte,
    output reg con_mem_read, 
    output reg con_mem_write,
    output reg con_mem_signed_extend,
    output reg[1:0] con_wb_src
);

always @(*) begin
    if (inst == 32'b0) begin // NOP
        { con_reg_write, con_mem_read, con_mem_write } = 3'b000;
    end
    else begin
        con_alu_sa <= (inst[31:26] == 6'b000000) && (
            (inst[5:0] == 6'b000000) || (inst[5:0] == 6'b000010));
        con_mov_cond <= (inst[31:26] == 6'b000000) && (inst[5:0] == 6'b001010);
        con_jal <= inst[31:26] == 6'b000011;
        con_mem_read <= inst[31:29] == 3'b100;
        con_mem_write <= inst[31:29] == 3'b101;

        case (inst[31:29])
            3'b001: begin // alu-based operations with an immediate number
                { con_alu_immediate, con_reg_write }  <= 2'b11;
                con_wb_src <= `WB_SRC_ALU;
                case (inst[28:26])
                    3'b001: begin // ADDIU 001001ssssstttttiiiiiiiiiiiiiiii
                        con_alu_op <= `ALU_OP_ADD;
                        con_alu_signed <= 1'b1;
                    end
                    3'b100: begin // ANDI 001100ssssstttttiiiiiiiiiiiiiiii
                        con_alu_op <= `ALU_OP_AND;
                        con_alu_signed <= 1'b0;
                    end
                    3'b101: begin // ORI 001101ssssstttttiiiiiiiiiiiiiiii
                        con_alu_op <= `ALU_OP_OR;
                        con_alu_signed <= 1'b0;
                    end
                    3'b110: begin // XORI 001110ssssstttttiiiiiiiiiiiiiiii
                        con_alu_op <= `ALU_OP_XOR;
                        con_alu_signed <= 1'b0;
                    end
                    3'b111: begin
                        con_alu_op <= `ALU_OP_LUI;
                        con_alu_signed <= 1'b0;
                    end
                endcase
            end

            3'b000: begin // alu-based operations without an immediate number, or branch/jump
                case (inst[28:26]) 
                    3'b000: begin
                        con_alu_immediate <= 1'b0;
                        con_reg_write <= inst[5:0] != 6'b001000; // JR
                        con_wb_src <= `WB_SRC_ALU;
                        case (inst[5:0])
                            6'b000000: begin // SLL 00000000000tttttdddddaaaaa000000
                                con_alu_op <= `ALU_OP_SLL;
                            end     
                            6'b000010: begin // SRL 00000000000tttttdddddaaaaa000010
                                con_alu_op <= `ALU_OP_SRL;
                            end                                                     
                            6'b100001: begin // ADDU 000000ssssstttttddddd00000100001
                                con_alu_op <= `ALU_OP_ADD;
                            end
                            6'b100010: begin // SUB 0000 00ss ssst tttt dddd d000 0010 0010
                                con_alu_op <= `ALU_OP_SUB;
                            end
                            6'b100100: begin // AND 000000ssssstttttddddd00000100100
                                con_alu_op <= `ALU_OP_AND;
                            end
                            6'b100101: begin // OR 000000ssssstttttddddd00000100101
                                con_alu_op <= `ALU_OP_OR;
                            end
                            6'b100110: begin // XOR 000000ssssstttttddddd00000100110
                                con_alu_op <= `ALU_OP_XOR;
                            end
                            6'b000110: begin // SRLV 000000ssssstttttddddd00000000110
                                con_alu_op <= `ALU_OP_SRL;
                            end
                            6'b001010: begin // MOVZ 000000ssssstttttddddd00000001010
                                con_alu_op <= `ALU_OP_B;
                            end
                        endcase
                    end
                    3'b011: begin // JAL
                        con_reg_write <= 1'b1;
                        con_wb_src <= `WB_SRC_PC_PLUS_8;
                    end
                    default: begin // branch or j or jr
                        con_reg_write <= 1'b0;
                    end
                endcase
            end

            3'b100: begin // load
                { con_alu_immediate, con_alu_signed, con_reg_write }  <= 3'b111;
                con_alu_op <= `ALU_OP_ADD;
                con_wb_src <= `WB_SRC_MEM;
                case (inst[28:26])
                    3'b000: begin // LB
                        con_mem_byte <= 1'b1;
                        con_mem_signed_extend <= 1'b1;
                    end
                    3'b011: begin // LW
                        con_mem_byte <= 1'b0;
                        con_mem_signed_extend <= 1'b0;
                    end
                    3'b100: begin // LBU
                        con_mem_byte <= 1'b1;
                        con_mem_signed_extend <= 1'b0;
                    end
                endcase
            end

            3'b101: begin // store
                { con_alu_immediate, con_alu_signed, con_reg_write }  <= 3'b110;
                con_alu_op <= `ALU_OP_ADD;
                case (inst[28:26])
                    3'b000: begin // SB
                        con_mem_byte <= 1'b1;
                    end
                    3'b011: begin // SW
                        con_mem_byte <= 1'b0;
                    end
                endcase
            end

            3'b011: begin // CLZ
                { con_alu_immediate, con_reg_write, con_mem_write} <= 3'b010;
                con_wb_src <= `WB_SRC_ALU;
                con_alu_op <= `ALU_OP_CLZ;
            end

        endcase
    end
end

endmodule
