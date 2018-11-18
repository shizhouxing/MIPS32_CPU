`timescale 1ns / 1ps

module uart_controller(
    input wire clk,
    input wire[31:0] address,
    input wire[31:0] data,
    input wire en,
    input wire data_read,
    input wire data_write,

    inout wire[7:0] uart_data,
    output reg uart_rdn,     
    output reg uart_wrn,     
    input wire uart_dataready,
    input wire uart_tbre,     
    input wire uart_tsre,

    output reg[31:0] result_data
);

reg write;
assign uart_data = write ? data : 8'bz;

always @(*) begin
    if (en) begin
        write <= 1'b0;
        { uart_rdn, uart_wrn } <= 2'b11;
    end
    else if (address == 32'hBFD003FC) begin
        write <= 1'b0;
        { uart_rdn, uart_wrn } <= 2'b11;
        result_data <= { 30'b0, uart_dataready, uart_tsre };
    end
    else begin
        if (data_write) begin
            write <= 1'b1;
            { uart_rdn, uart_wrn }  <= { 1'b1, ~clk};        
        end
        else begin
            write <= 1'b0;
            { uart_rdn, uart_wrn }  <= { ~clk, 1'b1 };
            result_data <= { 24'b0, uart_data };        
        end
    end
end

endmodule