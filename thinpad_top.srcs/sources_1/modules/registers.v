`timescale 1ns / 1ps

module registers(
    input wire clk, 
    input wire[4:0] read_address_1,
    input wire[4:0] read_address_2,
    input wire[4:0] write_address,
    input wire[31:0] write_data,

    input wire reg_write,

    output reg[31:0] read_data_1,
    output reg[31:0] read_data_2
);

reg[31:0] r[0:31];

always @(posedge clk) begin
    read_data_1 <= (reg_write && (read_address_1 == write_address)) ? 
        write_data : r[read_address_1];
    read_data_2 <= (reg_write && (read_address_2 == write_address)) ? 
        write_data : r[read_address_2];
    if (reg_write)
        r[write_address] <= write_data;
end

endmodule