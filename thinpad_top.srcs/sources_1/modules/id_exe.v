`timescale 1ns / 1ps

module id_exe(
    input wire clk,
    input wire rst,
    input wire flush,
    input wire stall,
    input wire nop,
    input wire[31:0] data_1,
    input wire[31:0] data_2,
    input wire[31:0] inst_in,
    input wire[31:0] pc_plus_4,

    // for forward
    input wire[4:0] forw_reg_write_address_mem,
    input wire forw_reg_write_mem,
    input wire[1:0] forw_wb_src_mem,
    input wire[31:0] forw_pc_plus_8_mem,
    input wire[31:0] forw_alu_res_mem,
    input wire[4:0] forw_reg_write_address_wb,
    input wire forw_reg_write_wb,
    input wire[31:0] forw_reg_write_data_wb,

    // control signals
    input wire con_alu_immediate,
    input wire con_alu_signed,
    input wire con_alu_sa,
    input wire con_jal,
    input wire con_mfc0,
 
    // for exe
    input wire[4:0] con_alu_op_in,
    input wire con_reg_write_in,    
    input wire con_mov_cond_in,
    output reg[4:0] con_alu_op_out,
    output reg con_reg_write_out,
    output reg con_mov_cond_out,

    // for mem
    input wire con_mem_byte_in,
    input wire con_mem_read_in,
    input wire con_mem_write_in,
    output reg con_mem_byte_out, 
    output reg con_mem_read_out,
    output reg con_mem_write_out,
    input wire[1:0] con_wb_src_in,
    output reg[1:0] con_wb_src_out,
    
    // for exception
    input wire[31:0] id_exception,
    input wire[31:0] id_exception_address,
    output reg[31:0] exe_exception,
    output reg[31:0] exe_exception_address,
    
    // for delayslot
    input wire id_this_delayslot,
    input wire id_next_delayslot,
    output reg this_delayslot_out,
    output reg exe_this_delayslot,

    output wire[31:0] data_A, // for alu
    output wire[31:0] data_B, // for alu
    output reg[4:0] reg_write_address,
    output reg[31:0] mem_write_data,
    output reg[31:0] pc_plus_8,
    output reg[31:0] inst_out
); 

wire[31:0] immediate;
assign immediate = con_alu_signed ? { {16{inst_in[15]}}, inst_in[15:0] } : inst_in[15:0];

reg[4:0] read_address_1, read_address_2;
reg[31:0] data_A_no_forw, data_B_no_forw;
wire[31:0] data_A_forw, data_B_forw;
reg reg_data_A, reg_data_B; // whether data_A and data_B are from registers respectively

forward _forward_A(
    .source(3'b110),
    .read_address(read_address_1),
    .read_data(data_A_no_forw),
    .reg_write_address_mem(forw_reg_write_address_mem),
    .reg_write_mem(forw_reg_write_mem),
    .wb_src_mem(forw_wb_src_mem),
    .pc_plus_8_mem(forw_pc_plus_8_mem),
    .alu_res_mem(forw_alu_res_mem),
    .reg_write_address_wb(forw_reg_write_address_wb),
    .reg_write_wb(forw_reg_write_wb),
    .reg_write_data_wb(forw_reg_write_data_wb),
    .read_data_new(data_A_forw)
);   

forward _forward_B(
    .source(3'b110),
    .read_address(read_address_2),
    .read_data(data_B_no_forw),
    .reg_write_address_mem(forw_reg_write_address_mem),
    .reg_write_mem(forw_reg_write_mem),
    .wb_src_mem(forw_wb_src_mem),
    .pc_plus_8_mem(forw_pc_plus_8_mem),
    .alu_res_mem(forw_alu_res_mem),
    .reg_write_address_wb(forw_reg_write_address_wb),
    .reg_write_wb(forw_reg_write_wb),
    .reg_write_data_wb(forw_reg_write_data_wb),
    .read_data_new(data_B_forw)
);   

assign data_A = reg_data_A ? data_A_forw : data_A_no_forw;
assign data_B = reg_data_B ? data_B_forw : data_B_no_forw;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        con_reg_write_out <= 1'b0;
        con_mem_read_out <= 1'b0;
        con_mem_write_out <= 1'b0;
        
        con_mem_byte_out <= 1'b0;
        
        con_wb_src_out <= 2'b0;
        reg_write_address <= 5'b0;
        mem_write_data <= 32'b0;
        pc_plus_8 <= 32'b0;
        inst_out <= 32'b0;
        
        exe_exception <= 32'b0;
        exe_exception_address <= 32'b0;
        
        this_delayslot_out <= 32'b0;
        exe_this_delayslot <= 32'b0;
    end
    else if (flush == 1'b1) begin
        con_reg_write_out <= 1'b0;
        con_mem_read_out <= 1'b0;
        con_mem_write_out <= 1'b0;
        
        con_mem_byte_out <= 1'b0;
        
        con_wb_src_out <= 2'b0;
        reg_write_address <= 5'b0;
        mem_write_data <= 32'b0;
        pc_plus_8 <= 32'b0;
        inst_out <= 32'b0;
        
        exe_exception <= 32'b0;
        exe_exception_address <= 32'b0;
        
        this_delayslot_out <= 32'b0;
        exe_this_delayslot <= 32'b0;
    end else begin
        if (~stall) begin
            if (nop) begin
                { con_reg_write_out, con_mem_read_out, con_mem_write_out } <= 3'b000;
                inst_out <= 32'b0;
            end
            else begin
                inst_out <= inst_in;

                con_alu_op_out <= con_alu_op_in;
                con_reg_write_out <= con_reg_write_in;
                con_mov_cond_out <= con_mov_cond_in;

                con_mem_byte_out <= con_mem_byte_in;
                con_mem_read_out <= con_mem_read_in;
                con_mem_write_out <= con_mem_write_in;

                con_wb_src_out <= con_wb_src_in;

                read_address_1 <= inst_in[25:21];
                read_address_2 <= inst_in[20:16];

                data_A_no_forw <= con_alu_sa ? inst_in[10:6] : data_1;
                data_B_no_forw <= con_alu_immediate ? immediate : data_2;
                reg_data_A <= ~con_alu_sa;
                reg_data_B <= ~con_alu_immediate;

                pc_plus_8 <= pc_plus_4 + 4'h4;
                
                exe_exception <= id_exception;
                exe_exception_address <= id_exception_address;
                
                this_delayslot_out <= id_next_delayslot;
                exe_this_delayslot <= id_this_delayslot;
                
                if (con_jal)
                    reg_write_address <= 5'b11111; // save $31 for jal
                else
                    reg_write_address <= con_mfc0 ? inst_in[20:16] : (con_alu_immediate ? inst_in[20:16] : inst_in[15:11]);

                mem_write_data <= data_2;
            end
        end
    end
end

endmodule