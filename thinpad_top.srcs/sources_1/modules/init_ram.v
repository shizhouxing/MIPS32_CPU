`timescale 1ns / 1ps

module init_ram(
    input wire clk,
    input wire rst,
    
    
    // ram controller
    output reg[31:0] flash_data_out,
    output reg[19:0] flash_data_address_out,
    output reg flash_data_en,
    
    // flash controller
    input wire[15:0] flash_data_in,
    output reg[22:0] flash_address,
    output reg flash_flag,
    output reg[31:0] ram_data_addr,
    output reg ram_byte,
    output reg[31:0] ram_data,
    output reg ram_data_en,
    output reg ram_data_read,
    output reg ram_data_write,
    
    // stall
    output reg flash_stall
);

reg[2:0] counter;
reg updown;

initial begin
    flash_stall <= 1'b0;
    flash_address <= 23'b0;
    flash_flag <= 1'b0;
    counter <= 3'b0;
    updown <= 1'b0;
    
    flash_data_out <= 32'b0;
    flash_data_en <= 1'b1;
end

always @(posedge clk) begin
    if (rst) begin
        flash_stall <= 1'b0;
        counter <= 3'b0;
        flash_data_out <= 32'b0;
        flash_data_en <= 1'b1;
    end
    else begin
        if (flash_stall == 1'b1) begin
            
            if (counter == 3'b111) begin // get flash output
            
                if (updown == 1'b0) begin
                    flash_data_en <= 1'b1;
                    flash_data_address_out <= flash_address[21:2];
                    flash_data_out[15:0] <= flash_data_in;
                    updown <= 1'b1;
                end
                else begin
                    flash_data_en <= 1'b0;
                    flash_data_out[31:16] <= flash_data_in;
                    updown <= 1'b0;
                end
                flash_flag <= ~flash_flag;
                flash_address <= flash_address + 2;
                counter <= 3'b0;
            end
            else begin
                flash_data_en <= 1'b1;
                counter = counter + 1;
                if (counter == 3'b010 && flash_address == 23'h40) begin
                    flash_stall <= 1'b0;
                end
            end
        end
    end
end

endmodule
