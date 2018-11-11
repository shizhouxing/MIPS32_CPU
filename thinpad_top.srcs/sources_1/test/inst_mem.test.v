`timescale 1ns / 1ps

module inst_mem_test(
    input  wire[31:0] dip_sw,
    output wire[15:0] leds,

    inout wire[31:0] ext_ram_data,  
    output wire[19:0] ext_ram_addr, 
    output wire[3:0] ext_ram_be_n,  
    output wire ext_ram_ce_n,       
    output wire ext_ram_oe_n,       
    output wire ext_ram_we_n       
);

wire[31:0] data;
assign leds = data[15:0];

inst_mem _inst_mem(
    .en(1'b0),
    .address(dip_sw),
    .data(data),
    .ram_data(ext_ram_data),  
    .ram_addr(ext_ram_addr), 
    .ram_be_n(ext_ram_be_n),  
    .ram_ce_n(ext_ram_ce_n),       
    .ram_oe_n(ext_ram_oe_n),       
    .ram_we_n(ext_ram_we_n)          
);

endmodule