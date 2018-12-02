`timescale 1ns / 1ps

module init_ram(
    input wire clk,
    input wire rst,
    
    output reg[22:0] flash_address,
    output reg flash_flag,
    input wire[15:0] flash_data,
    
    output reg[31:0] ram_inst_addr,
    output reg[31:0] ram_data_addr,
    output reg ram_byte,
    output reg[31:0] ram_data,
    output reg ram_data_en,
    output reg ram_data_read,
    output reg ram_data_write,
    
    output reg complete
);

reg[2:0] counter;

initial begin
    complete <= 1'b0;
    flash_address <= 23'b0;
    flash_flag <= 1'b0;
    counter <= 26'b0;
end

always @(posedge clk) begin
    if (rst) begin
        complete <= 1'b0;
        counter <= 3'b0;
    end
    else begin
        if (complete == 1'b0) begin
            if (counter == 3'b111) begin // get flash output
                if (flash_address == 23'h8) begin
                    complete <= 1'b1;
                end
                flash_flag <= ~flash_flag;
                flash_address <= flash_address + 2;
            end
            else begin
                counter = counter + 1;
            end
        end
    end
end

endmodule
