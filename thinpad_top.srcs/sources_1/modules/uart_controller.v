`timescale 1ns / 1ps

module uart_controller(
    input wire clk,
    input wire rst, 
    input wire[31:0] address,
    input wire[7:0] data,
    input wire en,
    input wire data_read,
    input wire data_write,

    inout wire[7:0] uart_data,
    output reg uart_rdn,     
    output reg uart_wrn,     
    input wire uart_dataready,
    input wire uart_tbre,     
    input wire uart_tsre,

    output reg[31:0] result_data,
    output reg[3:0] uart_state
);

assign uart_data = (~en & data_write) ? data : 8'bz;

// TODO: cp0 ?
// state machine for uart I/O
always @(posedge rst or posedge clk) begin
    if (rst) begin
        uart_state <= 4'b0;
    end
    else begin
        if (en) 
            uart_state <= 4'b0;
        else begin
            if (uart_state < 4'h9)
                uart_state <= uart_state + 4'b1;
        end
    end
end

always @(*) begin
    if (en) begin
        { uart_rdn, uart_wrn } <= 2'b11;
        result_data <= 32'b0;
    end
    else if (address == 32'hBFD003FC) begin
        { uart_rdn, uart_wrn } <= 2'b11;
        result_data <= { 30'b0, uart_dataready, uart_tsre };
    end
    else begin
        if (data_write) begin
            uart_rdn <= 1'b1;
            uart_wrn <= (uart_state >= 4'h4 && uart_state <= 4'h6) ? 1'b0 : 1'b1;
            result_data <= 32'b0;
        end
        else if (data_read) begin
            uart_rdn <= (uart_state >= 4'h4 && uart_state <= 4'h6) ? 1'b0 : 1'b1;
            uart_wrn <= 1'b1;
            result_data <= { 24'b0, uart_data };        
        end
        else begin
            { uart_rdn, uart_wrn }  <= 2'b11;
            result_data <= 32'b0;
        end
    end
end

endmodule