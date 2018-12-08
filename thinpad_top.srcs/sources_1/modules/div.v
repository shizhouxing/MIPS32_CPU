module div(
    input wire clk,
    input wire rst,

    input wire is_signed,
    input wire[31:0] A,
    input wire[31:0] B,
    input wire start,
    input wire annul,

    output reg[31:0] result,
    output reg ready
);

reg[1:0] state;
reg[5:0] cnt;
reg[80:0] dividend;
reg[31:0] divisor;

wire[32:0] tmp;
assign tmp = {1'b0, dividend[79:48]} - {1'b0, divisor};

always @ (posedge clk) begin
    if (rst)
        { state, ready, result } <= 35'b0;
    else begin
        case (state)
            2'b00:  begin
                if (start && ~annul) begin
                    if (B == 32'h0)
                        state <= 2'b01; 
                    else begin
                        dividend <= 80'h0;
                        dividend[48:17] <= (is_signed && A[31]) ? (~A + 1) : A;
                        divisor <= (is_signed && B[31]) ? (~B + 1) : B;
                        state <= 2'b10; 
                        cnt <= 6'b0;               
                    end
                end 
                else { ready, result }  <= 33'b0;
            end

            2'b01:  begin
                dividend <= 80'h0;
                state <= 2'b11;
            end

            2'b10:  begin
                if (~annul) begin
                    if (cnt == 6'b110000) begin 
                        if (is_signed) begin
                            if (A[31] ^ B[31])
                                dividend[47:0] <= ~dividend[47:0] + 1;
                            if (A[31] ^ dividend[96])
                                dividend[80:49] <= ~dividend[80:49] + 1;                        
                        end
                        state <= 2'b11;
                        cnt <= 6'b0;
                    end 
                    else begin
                        if (tmp[32])
                            dividend <= {dividend[79:0], 1'b0};
                        else
                            dividend <= {tmp[31:0], dividend[47:0], 1'b1};
                        cnt <= cnt + 1;
                    end
                end
                else state <= 2'b0;
            end

            2'b11:  begin
                result <= {dividend[47], dividend[30:0]};
                ready <= 1'b1;
                if (~start) { state, ready, result } <= 83'b0;
            end
        endcase
    end
end
endmodule
