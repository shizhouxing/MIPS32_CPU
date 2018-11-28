`timescale 1ns / 1ps

module exe_mem(
    input wire clk,
    input wire rst,
    input wire flush,
    input wire nop,
    input wire[31:0] inst_in,
    input wire alu_z,
    input wire[31:0] alu_res,
    input wire[31:0] pc_plus_8_in,
    input wire[4:0] reg_write_address_in,
    input wire[31:0] mem_write_data_in,

    input wire[31:0] data_A,

    // for forwarding
    input wire[4:0] forw_reg_write_address_wb,
    input wire forw_reg_write_wb,
    input wire[31:0] forw_reg_write_data_wb,
    input wire[4:0] forw_reg_write_address_end,
    input wire forw_reg_write_end,
    input wire[31:0] forw_reg_write_data_end,

    // control signals
    input wire con_reg_write,
    input wire con_mov_cond,

    // for mem
    input wire con_mem_byte_in,
    input wire con_mem_read_in,
    input wire con_mem_write_in,
    output reg con_mem_byte_out, 
    output reg con_mem_read_out,
    output reg con_mem_write_out,
    input wire[1:0] con_wb_src_in,
    output reg[1:0] con_wb_src_out,    

    // cp0
    input wire exe_cp0_we,
    input wire[4:0] exe_cp0_write_addr,
    input wire[31:0] exe_cp0_data,
    output reg mem_cp0_we,
    output reg[4:0] mem_cp0_write_addr,
    output reg[31:0] mem_cp0_data,
    
    // exception
    input wire[31:0] exe_exception,
    input wire[31:0] exe_exception_address,
    output reg[31:0] mem_exception,
    output reg[31:0] mem_exception_address,
    
    // delayslot
    input wire exe_this_delayslot,
    output reg mem_this_delayslot,
    
    
    output reg[31:0] pc_plus_8_out,
    output reg[31:0] mem_address,
    output reg[4:0] reg_write_address,
    output wire[31:0] mem_write_data,
    output reg[31:0] alu_res_out,
    output wire[31:0] mov_data,
    output reg reg_write
);

reg[4:0] read_address_1, read_address_2;
reg[31:0] mov_data_no_forw, mem_write_data_no_forw;

forward _forward_A(
    .source(3'b011),
    .read_address(read_address_1),
    .read_data(mov_data_no_forw),
    .reg_write_address_wb(forw_reg_write_address_wb),
    .reg_write_wb(forw_reg_write_wb),
    .reg_write_data_wb(forw_reg_write_data_wb),
    .reg_write_address_end(forw_reg_write_address_end),
    .reg_write_end(forw_reg_write_end),
    .reg_write_data_end(forw_reg_write_data_end),    
    .read_data_new(mov_data)
);

forward _forward_B(
    .source(3'b011),
    .read_address(read_address_2),
    .read_data(mem_write_data_no_forw),
    .reg_write_address_wb(forw_reg_write_address_wb),
    .reg_write_wb(forw_reg_write_wb),
    .reg_write_data_wb(forw_reg_write_data_wb),
    .reg_write_address_end(forw_reg_write_address_end),
    .reg_write_end(forw_reg_write_end),
    .reg_write_data_end(forw_reg_write_data_end),    
    .read_data_new(mem_write_data)
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        { reg_write, con_mem_read_out, con_mem_write_out } = 3'b000;
        mem_cp0_we <= 1'b0;
        mem_cp0_write_addr <= 4'b0;
        mem_cp0_data <= 31'b0;
        
        mem_exception <= 32'b0;
        mem_exception_address <= 32'b0;
        mem_this_delayslot <= 1'b0;
    end
    else if (flush == 1'b1) begin
        { reg_write, con_mem_read_out, con_mem_write_out } = 3'b000;
        mem_cp0_we <= 1'b0;
        mem_cp0_write_addr <= 4'b0;
        mem_cp0_data <= 31'b0;
        
        mem_exception <= 32'b0;
        mem_exception_address <= 32'b0;
        mem_this_delayslot <= 1'b0;
    end else begin
        if (nop) begin
            { con_mem_read_out, con_mem_write_out, reg_write } <= 3'b000;
            mem_cp0_we <= 1'b0;
            mem_cp0_write_addr <= 4'b0;
            mem_cp0_data <= 31'b0;
            mem_exception <= 32'b0;
            mem_exception_address <= 32'b0;
            mem_this_delayslot <= 1'b0;
        end
        else begin
            read_address_1 <= inst_in[25:21];
            read_address_2 <= inst_in[20:16];

            mem_cp0_we <= exe_cp0_we;
            mem_cp0_write_addr <= exe_cp0_write_addr;
            mem_cp0_data <= exe_cp0_data;
            
            mem_exception <= exe_exception;
            mem_exception_address <= exe_exception_address;
            mem_this_delayslot <= exe_this_delayslot;
            
            con_mem_byte_out <= con_mem_byte_in;
            con_mem_read_out <= con_mem_read_in;
            con_mem_write_out <= con_mem_write_in;

            con_wb_src_out <= con_wb_src_in;

            pc_plus_8_out <= pc_plus_8_in;
            mem_address <= alu_res;
            mem_write_data_no_forw <= mem_write_data_in;
            reg_write_address <= reg_write_address_in;

            // decide reg write
            reg_write <= con_reg_write & (~con_mov_cond | alu_z);
            
            alu_res_out <= alu_res;
            mov_data_no_forw <= data_A;
        end
    end
end

endmodule
