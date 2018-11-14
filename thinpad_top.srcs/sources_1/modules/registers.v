`timescale 1ns / 1ps

module registers(
    input wire clk, 
    input wire rst,
    input wire[4:0] read_address_1,
    input wire[4:0] read_address_2,
    input wire[4:0] write_address,
    input wire[31:0] write_data,

    input wire con_reg_write,

    output reg[31:0] read_data_1,
    output reg[31:0] read_data_2
);

integer i;
reg[31:0] r[0:31];

always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (i = 0; i < 32; i = i + 1)
            r[i] <= 32'b0;
    end
    else begin
        r[0] <= 32'h0;
        read_data_1 <= (con_reg_write && (read_address_1 == write_address)) ? 
            write_data : r[read_address_1];
        read_data_2 <= (con_reg_write && (read_address_2 == write_address)) ? 
            write_data : r[read_address_2];
        if (con_reg_write && write_address != 5'b00000)
            r[write_address] <= write_data;    
    end
end

endmodule