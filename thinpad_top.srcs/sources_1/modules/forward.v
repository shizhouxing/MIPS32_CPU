`timescale 1ns / 1ps

module forward(
    input wire[0:2] source,

    input wire[4:0] read_address,
    input wire[31:0] read_data,

    // forward from mem
    input wire[4:0] reg_write_address_mem,
    input wire reg_write_mem,
    input wire[1:0] wb_src_mem,
    input wire[31:0] pc_plus_8_mem,
    input wire[31:0] alu_res_mem,

    // forward from wb
    input wire[4:0] reg_write_address_wb,
    input wire reg_write_wb,
    input wire[31:0] reg_write_data_wb,

    // forward from end
    input wire[4:0] reg_write_address_end,
    input wire reg_write_end,
    input wire[31:0] reg_write_data_end,    

    output reg[31:0] read_data_new
);

always @(*) begin
    if (source[0] && reg_write_mem 
        && reg_write_address_mem != 5'b0 && reg_write_address_mem == read_address
        && (wb_src_mem == `WB_SRC_PC_PLUS_8 || wb_src_mem == `WB_SRC_ALU)
    )
        read_data_new <= (wb_src_mem == `WB_SRC_PC_PLUS_8) ? pc_plus_8_mem : alu_res_mem;
    else if (source[1] && reg_write_wb 
            && reg_write_address_wb != 5'b0 && reg_write_address_wb == read_address)
                read_data_new <= reg_write_data_wb;
    else if (source[2] && reg_write_end 
        && reg_write_address_end != 5'b0 && reg_write_address_end == read_address)
        read_data_new <= reg_write_data_end;
    else
        read_data_new <= read_data;
end

endmodule