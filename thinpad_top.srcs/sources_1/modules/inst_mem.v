`timescale 1ns / 1ps

// instruction memory
module inst_mem(
    input wire en,
    input wire[31:0] address,
    output wire[31:0] data,

    inout wire[31:0] base_ram_data,  
    output wire[19:0] base_ram_addr, 
    output wire[3:0] base_ram_be_n,  
    output wire base_ram_ce_n,       
    output wire base_ram_oe_n,       
    output wire base_ram_we_n      
);

assign base_ram_ce_n = en;
assign base_ram_oe_n = 1'b0;
assign base_ram_we_n = 1'b1;
assign base_ram_be_n = 4'h0;
assign base_ram_data = 32'bz;
assign base_ram_addr = address[21:2];
assign data = base_ram_data;

endmodule