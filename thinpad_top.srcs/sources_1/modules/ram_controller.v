`timescale 1ns / 1ps

module ram_controller(
    input wire rst,
    input wire clk,

    input wire byte,
    input wire[31:0] inst_addr,
    input wire[31:0] data_addr,
    input wire[31:0] data,
    input wire data_en,
    input wire data_read,
    input wire data_write,
    
    input wire[20:0] flash_data_addr,
    input wire[31:0] flash_data,
    input wire flash_data_en,

    inout wire[31:0] base_ram_data, 
    output reg[19:0] base_ram_addr, 
    output wire[3:0] base_ram_be_n, 
    output wire base_ram_ce_n, 
    output wire base_ram_oe_n, 
    output reg base_ram_we_n, 

    inout wire[31:0] ext_ram_data, 
    output reg[19:0] ext_ram_addr,
    output wire[3:0] ext_ram_be_n,
    output wire ext_ram_ce_n, 
    output wire ext_ram_oe_n, 
    output reg ext_ram_we_n, 

    output wire[31:0] result_inst,
    output reg[31:0] result_data,
    output reg[1:0] ram_state,
    output reg conflict
);

reg[3:0] mask;
reg[31:0] data_extended;
reg base_write, ext_write;
wire[31:0] result_data_raw; // hasn't placed the data at the lowest byte for lb or lbu
assign result_inst = ext_ram_data;
assign result_data_raw = conflict ? ext_ram_data : base_ram_data;
assign ext_ram_ce_n = 1'b0;
assign base_ram_ce_n = data_en;
assign base_ram_oe_n = ~base_write ? 1'b0 : 1'b1;
assign ext_ram_oe_n = ~ext_write ? 1'b0 : 1'b1;
assign base_ram_be_n = base_write ? mask : 4'b0;
assign ext_ram_be_n = ext_write ? mask : 4'b0;
assign base_ram_data = base_write ? data_extended : 32'bz;
assign ext_ram_data = ext_write ? data_extended : 32'bz;

// use 2 clock circles for ram writing
always @(posedge rst or negedge clk) begin
    if (rst) begin
        ram_state <= 2'b0;
    end
    else begin
        if ((~data_en & data_write) | ~flash_data_en) begin
            if (ram_state < 2'b10)
                ram_state <= ram_state + 2'b1;
            else
                ram_state <= 2'b0;
        end
        else
            ram_state <= 2'b0;
    end
end

// ram writing
always @(*) begin
    if (base_write) 
        //base_ram_we_n <= ram_state != 2'b1;
        base_ram_we_n <= clk;
    else 
        base_ram_we_n <= 1'b1;
    if (ext_write)
        //ext_ram_we_n <= ram_state != 2'b1;
        ext_ram_we_n <= clk;
    else
        ext_ram_we_n <= 1'b1;
end


always @(*) begin
    base_ram_addr <= data_addr[21:2];
    if (flash_data_en == 1'b0) begin
        data_extended <= flash_data;
        if (flash_data_addr[20] == 1'b0) begin
            base_write <= 1'b0;
            ext_write <= 1'b1;
            ext_ram_addr <= flash_data_addr[19:0];
            conflict <= 1'b1;
        end
        else if (flash_data_addr[20] == 1'b1) begin
            base_write <= 1'b1;
            ext_write <= 1'b0;
            base_ram_addr <= flash_data_addr[19:0];
            conflict <= 1'b0;
        end
    end else begin
        if (byte) begin // load or store a single byte
            data_extended <= { 4{data[7:0]} };
            case (data_addr[1:0])
                2'b00: begin
                    mask <= 4'b1110;
                    result_data <= {24'b0, result_data_raw[7:0]};
                end
                2'b01: begin
                    mask <= 4'b1101;
                    result_data <= {24'b0, result_data_raw[15:8]};
                end
                2'b10: begin
                    mask <= 4'b1011;
                    result_data <= {24'b0, result_data_raw[23:16]};
                end
                2'b11: begin
                    mask <= 4'b0111;
                    result_data <= {24'b0, result_data_raw[31:24]};
                end
            endcase
        end
        else begin
            mask <= 4'b0;
            data_extended <= data;
            result_data <= result_data_raw;
        end
        
        
        
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
end

endmodule