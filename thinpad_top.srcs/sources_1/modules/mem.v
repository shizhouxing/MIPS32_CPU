`timescale 1ns / 1ps

module mem(
    input wire clk,
    input wire[31:0] address,
    input wire[31:0] ram_read_data,
    input wire mem_read,
    input wire mem_write,

    output reg ram_en,
    output reg[31:0] read_data
);

always @(*) begin
    if (address[31:28] == 4'h8) begin
        read_data <= ram_read_data;
        if (mem_read | mem_write) 
            ram_en <= 1'b0;
        else
            ram_en <= 1'b1;
    end
    else begin // TODO: uart, .etc
        // 0xBFD003F8-0xBFD003FD
    end
end

endmodule
