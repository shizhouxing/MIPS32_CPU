`timescale 1ns / 1ps

module data_mem_test(
    input wire clk,
    input wire[31:0] dip_sw, 
    output wire[15:0] leds,

    inout wire[31:0] base_ram_data,  
    output wire[19:0] base_ram_addr, 
    output wire[3:0] base_ram_be_n,  
    output wire base_ram_ce_n,       
    output wire base_ram_oe_n,       
    output wire base_ram_we_n     
);

wire[31:0] data_out;
assign leds = data_out[15:0];
reg[31:0] address, data_in;

data_mem _data_mem(
    .clk(clk),
    .en(1'b0),
    .mask(4'h0),
    
    .write(dip_sw[31]),
    .address(address),
    .data_in(data_in),
    .data_out(data_out),

    .ram_data(base_ram_data),
    .ram_addr(base_ram_addr),
    .ram_be_n(base_ram_be_n),
    .ram_ce_n(base_ram_ce_n),
    .ram_oe_n(base_ram_oe_n),
    .ram_we_n(base_ram_we_n)
);

always @(posedge clk) begin
    address <= { 3'b000, 12'h000, dip_sw[30:16]};
    data_in <= { 16'h0000, dip_sw[15:0]};
end

endmodule