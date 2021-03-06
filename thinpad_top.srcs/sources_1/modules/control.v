`timescale 1ns / 1ps

`include "constants.v"

// generate control signals
module control(
    input wire[31:0] inst,
    input wire[31:0] pc,
    
    // register
    output reg[31:0] read_address_1,
    output reg[31:0] read_address_2,
    
    /*
       [8]   syscall
       [9]   instruction valid
       [12]  eret
    */
    // exception
    output reg[31:0] exception_out,
    output reg[31:0] exception_address_out,

    // id
    output reg con_alu_immediate,
    output reg con_alu_signed,
    output reg con_alu_sa, // for SLL and SRL
    output reg con_jal, // for JAL
    output reg con_mfc0, // for mfc0
    output reg con_muls, // for muls
    output reg con_divs, // for divs

    // exe
    output reg[4:0] con_alu_op,
    output reg con_reg_write,    
    output reg con_mov_cond, // conditional mov

    // mem
    output reg con_mem_byte, // byte load or store
    output reg con_mem_unsigned,
    output reg con_mem_read, 
    output reg con_mem_write,
    output reg[1:0] con_wb_src
);

reg valid;

always @(*) begin
    if (inst == 32'b0) begin // NOP
        { con_reg_write, con_mem_read, con_mem_write } <= 3'b000;
        exception_out <= 32'b0;
        exception_address_out <= 32'b0;
        
        con_jal <= 1'b0;
        con_muls <= 1'b0;
        con_mfc0 <= 1'b0;
        con_wb_src <= `WB_SRC_ALU;
        con_alu_op <= `ALU_OP_ADD;

        read_address_1 <= 5'b0;
        read_address_2 <= 5'b0;
    end
    else begin
        con_alu_sa <= (inst[31:26] == 6'b000000) && (
            (inst[5:0] == 6'b000000) || (inst[5:0] == 6'b000010));
        con_mov_cond <= (inst[31:26] == 6'b000000) && (inst[5:0] == 6'b001010);
        con_jal <= inst[31:26] == 6'b000011;
        con_mem_read <= inst[31:29] == 3'b100;
        con_mem_write <= inst[31:29] == 3'b101;
        con_mfc0 <= inst[31:29] == 3'b010 && inst[28:21] == 8'b00000000;
        con_muls <= inst[31:21] == 11'b01000110000 && inst[5:0] == 6'b000010;
        con_divs <= inst[31:21] == 11'b01000110000 && inst[5:0] == 6'b000011;
        
        exception_out <= 32'b0;
        exception_out[9] <= 1'b1;
        exception_address_out <= pc;

        if (inst[31:21] == 11'b01000110000 && (inst[5:0] == 6'b000010 || inst[5:0] == 6'b000011)) begin
            read_address_1 <= inst[15:11];
            read_address_2 <= inst[20:16];
        end
        else begin
            read_address_1 <= inst[25:21];
            read_address_2 <= inst[20:16];        
        end
    
        case (inst[31:26])
            6'b000100: begin // BEQ
                exception_out[9] <= 1'b0;
            end
            6'b000111: begin // BGTZ
                exception_out[9] <= 1'b0;
            end
            6'b000101: begin // BNE
                exception_out[9] <= 1'b0;
            end
            6'b000010: begin // J
                exception_out[9] <= 1'b0;
            end
            6'b000011: begin // JAL
                exception_out[9] <= 1'b0;
            end
        endcase
        
        case (inst[31:29])
            3'b010: begin // exceptions
                { con_alu_immediate, con_alu_signed } <= 2'b00;
                case (inst[28:21]) 
                    8'b00000000: begin // mfc0, inst[10:0] == 11'b0
                        // GPR[rt] <- CPR[0, rd]
                        con_reg_write <= 1'b1;
                        con_wb_src <= `WB_SRC_ALU;
                        con_alu_op <= `ALU_OP_MFC0;
                        exception_out[9] <= 1'b0;
                    end
                    8'b00000100: begin // mtc0, inst[10:0] == 11'b0
                        // CPR[0, rd] <- GPR[rt]
                        con_reg_write <= 1'b0;
                        con_alu_op <= `ALU_OP_MTC0;
                        exception_out[9] <= 1'b0;                    
                    end
                    8'b00010000: begin // eret, last: 000000000000000011000
                        con_reg_write <= 1'b0;
                        con_wb_src <= `WB_SRC_ALU;
                        con_alu_op <= `ALU_OP_ERET;
                        exception_out[9] <= 1'b0;
                        exception_out[12] <= 1'b1;                    
                    end
                    8'b00110000: begin // mul.s
                        case (inst[5:0])
                            6'b000010: begin // MUL.S
                                con_reg_write <= 1'b1;
                                con_wb_src <= `WB_SRC_ALU;
                                con_alu_op <= `ALU_OP_MULS;
                                exception_out[9] <= 1'b0;
                            end
                            6'b000011: begin // DIV.S
                                con_reg_write <= 1'b1;
                                con_wb_src <= `WB_SRC_ALU;
                                con_alu_op <= `ALU_OP_DIVS;
                                exception_out[9] <= 1'b0;
                            end
                        endcase
                    end
                endcase
            end

            3'b001: begin // alu-based operations with an immediate number
                { con_alu_immediate, con_reg_write }  <= 2'b11;
                con_wb_src <= `WB_SRC_ALU;
                case (inst[28:26])
                    3'b001: begin // ADDIU 001001ssssstttttiiiiiiiiiiiiiiii
                        con_alu_op <= `ALU_OP_ADD;
                        con_alu_signed <= 1'b1;
                        exception_out[9] <= 1'b0;
                    end
                    3'b100: begin // ANDI 001100ssssstttttiiiiiiiiiiiiiiii
                        con_alu_op <= `ALU_OP_AND;
                        con_alu_signed <= 1'b0;
                        exception_out[9] <= 1'b0;
                    end
                    3'b101: begin // ORI 001101ssssstttttiiiiiiiiiiiiiiii
                        con_alu_op <= `ALU_OP_OR;
                        con_alu_signed <= 1'b0;
                        exception_out[9] <= 1'b0;
                    end
                    3'b110: begin // XORI 001110ssssstttttiiiiiiiiiiiiiiii
                        con_alu_op <= `ALU_OP_XOR;
                        con_alu_signed <= 1'b0;
                        exception_out[9] <= 1'b0;
                    end
                    3'b111: begin
                        con_alu_op <= `ALU_OP_LUI;
                        con_alu_signed <= 1'b0;
                        exception_out[9] <= 1'b0;
                    end
                endcase
            end

            3'b000: begin // alu-based operations without an immediate number, or branch/jump, or syscall
                con_alu_immediate <= 1'b0;
                con_alu_signed <= 1'b0;
                case (inst[28:26]) 
                    3'b000: begin
                        con_reg_write <= 
                            inst[5:0] != 6'b001000 && inst[5:0] != 6'b001100; // not JR or syscall
                        con_wb_src <= `WB_SRC_ALU;
                        case (inst[5:0])
                            6'b001100: begin // syscall
                                con_alu_op <= `ALU_OP_SYSCALL;
                                exception_out[9] <= 1'b0;
                                exception_out[8] <= 1'b1;                                 
                            end
                            6'b000000: begin // SLL 00000000000tttttdddddaaaaa000000
                                con_alu_op <= `ALU_OP_SLL;
                                exception_out[9] <= 1'b0;
                            end     
                            6'b000010: begin // SRL 00000000000tttttdddddaaaaa000010
                                con_alu_op <= `ALU_OP_SRL;
                                exception_out[9] <= 1'b0;
                            end                                                     
                            6'b100001: begin // ADDU 000000ssssstttttddddd00000100001
                                con_alu_op <= `ALU_OP_ADD;
                                exception_out[9] <= 1'b0;
                            end
                            6'b100010: begin // SUB 0000 00ss ssst tttt dddd d000 0010 0010
                                con_alu_op <= `ALU_OP_SUB;
                                exception_out[9] <= 1'b0;
                            end
                            6'b100100: begin // AND 000000ssssstttttddddd00000100100
                                con_alu_op <= `ALU_OP_AND;
                                exception_out[9] <= 1'b0;
                            end
                            6'b100101: begin // OR 000000ssssstttttddddd00000100101
                                con_alu_op <= `ALU_OP_OR;
                                exception_out[9] <= 1'b0;
                            end
                            6'b100110: begin // XOR 000000ssssstttttddddd00000100110
                                con_alu_op <= `ALU_OP_XOR;
                                exception_out[9] <= 1'b0;
                            end
                            6'b000110: begin // SRLV 000000ssssstttttddddd00000000110
                                con_alu_op <= `ALU_OP_SRL;
                                exception_out[9] <= 1'b0;
                            end
                            6'b001010: begin // MOVZ 000000ssssstttttddddd00000001010
                                con_alu_op <= `ALU_OP_B;
                                con_wb_src <= `WB_SRC_MOV;
                                exception_out[9] <= 1'b0;
                            end
                            6'b001000: begin // JR
                                exception_out[9] <= 1'b0;
                            end
                        endcase
                    end
                    3'b011: begin // JAL
                        con_reg_write <= 1'b1;
                        con_wb_src <= `WB_SRC_PC_PLUS_8;
                        exception_out[9] <= 1'b0;
                    end
                    default: begin // branch or j
                        con_reg_write <= 1'b0;
                        exception_out[9] <= 1'b0;
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
                        con_mem_unsigned <= 1'b0;
                        exception_out[9] <= 1'b0;
                    end
                    3'b011: begin // LW
                        con_mem_byte <= 1'b0;
                        exception_out[9] <= 1'b0;
                    end
                    3'b100: begin // LBU
                        con_mem_byte <= 1'b1;
                        con_mem_unsigned <= 1'b1;
                        exception_out[9] <= 1'b0;
                    end
                endcase
            end

            3'b101: begin // store
                { con_alu_immediate, con_alu_signed, con_reg_write }  <= 3'b110;
                con_alu_op <= `ALU_OP_ADD;
                case (inst[28:26])
                    3'b000: begin // SB
                        con_mem_byte <= 1'b1;
                        exception_out[9] <= 1'b0;
                    end
                    3'b011: begin // SW
                        con_mem_byte <= 1'b0;
                        exception_out[9] <= 1'b0;
                    end
                endcase
            end

            3'b011: begin // CLZ
                { con_alu_immediate, con_reg_write, con_mem_write} <= 3'b010;
                con_wb_src <= `WB_SRC_ALU;
                con_alu_op <= `ALU_OP_CLZ;
                exception_out[9] <= 1'b0;
            end
        endcase
    end
end

endmodule
