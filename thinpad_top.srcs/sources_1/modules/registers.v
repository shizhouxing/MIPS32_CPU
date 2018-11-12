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

// TODO

endmodule