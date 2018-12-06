`timescale 1ns / 1ps
//
// WIDTH: bits in register hdata & vdata
// HSIZE: horizontal size of visible field 
// HFP: horizontal front of pulse
// HSP: horizontal stop of pulse
// HMAX: horizontal max size of value
// VSIZE: vertical size of visible field 
// VFP: vertical front of pulse
// VSP: vertical stop of pulse
// VMAX: vertical max size of value
// HSPP: horizontal synchro pulse polarity (0 - negative, 1 - positive)
// VSPP: vertical synchro pulse polarity (0 - negative, 1 - positive)
//
module vga
#(parameter WIDTH = 0, HSIZE = 0, HFP = 0, HSP = 0, HMAX = 0, VSIZE = 0, VFP = 0, VSP = 0, VMAX = 0, HSPP = 0, VSPP = 0)
(
    input wire clk,
    input wire rst,
    
    input wire vga_we_in,
    input wire[11:0] vga_address_in,
    input wire[6:0] vga_data_in,

    
    output wire hsync,
    output wire vsync,
    output reg [WIDTH - 1:0] hdata,
    output reg [WIDTH - 1:0] vdata,
    output wire [6:0] letter,
    output wire [2:0] letter_h,
    output wire [3:0] letter_v,
    output wire data_enable
);

reg[6:0] screen[0:1499];
reg[3:0] hcount;
reg[4:0] vcount;
reg [11:0] pos;

assign letter_h = hcount[3:1];
assign letter_v = vcount[4:1];
assign letter = screen[pos];
integer i;

// init
initial begin
    for (i = 0; i < 1500; i = i + 1)
        screen[i] <= 7'b0;
    hdata <= 0;
    vdata <= 0;
    hcount <= 0;
    vcount <= 0;
    pos <= 0;
end

// write
always @ (posedge rst or posedge clk)
begin
    if (rst == 1'b1) begin
        // debug
        //for (i = 0; i < 1500; i = i + 1)
        //    screen[i] <= 7'b0;
    end else begin
        if (vga_data_in >= 8'h20 && ~vga_we_in) begin
            screen[vga_address_in] <= vga_data_in - 8'h20;
        end
    end
end

// pos
always @ (posedge clk)
begin
    if (hdata == (HMAX - 1)) begin
        if (vdata == (VMAX - 1)) begin
            pos <= 0;
        end
        else begin
            if (vcount == 5'b11111) begin
                pos <= pos + 1;
            end
            else begin
                pos <= pos - 64;
            end
        end
    end else begin
        if (hcount == 4'b1111) begin
            pos <= pos + 1;
        end
    end
end

// hdata
always @ (posedge clk)
begin
    if (hdata == (HMAX - 1)) begin
        hdata <= 0;
        hcount <= 0;
    end
    else begin
        hdata <= hdata + 1;
        if (hcount == 4'b1111) begin
            hcount <= 4'b0;
        end
        else begin
            hcount <= hcount + 1;
        end
    end
end

// vdata
always @ (posedge clk)
begin
    if (hdata == (HMAX - 1)) 
    begin
        if (vdata == (VMAX - 1)) begin
            vdata <= 0;
            vcount <= 0;
        end
        else begin
            vdata <= vdata + 1;
            if (vcount == 5'b11111) begin
                vcount <= 5'b0;
            end
            else begin
                vcount <= vcount + 1;
            end
        end
    end
end

// hsync & vsync & blank
assign hsync = ((hdata >= HFP) && (hdata < HSP)) ? HSPP : !HSPP;
assign vsync = ((vdata >= VFP) && (vdata < VSP)) ? VSPP : !VSPP;
assign data_enable = ((hdata < HSIZE) & (vdata < VSIZE));

endmodule