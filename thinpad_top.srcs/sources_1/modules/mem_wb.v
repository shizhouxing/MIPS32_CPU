`timescale 1ns / 1ps

`include "constants.v"

module mem_wb(
    input wire clk,
    input wire rst,
    input wire nop,
    input wire reg_write_in,
    input wire[4:0] reg_write_address_in,
    input wire[31:0] pc_plus_8,
    input wire[31:0] mov_data,
    input wire[31:0] mem_read_data,
    input wire[31:0] alu_res,

    input wire[1:0] con_wb_src,
    input wire con_mem_byte,

    // cp0
    input wire mem_cp0_we,
    input wire[4:0] mem_cp0_write_addr,
    input wire[31:0] mem_cp0_data,
    output reg wb_cp0_we,
    output reg[4:0] wb_cp0_write_addr,
    output reg[31:0] wb_cp0_data,
    
    // exception
    input wire flush,
    input wire reg_write_disable_in,

    output reg reg_write_out,
    output reg[4:0] reg_write_address_out,
    output reg[31:0] reg_write_data
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        reg_write_out <= 1'b0;
        wb_cp0_we <= 1'b0;
        wb_cp0_write_addr <= 4'b0;
        wb_cp0_data <= 32'b0;
    end else if (flush == 1'b1) begin
        reg_write_out <= 1'b0;
        wb_cp0_we <= 1'b0;
        wb_cp0_write_addr <= 4'b0;
        wb_cp0_data <= 32'b0;
    end else begin
        if (nop) begin
            reg_write_out <= 1'b0;
        end
        else begin
            if (reg_write_disable_in == 1'b1) begin
                reg_write_out <= 1'b0;
            end else begin
                reg_write_out <= reg_write_in;
            end
            reg_write_address_out <= reg_write_address_in;
            
            wb_cp0_we <= mem_cp0_we;
            wb_cp0_write_addr <= mem_cp0_write_addr;
            wb_cp0_data <= mem_cp0_data;
            
            case (con_wb_src)
                `WB_SRC_PC_PLUS_8:
                    reg_write_data <= pc_plus_8;
                `WB_SRC_MOV:
                    reg_write_data <= mov_data;
                `WB_SRC_MEM: begin
                    if (con_mem_byte)
                        reg_write_data <= $signed(mem_read_data[7:0]);
                    else
                        reg_write_data <= mem_read_data;
                end
                `WB_SRC_ALU:
                    reg_write_data <= alu_res;
            endcase
        end
    end
end

endmodule
