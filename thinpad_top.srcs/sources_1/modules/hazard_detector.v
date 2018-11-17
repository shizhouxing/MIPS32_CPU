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

    output reg[0:2] stall, // pc, if, id
    output reg[0:2] nop // if, id, exe
);

always @(*) begin
    if (
        // EXE MEM
        (read_address_1_exe != 5'b0 && read_address_1_exe == reg_write_address_mem && reg_write_mem && 
            (wb_src_mem == `WB_SRC_MOV || wb_src_mem == `WB_SRC_MEM)) || 
        (read_address_2_exe != 5'b0 && read_address_2_exe == reg_write_address_mem && reg_write_mem && 
            (wb_src_mem == `WB_SRC_MOV || wb_src_mem == `WB_SRC_MEM))
    ) begin
        stall <= 3'b111;
        nop <= 3'b001;
    end
    else if (
        // ID EXE
        (read_address_1_id != 5'b0 && read_address_1_id == reg_write_address_exe && reg_write_exe) ||
        (read_address_2_id != 5'b0 && read_address_2_id == reg_write_address_exe && reg_write_exe) ||
        // ID MEM
        (read_address_1_id != 5'b0 && read_address_1_id == reg_write_address_mem && reg_write_mem && 
            (wb_src_mem == `WB_SRC_MOV || wb_src_mem == `WB_SRC_MEM)) || 
        (read_address_2_id != 5'b0 && read_address_2_id == reg_write_address_mem && reg_write_mem && 
            (wb_src_mem == `WB_SRC_MOV || wb_src_mem == `WB_SRC_MEM))
    ) begin
        stall <= 3'b110;
        nop <= 3'b010;
    end
    else if (mem_conflict) begin
        stall <= 3'b100;
        nop <= 3'b100;
    end
    else begin
        stall <= 3'b000;
        nop <= 3'b000;
    end
end

endmodule