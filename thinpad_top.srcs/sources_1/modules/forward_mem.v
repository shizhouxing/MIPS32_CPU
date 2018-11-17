`timescale 1ns / 1ps

module forward_mem(
    input wire[4:0] read_address,
    input wire[31:0] read_data,

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
    if (reg_write_wb 
        && reg_write_address_wb != 5'b0 && reg_write_address_wb == read_address)
        read_data_new <= reg_write_data_wb;
    else if (reg_write_end 
        && reg_write_address_end != 5'b0 && reg_write_address_end == read_address)
        read_data_new <= reg_write_data_end;
    else
        read_data_new <= read_data;
end

endmodule