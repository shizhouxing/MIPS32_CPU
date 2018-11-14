`timescale 1ns / 1ps

// generate control signals
module control(
    input wire[5:0] op,

    output wire con_alu_immediate,
    output wire con_alu_signed,
    output wire con_alu_sa,
    output wire[1:0] con_reg_dst,

    output wire[3:0] con_alu_op,
    output wire[1:0] con_reg_data,
    output wire con_branch,
    output wire con_branch_rev,
    output wire con_branch_s,
    output wire con_jump,
    output wire[3:0] con_mem_mask,
    output wire con_mem_write,
    output wire con_wb_memory, 
    output wire con_reg_write, 
    output wire con_mov_cond
);

endmodule
