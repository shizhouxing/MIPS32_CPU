`timescale 1ns / 1ps
`include "../modules/inst_mem.v"

module inst_mem_test(
    input  wire[31:0] dip_sw,
    output wire[15:0] leds,

    inout wire[31:0] base_ram_data,  
    output wire[19:0] base_ram_addr, 
    output wire[3:0] base_ram_be_n,  
    output wire base_ram_ce_n,       
    output wire base_ram_oe_n,       
    output wire base_ram_we_n       
);

wire[31:0] data;
assign leds = data[15:0];

inst_mem _inst_mem(
    .en(1'b0),
    .address(dip_sw),
    .data(data),
    .base_ram_data(base_ram_data),  
    .base_ram_addr(base_ram_addr), 
    .base_ram_be_n(base_ram_be_n),  
    .base_ram_ce_n(base_ram_ce_n),       
    .base_ram_oe_n(base_ram_oe_n),       
    .base_ram_we_n(base_ram_we_n)          
);

endmodule