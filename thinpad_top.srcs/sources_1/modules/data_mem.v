`timescale 1ns / 1ps

module data_mem(
    input wire clk,
    input wire en,
    input wire[31:0] mask,
    input wire write,
    input wire[31:0] address,
    input wire[31:0] data_in,
    output wire[31:0] data_out,

    inout wire[31:0] ram_data,
    output wire[19:0] ram_addr,
    output wire[3:0] ram_be_n,
    output wire ram_ce_n, 
    output wire ram_oe_n, 
    output wire ram_we_n 
);

assign ram_ce_n = en;
assign ram_we_n = write ? ~clk : 1'b1;
assign ram_oe_n = ~write ? 1'b0 : 1'b1;
assign ram_be_n = mask;
assign ram_addr = address[21:2];
assign ram_data = write ? data_in : 32'bz;
assign data_out = ram_data;

endmodule
