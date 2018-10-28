`timescale 1ns / 1ps

module ram_controller(
    input wire clk, 
    input wire rst,
    input wire ce,
    input wire oe,
    input wire we,
    input wire[19:0] address,
    input wire[31:0] data_in,
    
    output reg[31:0] data_out,

    //output reg write_ack,
    //output reg ram_busy,

    inout wire[31:0] base_ram_data_wire,
    output reg[19:0] base_ram_addr,
    output wire[3:0] base_ram_be_n,
    output wire base_ram_ce_n,
    output reg base_ram_oe_n,
    output reg base_ram_we_n,

    inout wire[31:0] ext_ram_data_wire,
    output reg[19:0] ext_ram_addr,
    output wire[3:0] ext_ram_be_n,
    output wire ext_ram_ce_n,
    output reg ext_ram_oe_n,
    output reg ext_ram_we_n
);

assign base_ram_be_n = 4'h0;
assign ext_ram_be_n = 4'h0;
//assign ram_busy <= 1'b1; // TODO: add enable for the ram controller
assign { base_ram_ce_n, ext_ram_ce_n } = ce ? 2'b10 : 2'b01;

reg data_z;
reg[31:0] base_ram_data, ext_ram_data;
assign base_ram_data_wire = data_z ? 32'bz : base_ram_data;
assign ext_ram_data_wire = data_z ? 32'bz : ext_ram_data;

localparam STATE_IDLE = 3'b000;
localparam STATE_READ_0 = 3'b001;
localparam STATE_READ_1 = 3'b010;
localparam STATE_WRITE_0 = 3'b011;
localparam STATE_WRITE_1 = 3'b100;

reg[2:0] state = STATE_IDLE;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= STATE_IDLE;
        { base_ram_we_n, ext_ram_we_n } <= 2'b11;
        { base_ram_oe_n, ext_ram_oe_n } <= 2'b11;
        base_ram_addr <= 20'h00000;
        ext_ram_addr <= 20'h00000;
        data_out <= 32'h00000000;
        data_z <= 1'b0;
    end
    else begin
        case (state)
            STATE_IDLE: begin
                if (~we || ~oe) begin
                    base_ram_addr <= address;
                    ext_ram_addr <= address;
                end
                if (~we) begin 
                    state <= STATE_WRITE_0;
                    base_ram_data <= data_in;
                    ext_ram_data <= data_in;
                    data_z <= 1'b0;
                end
                else if (~oe) begin
                    state <= STATE_READ_0;
                    data_z <= 1'b1;
                end
            end
            STATE_READ_0: begin
                state <= STATE_READ_1;
                { base_ram_oe_n, ext_ram_oe_n } = 2'b00;
            end
            STATE_READ_1: begin
                if (oe) begin
                    state <= STATE_IDLE;
                    { base_ram_oe_n, ext_ram_oe_n } = 2'b11;
                end
                else begin
                    data_out <= ce ? ext_ram_data_wire : base_ram_data_wire;
                    base_ram_addr <= address;
                    ext_ram_addr <= address;
                end
            end
            STATE_WRITE_0: begin
                state <= STATE_WRITE_1;
                { base_ram_we_n, ext_ram_we_n } <= 2'b00;
            end
            STATE_WRITE_1: begin
                state <= STATE_IDLE;
                { base_ram_we_n, ext_ram_we_n } <= 2'b11;
            end
        endcase
    end
end

endmodule