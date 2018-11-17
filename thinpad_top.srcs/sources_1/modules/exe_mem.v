`timescale 1ns / 1ps

module exe_mem(
    input wire clk,
    input wire rst,
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
    input wire[3:0] con_mem_mask_in,
    input wire con_mem_write_in,
    input wire con_mem_signed_extend_in,
    output reg[3:0] con_mem_mask_out, 
    output reg con_mem_write_out,
    output reg con_mem_signed_extend_out,
    input wire[1:0] con_wb_src_in,
    output reg[1:0] con_wb_src_out,    

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

forward_mem _forward_mem_A(
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

forward_mem _forward_mem_B(
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
        reg_write <= 1'b0;
        con_mem_write_out <= 1'b0;
    end
    else begin
        read_address_1 <= inst_in[25:21];
        read_address_2 <= inst_in[20:16];

        con_mem_mask_out <= con_mem_mask_in;
        con_mem_write_out <= con_mem_write_in;
        con_mem_signed_extend_out <= con_mem_signed_extend_in;

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

endmodule
