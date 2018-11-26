`timescale 1ns / 1ps

module mem(
    input wire[31:0] address,
    input wire[31:0] ram_read_data,
    input wire[31:0] uart_read_data,
    input wire mem_read,
    input wire mem_write,
    
    input wire cp0_we_in,
    input wire[4:0] cp0_write_addr_in,
    input wire[31:0] cp0_data_in,
    
    output reg cp0_we_out,
    output reg[4:0] cp0_write_addr_out,
    output reg[31:0] cp0_data_out,

    output reg ram_en,
    output reg uart_en,
    output reg[31:0] read_data
);

always @(*) begin
    cp0_we_out <= cp0_we_in;
    cp0_write_addr_out <= cp0_write_addr_in;
    cp0_data_out <= cp0_data_in;
    if (address[31:28] == 4'h8) begin
        read_data <= ram_read_data;
        if (mem_read | mem_write) 
            ram_en <= 1'b0;
        else
            ram_en <= 1'b1;
        uart_en <= 1'b1;
    end
    else begin 
        // uart 
        // 0xBFD003F8-0xBFD003FD
        ram_en <= 1'b1;
        uart_en <= 1'b0;
        read_data <= uart_read_data;
    end
end

endmodule
