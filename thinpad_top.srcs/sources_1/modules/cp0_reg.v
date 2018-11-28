/*
    Count寄存�?(9)     32�? 当计数到�?32位无符号数上限时归零 可读可写
    Compare寄存�?(11)  32�? 定时中断 当和count寄存器中的�?�相同时产生定时中断 可读可写
    Status寄存�?(12)   32�? 可读可写
        31-28 CU3-CU0   表示相应的协处理器是否可�? 默认4'b0001
        15-8  IM7-IM0   表示是否屏蔽中断�?0表示屏蔽
        1     EXL       表示是否处于异常级，表示是否处于异常级，如果异常则为1，进入kernal，禁止中�?
        0     IE        表示是否使能中断�? 1表示中断使能
    Cause寄存�?(13)    32�? 记录�?近一次异常发生的原因 可读可写
        31      BD      当发生异常的指令处于分支延迟槽，置为1
        15-10   IP[7-2] 中断挂起字段，表示相应的外部硬件是否发生中断�?1表示发生中断，[7-2] 对应 [5-0]硬件
        9-8     IP[1-0] 中断挂起字段，表示软件中断，1表示发生中断，[1-0]对应[1-0]软件
        6-2     ExcCode
            0   Int     中断
            8   Sys     系统调用指令Syscall
            10  RI      执行未定义指令引起的异常
            12  Ov      整数溢出异常
            13  Tr      自陷指令引起的异�?
    EPC寄存�?(14)      32�? 保存上一次异常时的程序计数器，如果发生异常的指令在延迟槽中，保存的是前一条转移指令的地址
    PRId寄存�?(15)     32�? 处理器标志和版本 不需要？
    Config寄存�?(16)   32�? 配置寄存器，用于设置CPU的参�? 不需�??
        15      BE      1表示大端序，0表示小端�?
*/

`timescale 1ns / 1ps
`include "constants.v"

module cp0_reg(
    input wire clk, // 时钟信号
    input wire rst, // 复位信号

    input wire w_in, // 是否写，1表示�?
    input wire[4:0] waddr_in, // 写入CP0寄存器的地址
    input wire[4:0] raddr_in, // 读取CP0寄存器的地址
    input wire[31:0] data_in, // 写入的数�?
    input wire[6:0] inter_in, // 6个外部硬件中�?

    output reg[31:0] data_out, // 读取的数�?
    output reg[31:0] count_out, // Count寄存器的�?
    output reg[31:0] compare_out, // Compare寄存器的�?
    output reg[31:0] status_out, // Status寄存器的�?
    output reg[31:0] cause_out, // Cause寄存器的�?
    output reg[31:0] epc_out, // EPC寄存器的�?
    
    // exception
    input wire[31:0] exception_in,
    input wire[31:0] exception_address_in,
    
    // delayslot
    input wire this_delayslot_in,

    output reg timer_inter_out // 是否有定时中�?
);


always @ (posedge clk) begin
    if (rst == 1'b1) begin
        count_out <= 32'b0;
        compare_out <= 32'b0;
        status_out <= 32'h10000000;
        cause_out <= 32'b0;
        epc_out <= 32'b0;
        timer_inter_out <= 1'b0;
    end
    else begin
        // 产生定时中断
        count_out <= count_out + 1;
        if (compare_out != 32'b0 && count_out == compare_out) begin
            timer_inter_out <= 1'b1;
        end

        // 保存外部硬件中断
        cause_out[15:10] <= inter_in;
        
        // 写入寄存�?
        if (w_in == 1'b1) begin
            case (waddr_in)
                5'b01001: begin // Count
                    count_out <= data_in;
                end
                5'b01011: begin // Compare
                    compare_out <= data_in;
                    timer_inter_out <= 1'b0;
                end
                5'b01100: begin // Status
                    status_out <= data_in;
                end
                5'b01101: begin // Cause
                    cause_out[22] <= data_in[22];
                    cause_out[23] <= data_in[23];
                    cause_out[9:8] <= data_in[9:8];
                end
                5'b01110: begin // Epc
                    epc_out <= data_in;
                end
                default: begin
                end
            endcase
        end
        
        if (exception_in != 32'h0 && exception_in != 32'h0000000e) begin
            if (this_delayslot_in == 1'b1) begin
                epc_out <= exception_address_in - 4;
                cause_out[31] <= 1'b1;
            end else begin
                epc_out <= exception_address_in;
                cause_out[31] <= 1'b0;
            end
        end
        
        case (exception_in)
            32'h00000001: begin // interrupt
                status_out[1] <= 1'b1;
                cause_out[6:2] <= 5'b00000;
            end
            32'h00000008: begin // syscall
                status_out[1] <= 1'b1;
                cause_out[6:2] <= 5'b01000;
            end
            32'h0000000a: begin // instruction invalid
                status_out[1] <= 1'b1;
                cause_out[6:2] <= 5'b01010;
            end
            32'h0000000d: begin // trap
                status_out[1] <= 1'b1;
                cause_out[6:2] <= 5'b01101;
            end
            32'h0000000c: begin // overflow
                status_out[1] <= 1'b1;
                cause_out[6:2] <= 5'b01100;
            end
            32'h0000000e: begin
                status_out[1] <= 1'b0;
            end
        endcase
    end
end

always @ (*) begin
    if (rst) begin
        data_out <= 32'b0; 
    end
    else begin
        // 读取寄存�?
        case (raddr_in)
            5'b01001: begin // Count
                data_out <= count_out;
            end
            5'b01011: begin // Compare
                data_out <= compare_out;
            end
            5'b01100: begin // Status
                data_out <= status_out;
            end
            5'b01101: begin // Cause
                data_out <= cause_out;
            end
            5'b01110: begin // Epc
                data_out <= epc_out;
            end
            default: begin
                data_out <= 32'h0;
            end
        endcase
    end
end

endmodule
