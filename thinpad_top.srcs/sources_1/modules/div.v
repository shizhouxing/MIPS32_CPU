module div(
    input wire clk,
    input wire rst,

    input wire signed_div_in,
    input wire[31:0] opdata1_in,
    input wire[31:0] opdata2_in,
    input wire start_in,
    input wire annul_in,

    output reg[31:0] result_out,
    output reg ready_out
);

wire[32:0] div_temp;
reg[5:0] cnt;   //记录试商法进行了几轮，当等于48时，表示试商法结�?
reg[80:0] dividend;
reg[1:0] state;

reg[31:0] divisor;
reg[31:0] temp_op1;
reg[31:0] temp_op2;

//dividend的低32位保存的是被除数，中间结果，第k次迭代结束的时�?�dividend[k:0]
//保存的就是当前得到的中间结果，dividend[47:k+1]保存的就是被除数中还没有参与运算
//的数据，dividend�?32位是每次迭代时的被减数，�?以dividend[79:48]==minuend
assign div_temp = {1'b0, dividend[79:48]} - {1'b0, divisor};

always @ (posedge clk) begin
    if (rst == 1'b1) begin
        state <= 2'b00;
        ready_out <= 1'b0;
        result_out <= 32'h00000000;
    end else begin
        case (state)
        //DivFree状�??
        //(1)�?始除法，除数�?0，DivByZero状�??
        //(2)�?始除法，除数不为0，DivOn状�?�，初始化cnt�?0
        //(3)没有�?始除法，DivResultNotReady
        2'b00:  begin   //DivFree状�??
            if (start_in == 1'b1 && annul_in == 1'b0) begin
                if (opdata2_in == 32'h00000000) begin
                    state <= 2'b01;   // DivByZero
                end else begin
                    state <= 2'b10;   // DivOn
                    cnt <= 6'b000000;
                    if (signed_div_in == 1'b1 && opdata1_in[31] == 1'b1) begin
                        temp_op1 = ~opdata1_in + 1; //取补�?
                    end else begin
                        temp_op1 = opdata1_in;
                    end
                    if (signed_div_in == 1'b1 && opdata2_in[31] == 1'b1) begin
                        temp_op2 = ~opdata2_in + 1; //取补�?
                    end else begin
                        temp_op2 = opdata2_in;
                    end
                    dividend <= {32'h00000000, 32'h00000000, 16'h0000};
                    dividend[48:17] <= temp_op1;
                    divisor <= temp_op2;
                end
            end else begin //没有�?始除法运�?
                ready_out <= 1'b0;
                result_out <= 32'h00000000;
            end
        end

        //DivByZero
        //直接进入DivEnd状�?�，除法结束，结果为0
        2'b01:  begin
            dividend <= {32'h00000000, 32'h00000000, 16'h0000};
            state <= 2'b11;
        end

        //DivOn
        //(1)输入信号annul_i�?1，表示处理器取消除法运算�?===》DivFree
        //(2)输入信号annul_i�?0，且cnt不为48，试商法未结束，判断减法结果div_temp
        //(3)输入信号annul_i�?0，且cnt�?48，那么表示试商法结束�?===》DivEnd
        2'b10:  begin
            if (annul_in == 1'b0) begin
                if (cnt != 6'b110000) begin //试商法未结束
                    if (div_temp[32] == 1'b1) begin
                        // (minuend - n) < 0
                        dividend <= {dividend[79:0], 1'b0};
                    end else begin
                        // (minuend - n) >= 0
                        dividend <= {div_temp[31:0], dividend[47:0], 1'b1};
                    end
                    cnt <= cnt + 1;
                end else begin //试商法结�?
                    if ((signed_div_in == 1'b1) &&
                    ((opdata1_in[31] ^ opdata2_in[31]) == 1'b1)) begin
                        dividend[47:0] <= (~dividend[47:0] + 1);
                    end
                    if ((signed_div_in == 1'b1) &&
                        ((opdata1_in[31] ^ dividend[96]) == 1'b1)) begin
                            dividend[80:49] <= (~dividend[80:49] + 1);
                    end
                    state <= 2'b11;
                    cnt <= 6'b000000;
                end
            end else begin
                state <= 2'b00;
            end
        end

        //DivEnd
        2'b11:  begin
            result_out <= {dividend[47],dividend[30:0]};
            ready_out <= 1'b1;
            if (start_in == 1'b0) begin
                state <= 2'b00;
                ready_out <= 1'b0;
                result_out <= {32'h00000000, 32'h00000000, 16'h0000};
            end
        end
        endcase
    end
end
endmodule
