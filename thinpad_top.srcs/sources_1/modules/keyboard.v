module keyboard(
    input wire clk,	//50M时钟信号
    input wire rst_n,	//复位信号
    output reg sl811_a0,
    output reg sl811_wr_n,
    output reg sl811_rd_n,
    output reg sl811_cs_n,
    output reg sl811_rst_n,
    output reg sl811_dack_n,
    inout wire [7:0] data,	// 1byte键�?�，只做�?单的按键扫描
    output reg [7:0] char_data		//键盘当前状�?�，ps2_state=1表示有键被按�?
 );
 
reg[3:0] state;
assign data = sl811_a0 ? 8'hz: 8'h40;
 
initial begin
    sl811_a0 <= 1'b0;
    sl811_wr_n <= 1'b1;
    sl811_rd_n <= 1'b1;
    sl811_cs_n <= 1'b1;
    sl811_dack_n <= 1'b1;
    char_data <= 8'b0;
    state <= 4'b0;
end
 
 always @ (posedge clk) begin
	if (rst_n == 1'b1) begin
	   sl811_a0 <= 1'b1;
       sl811_wr_n <= 1'b1;
       sl811_rd_n <= 1'b1;
       sl811_cs_n <= 1'b1;
       sl811_dack_n <= 1'b1;
	end
	else begin						//锁存状�?�，进行滤波
        case (state)
            4'b0000: begin
                sl811_a0 <= 1'b0;
                sl811_wr_n <= 1'b0;
                sl811_cs_n <= 1'b0;
                state <= 4'h1;
            end
            4'b0001: begin
                sl811_a0 <= 1'b1;
                sl811_wr_n <= 1'b1;
                sl811_cs_n <= 1'b1;
                state <= 4'h2;
            end
            4'b0010: begin
                sl811_cs_n <= 1'b0;
                sl811_rd_n <= 1'b0;
                state <= 4'h3;
            end
            4'b0011: begin
                char_data <= data;
                sl811_cs_n <= 1'b1;
                state <= 4'h0;
            end
        endcase
    end
end

endmodule