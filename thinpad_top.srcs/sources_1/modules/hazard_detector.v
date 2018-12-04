`timescale 1ns / 1ps

module hazard_detector(
    input wire[4:0] read_address_1_id,
    input wire[4:0] read_address_2_id,
    input wire[4:0] reg_write_address_exe,
    input wire reg_write_exe,

    input wire[4:0] read_address_1_exe,
    input wire[4:0] read_address_2_exe,
    input wire[4:0] reg_write_address_mem,
    input wire reg_write_mem,
    input wire[1:0] wb_src_mem,

    input wire mem_conflict,
    input wire con_pc_jump,

    input wire uart_en, 
    input wire[3:0] uart_state,
    
    input wire div_stall,

    output wire[0:4] stall, // pc, if/id, id/exe, exe/mem, mem/wb
    output wire[0:4] nop // if/id, id/exe, exe/mem, mem/wb, wb/end
);

wire hazard_exe_mem, hazard_id_exe, hazard_id_mem;
assign hazard_exe_mem = 
    (read_address_1_exe != 5'b0 && read_address_1_exe == reg_write_address_mem && reg_write_mem && 
        (wb_src_mem == `WB_SRC_MOV || wb_src_mem == `WB_SRC_MEM)) || 
    (read_address_2_exe != 5'b0 && read_address_2_exe == reg_write_address_mem && reg_write_mem && 
        (wb_src_mem == `WB_SRC_MOV || wb_src_mem == `WB_SRC_MEM));
assign hazard_id_exe = 
    (read_address_1_id != 5'b0 && read_address_1_id == reg_write_address_exe && reg_write_exe) ||
    (read_address_2_id != 5'b0 && read_address_2_id == reg_write_address_exe && reg_write_exe);
assign hazard_id_mem = 
    (read_address_1_id != 5'b0 && read_address_1_id == reg_write_address_mem && reg_write_mem && 
        (wb_src_mem == `WB_SRC_MOV || wb_src_mem == `WB_SRC_MEM)) || 
    (read_address_2_id != 5'b0 && read_address_2_id == reg_write_address_mem && reg_write_mem && 
        (wb_src_mem == `WB_SRC_MOV || wb_src_mem == `WB_SRC_MEM)) || 
    (mem_conflict && con_pc_jump);

wire hazard_wb, hazard_mem, hazard_exe, hazard_id, hazard_if;
assign hazard_wb = ~uart_en & (uart_state < 4'h9) | div_stall;
assign hazard_mem = (~uart_en & (uart_state < 4'h9)) | div_stall;
assign hazard_exe = hazard_exe_mem | div_stall;
assign hazard_id = hazard_id_exe | hazard_id_mem;
assign hazard_if = mem_conflict;

assign stall = { 
    hazard_wb | hazard_mem | hazard_exe | hazard_id | hazard_if, 
    hazard_wb | hazard_mem | hazard_exe | hazard_id, 
    hazard_wb | hazard_mem | hazard_exe,
    hazard_wb | hazard_mem,
    hazard_wb
};
assign nop = { 
    hazard_if & ~hazard_id & ~hazard_exe & ~hazard_mem & ~hazard_wb, 
    hazard_id & ~hazard_exe & ~hazard_mem & ~hazard_wb,  
    hazard_exe & ~hazard_mem & ~hazard_wb, 
    hazard_mem  & ~hazard_wb,
    hazard_wb
};

endmodule
