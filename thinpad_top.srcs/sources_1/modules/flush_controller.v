`timescale 1ns / 1ps

module flush_controller(
    input wire rst,
    
    input wire[31:0] exception_in,
    input wire[31:0] cp0_epc_in,
    
    output reg flush,
    output reg[31:0] pc_flush
);

always @(*) begin
    if (rst == 1'b1) begin
        flush <= 1'b0;
        pc_flush <= 32'b0;
    end else begin
        if (exception_in != 32'b0) begin
            flush <= 1'b1;
            case (exception_in)
                32'h00000001: begin // interrupt
                    pc_flush <= 32'h80001180;
                end
                32'h00000008: begin // syscall
                    pc_flush <= 32'h80001180;
                end
                32'h0000000a: begin // instruction invalid
                    flush <= 1'b0;
                    //pc_flush <= 32'h00000040;
                end
                32'h0000000d: begin // trap
                    pc_flush <= 32'h80001180;
                end
                32'h0000000c: begin // overflow
                    pc_flush <= 32'h80001180;
                end
                32'h0000000e: begin // eret
                    pc_flush <= cp0_epc_in;
                end
            endcase
        end else begin
            flush <= 1'b0;
            pc_flush <= 32'b0;
        end
    end
end

endmodule
