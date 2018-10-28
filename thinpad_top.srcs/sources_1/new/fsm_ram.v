`timescale 1ns / 1ps

module fsm_ram(
    input wire clk,
    input wire rst,
    input wire[31:0] inp,
    output wire[15:0] disp,
    output reg[3:0] index,
    output reg[1:0] state,

    input wire[31:0] data_res,
    output reg ce,
    output reg oe,
    output reg we,
    output reg[19:0] address,
    output reg[31:0] data
);

localparam STATE_WRITE_1 = 2'b00;
localparam STATE_READ_1 = 2'b01;
localparam STATE_WRITE_2 = 2'b10;
localparam STATE_READ_2 = 2'b11;

wire state_write_or_read;
reg state_addr_or_data = 1'b0; // 0: addr, 1: data
reg[31:0] addr_first;
reg[31:0] data_arr[0:10];

assign state_write_or_read = (state == STATE_READ_1 || state == STATE_READ_2) ? 1'b1 : 1'b0;
assign disp = { 
    address[7:0], 
    state_write_or_read ? ((index == 4'h0) ? 8'h00 : data_res[7:0]) : data[7:0] 
};

always @(posedge clk or posedge rst) 
begin
    if (rst) begin
        state <= STATE_WRITE_1;
        state_addr_or_data <= 1'b0;
        {oe, we} <= 2'b11;
        ce <= 1'b0;
        index <= 4'h0;
        data <= 32'h00000000;
        address <= 32'h00000000;
    end
    else begin    
        case (state)
            STATE_WRITE_1: begin
                if (index == 4'ha) begin
                    state = STATE_READ_1;
                    index <= 4'h0;                    
                    we <= 1'b1;
                end
                else if (index == 4'h0) begin
                    if (~state_addr_or_data) begin
                        addr_first <= inp;
                        address <= inp;
                        state_addr_or_data <= 1'b1;
                    end
                    else begin
                        data <= inp;
                        index <= index + 4'h1;
                        we <= 1'b0;
                    end
                end
                else begin
                    data <= data + 4'h1;
                    address <= address + 1;
                    index <= index + 4'h1;
                end
            end
            STATE_READ_1: begin
                oe <= 1'b0;
                if (index != 4'h0) 
                    data_arr[index] <= data_res;
                if (index == 4'ha) begin // finished reading
                    state <= STATE_WRITE_2;
                    index <= 4'h0;
                    oe <= 1'b1;
                    data <= 32'h00000000;
                    ce <= 1'b1;
                end
                else begin
                    if (index == 4'h0)
                        address <= addr_first;
                    else
                        address <= address + 4'h1;
                    index <= index + 4'h1;
                end
            end
            STATE_WRITE_2: begin
                if (index == 4'ha) begin
                    state <= STATE_READ_2;
                    index <= 4'h0;
                    we <= 1'b1;
                end 
                else begin
                    if (index == 4'h0) begin
                        address <= addr_first;
                        we <= 1'b0;
                    end
                    else begin
                        address <= address + 4'h1;
                    end
                    data <= data_arr[index + 4'h1] - 1'b1;
                    index <= index + 4'h1;   
                end
            end
            STATE_READ_2: begin
                oe <= 1'b0;
                if (index == 4'ha) begin // finished reading
                    
                end
                else begin
                    if (index == 4'h0)
                        address <= addr_first;
                    else
                        address <= address + 4'h1;
                    index <= index + 4'h1;
                end
            end
        endcase
    end 
end

endmodule