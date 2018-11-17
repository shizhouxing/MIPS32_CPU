`timescale 1ns / 1ps

module ram_controller(
    input wire clk,

    input wire[31:0] inst_addr,
    input wire[31:0] data_addr,
    input wire[3:0] mask,
    input wire[31:0] data,
    input wire data_en,
    input wire data_read,
    input wire data_write,

    inout wire[31:0] base_ram_data, 
    output wire[19:0] base_ram_addr, 
    output wire[3:0] base_ram_be_n, 
    output wire base_ram_ce_n, 
    output wire base_ram_oe_n, 
    output wire base_ram_we_n, 

    inout wire[31:0] ext_ram_data, 
    output reg[19:0] ext_ram_addr,
    output wire[3:0] ext_ram_be_n,
    output wire ext_ram_ce_n, 
    output wire ext_ram_oe_n, 
    output wire ext_ram_we_n, 

    output wire[31:0] result_inst,
    output wire[31:0] result_data,
    output reg conflict
);

reg base_write, ext_write;
assign result_inst = ext_ram_data;
assign result_data = (conflict ? ext_ram_data : base_ram_data) & ~mask;
assign ext_ram_ce_n = 1'b0;
//assign base_ram_ce_n = data_en;
assign base_ram_ce_n = 1'b0;
assign base_ram_we_n = base_write ? ~clk : 1'b1;
assign ext_ram_we_n = ext_write ? ~clk : 1'b1;
assign base_ram_oe_n = ~base_write ? 1'b0 : 1'b1;
assign ext_ram_oe_n = ~ext_write ? 1'b0 : 1'b1;
assign base_ram_be_n = base_write ? mask : 4'b0;
assign ext_ram_be_n = ext_write ? mask : 4'b0;
assign base_ram_data = base_write ? data : 32'bz;
assign ext_ram_data = ext_write ? data : 32'bz;
assign base_ram_addr = data_addr[21:2];

always @(*) begin
    if (data_en) begin
        conflict <= 1'b0;
        { base_write, ext_write } <= 2'b00;
        ext_ram_addr <= inst_addr[21:2];
    end
    else begin
        if (~data_addr[22]) begin // conflict on ext ram
            conflict <= 1'b1;
            base_write <= 1'b0;
            ext_write <= data_write;
            ext_ram_addr <= data_addr[21:2];
        end
        else begin
            conflict <= 1'b0;
            base_write <= data_write;
            ext_write <= 1'b0;
            ext_ram_addr <= inst_addr[21:2];
        end
    end
end

endmodule