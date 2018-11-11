`timescale 1ns / 1ps

// instruction memory
module inst_mem(
    input wire en,
    input wire[31:0] address,
    output wire[31:0] data,

    inout wire[31:0] ram_data,  
    output wire[19:0] ram_addr, 
    output wire[3:0] ram_be_n,  
    output wire ram_ce_n,       
    output wire ram_oe_n,       
    output wire ram_we_n      
);

assign ram_ce_n = en;
assign ram_oe_n = 1'b0;
assign ram_we_n = 1'b1;
assign ram_be_n = 4'h0;
assign ram_data = 32'bz;
assign ram_addr = address[21:2];
assign data = ram_data;

endmodule