`timescale 1ns / 1ps

module flash_controller(
    input wire clk,
    input wire rst,
    input wire[22:0] flash_address,
    input wire flag,
    
    // flash
    output reg[22:0] flash_a,
    inout wire[15:0] flash_d,
    output reg flash_rp,
    output reg flash_vpen,
    output reg flash_ce,
    output reg flash_oe,
    output reg flash_we,
    output reg flash_byte,
    
    output reg[15:0] data_out
);

reg[2:0] state;
reg last_flag;

assign flash_d = flash_we ? 16'hz: 16'h00ff;
initial begin
    state <= 3'b0;
    flash_byte <= 1'b1;
    flash_vpen <= 1'b1;
    flash_ce <= 1'b0;
    flash_rp <= 1'b1;
    last_flag <= 1'b1;
end

always @(posedge clk) begin
    if (rst == 1'b1) begin
        flash_oe <= 1'b1;
        flash_we <= 1'b1;
        state <= 3'b0;
    end else begin
        case (state)
            3'b000: begin
                if (flag != last_flag) begin
                    flash_we <= 1'b0;
                    state <= 3'b001;
                    last_flag = flag;
                end
            end
            3'b001: begin
                flash_we <= 1'b1;
                state <= 3'b010;
            end
            3'b010: begin
                flash_oe <= 1'b0;
                flash_a <= flash_address;
                state <= 3'b011;
            end
            3'b011: begin
                data_out <= flash_d;
                state <= 3'b100;
            end
            3'b100: begin
                flash_oe <= 1'b1;
                flash_we <= 1'b1;
                state <= 3'b000;
            end
        endcase
    end
end

endmodule
