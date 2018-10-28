`timescale 1ns / 1ps

module fsm_ram(
    input wire clk,
    input wire rst,
    input wire[31:0] inp,
    output wire[15:0] disp,
    output reg[3:0] index,

    input wire[31:0] data_res,
    output wire ce,
    output reg oe,
    output reg we,
    output reg[19:0] address,
    output reg[31:0] data
);

reg state_write_or_read = 1'b0; // 0: write, 1: read
reg state_addr_or_data = 1'b0; // 0: addr, 1: data
reg[31:0] addr_first;

assign ce = 1'b0;
assign disp = { address[7:0], state_write_or_read ? data_res[7:0] : data[7:0] };

always @(posedge clk or posedge rst) 
begin
    if (rst) begin
        state_write_or_read <= 1'b0;
        state_addr_or_data <= 1'b0;
        {oe, we} <= 2'b11;
        index <= 4'h0;
        data <= 32'h00000000;
        address <= 32'h00000000;
    end
    else begin    
        if (~state_write_or_read) begin // write
            oe <= 1'b1;
            if (index == 4'h0) begin
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
                if (index == 4'h9) begin
                    state_write_or_read <= 1'b1;
                    we <= 1'b1;
                    index <= 4'h0;
                end
            end
        end
        else begin // TODO



            // if (index == 4'ha) begin
            
            // end
            // else begin
            //     index <= index + 4'h1;
            // end
        end
    end 
end

endmodule