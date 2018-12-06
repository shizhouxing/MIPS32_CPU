`timescale 1ns / 1ps

module hazard_detector(
    input wire[31:0] inst_id,
    input wire[31:0] inst_exe,

    input wire[4:0] reg_write_address_exe,
    input wire reg_write_exe,

    input wire[4:0] reg_write_address_mem,
    input wire reg_write_mem,
    input wire[1:0] wb_src_mem,

    input wire mem_conflict,
    input wire con_pc_jump,

    input wire ram_en,
    input wire mem_write,
    input wire[1:0] ram_state,
    input wire uart_en, 
    input wire[3:0] uart_state,
    
    input wire div_stall,
    input wire flash_stall,

    output wire[0:3] stall, // pc, if/id, id/exe, exe/mem, mem/wb
    output wire[0:3] nop // if/id, id/exe, exe/mem, mem/wb
);

reg[4:0] read_address_1_id, read_address_2_id, read_address_1_exe, read_address_2_exe;

always @(*) begin
    if (inst_id[31:21] == 11'b01000110000 && (inst_id[5:0] == 6'b000010 || inst_id[5:0] == 6'b000011)) begin
        read_address_1_id <= inst_id[15:11];
        read_address_2_id <= inst_id[20:16];
    end
    else begin
        read_address_1_id <= inst_id[25:21];
        read_address_2_id <= inst_id[20:16];        
    end
    if (inst_exe[31:21] == 11'b01000110000 && (inst_exe[5:0] == 6'b000010 || inst_exe[5:0] == 6'b000011)) begin
        read_address_1_exe <= inst_exe[15:11];
        read_address_2_exe <= inst_exe[20:16];
    end
    else begin
        read_address_1_exe <= inst_exe[25:21];
        read_address_2_exe <= inst_exe[20:16];        
    end    
end

wire hazard_exe_mem, hazard_id_exe, hazard_id_mem, busy_mem;
assign hazard_exe_mem = 
    (read_address_1_exe != 5'b0 && read_address_1_exe == reg_write_address_mem && reg_write_mem && 
        (wb_src_mem == `WB_SRC_MOV || wb_src_mem == `WB_SRC_MEM)) || 
    (read_address_2_exe != 5'b0 && read_address_2_exe == reg_write_address_mem && reg_write_mem && 
        (wb_src_mem == `WB_SRC_MOV || wb_src_mem == `WB_SRC_MEM));
assign hazard_id_exe = 
    ((read_address_1_id != 5'b0 && read_address_1_id == reg_write_address_exe && reg_write_exe) ||
    (read_address_2_id != 5'b0 && read_address_2_id == reg_write_address_exe && reg_write_exe))
    & ((inst_id[31:26] == 6'b000100) | (inst_id[31:26] == 6'b000111) | 
        (inst_id[31:26] == 6'b000101) | (inst_id[31:26] == 6'b000000 & inst_id[5:0] == 6'b001000));
assign hazard_id_mem = 
    (read_address_1_id != 5'b0 && read_address_1_id == reg_write_address_mem && reg_write_mem && 
        (wb_src_mem == `WB_SRC_MOV || wb_src_mem == `WB_SRC_MEM)) || 
    (read_address_2_id != 5'b0 && read_address_2_id == reg_write_address_mem && reg_write_mem && 
        (wb_src_mem == `WB_SRC_MOV || wb_src_mem == `WB_SRC_MEM)) 
    ;
assign busy_mem = (~uart_en & (uart_state < 4'hf)) 
    | (mem_write & ~ram_en & (ram_state < 2'b10)) 
    | flash_stall;

wire hazard_wb, hazard_mem, hazard_exe, hazard_id, hazard_if;
assign hazard_wb = busy_mem | div_stall;
assign hazard_mem = busy_mem | div_stall;
assign hazard_exe = hazard_exe_mem | div_stall;
assign hazard_id = (hazard_id_exe | hazard_id_mem) || (mem_conflict && con_pc_jump);
assign hazard_if = mem_conflict;

assign stall = { 
    hazard_mem | hazard_exe | hazard_id | hazard_if, 
    hazard_mem | hazard_exe | hazard_id, 
    hazard_mem | hazard_exe,
    hazard_mem
};
assign nop = { 
    hazard_if & ~hazard_id & ~hazard_exe & ~hazard_mem, 
    hazard_id & ~hazard_exe & ~hazard_mem,  
    hazard_exe & ~hazard_mem, 
    hazard_mem
};

endmodule
