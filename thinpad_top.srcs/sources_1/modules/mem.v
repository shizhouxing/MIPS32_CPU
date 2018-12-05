`timescale 1ns / 1ps

module mem(
    input wire clk,
    input wire rst,

    input wire[31:0] address,
    input wire[31:0] ram_read_data,
    input wire[31:0] uart_read_data,
    input wire mem_read,
    input wire mem_write,
    
    // cp0
    input wire cp0_we_in,
    input wire[4:0] cp0_write_addr_in,
    input wire[31:0] cp0_data_in,
    output reg cp0_we_out,
    output reg[4:0] cp0_write_addr_out,
    output reg[31:0] cp0_data_out,
    
    // exception
    input wire[31:0] exception_in,
    input wire[31:0] exception_address_in,
    input wire[31:0] cp0_status_in,
    input wire[31:0] cp0_cause_in,
    input wire[31:0] cp0_epc_in,
    input wire[31:0] wb_cp0_we,
    input wire[31:0] wb_cp0_write_address,
    input wire[31:0] wb_cp0_data,
    output reg[31:0] exception_out,
    output reg[31:0] exception_address_out,
    output wire[31:0] cp0_epc_out,
    output reg reg_write_disable_out,
    
    // delayslot
    input wire this_delayslot_in,
    output reg this_delayslot_out,  

    output reg ram_en,
    output reg uart_en,
    output reg graph_en,
    output reg[31:0] read_data
);

reg[31:0] cp0_status;
reg[31:0] cp0_cause;
reg[31:0] cp0_epc;

assign cp0_epc_out = cp0_epc;

always @(*) begin // status
    if (rst == 1'b1) begin
        cp0_status <= 32'b0;
    end else begin
        if (wb_cp0_we == 1'b1 && wb_cp0_write_address == 5'b01100) begin
            cp0_status <= wb_cp0_data;
        end
        else begin
            cp0_status <= cp0_status_in;
        end
    end
end

always @(*) begin // epc
    if (rst == 1'b1) begin
        cp0_epc <= 32'b0;
    end else begin
        if (wb_cp0_we == 1'b1 && wb_cp0_write_address == 5'b01110) begin
            cp0_epc <= wb_cp0_data;
        end
        else begin
            cp0_epc <= cp0_epc_in;
        end
    end
end

always @(*) begin // cause
    if (rst == 1'b1) begin
        cp0_cause <= 0;
    end else begin
        if (wb_cp0_we == 1'b1 && wb_cp0_write_address == 5'b01101) begin
            cp0_cause[23] <= wb_cp0_data[23];
            cp0_cause[22] <= wb_cp0_data[22];
            cp0_cause[9:8] <= wb_cp0_data[9:8];
        end
        else begin
            cp0_cause <= cp0_cause_in;
        end
    end
end

always @(*) begin
    if (rst == 1'b1) begin
        exception_out <= 32'b0;
        reg_write_disable_out <= 1'b0;
        this_delayslot_out <= 1'b0;
    end else begin
        
        this_delayslot_out <= this_delayslot_in;
        exception_out <= 32'b0;
        reg_write_disable_out <= 1'b0;
        if (exception_address_in != 32'b0) begin
            // interrupt
            if ((cp0_status[15:8] & cp0_cause[15:8]) != 8'b0 && cp0_status[1] == 1'b0 && cp0_cause[0] == 1'b1) begin
                exception_out <= 32'h00000001;
                reg_write_disable_out <= 1'b1;
            end
            else if (exception_in[8] == 1'b1) begin // syscall
                exception_out <= 32'h00000008;
                reg_write_disable_out <= 1'b1;
            end
            else if (exception_in[9] == 1'b1) begin // instruction invalid
                exception_out <= 32'h0000000a;
                reg_write_disable_out <= 1'b1;
            end
            else if (exception_in[10] == 1'b1) begin // trap
                exception_out <= 32'h0000000d;
                reg_write_disable_out <= 1'b1;
            end
            else if (exception_in[11] == 1'b1) begin // overflow
                exception_out <= 32'h0000000c;
                reg_write_disable_out <= 1'b1;
            end
            else if (exception_in[12] == 1'b1) begin // eret
                exception_out <= 32'h0000000e;
                reg_write_disable_out <= 1'b1;
            end
        end
    end
end

always @(*) begin
    if (rst == 1'b1) begin // perhaps RSTs in this file are unnecessary?
        cp0_we_out <= 1'b0;
        cp0_write_addr_out <= 5'b0;
        cp0_data_out <= 32'b0;
        ram_en <= 1'b1;
        uart_en <= 1'b1;
        graph_en <= 1'b1;
        read_data <= 32'b0;
    end else begin
        cp0_we_out <= cp0_we_in;
        cp0_write_addr_out <= cp0_write_addr_in;
        cp0_data_out <= cp0_data_in;
        
        exception_address_out <= exception_address_in;
        
        if (address[31:28] == 4'h9) begin // graphics memory
            { ram_en, uart_en } <= 2'b11;
            if (mem_read | mem_write)
                graph_en <= 1'b0;
        end
        else if (address[31:28] == 4'h8) begin // use ram 
            read_data <= ram_read_data;
            if (mem_read | mem_write) 
                ram_en <= 1'b0;
            else
                ram_en <= 1'b1;
            uart_en <= 1'b1;
            graph_en <= 1'b1;
        end
        else begin // use uart
            // 0xBFD003F8-0xBFD003FD
            ram_en <= 1'b1;
            if (mem_read | mem_write)
                uart_en <= 1'b0;
            else 
                uart_en <= 1'b1;
            read_data <= uart_read_data;
            graph_en <= 1'b1;
        end
    end
end

endmodule
