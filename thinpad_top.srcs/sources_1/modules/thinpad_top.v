`default_nettype wire

module thinpad_top(
    input wire clk_50M,           //50MHz 时钟输入
    input wire clk_11M0592,       //11.0592MHz 时钟输入

    input wire clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到“ON”时为1
    output wire[15:0] leds,       //16位LED，输出时1点亮
    output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮

    //CPLD串口控制器信号
    output wire uart_rdn,         //读串口信号，低有效
    output wire uart_wrn,         //写串口信号，低有效
    input wire uart_dataready,    //串口数据准备好
    input wire uart_tbre,         //发送数据标志
    input wire uart_tsre,         //数据发送完毕标志

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效

    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端

    //Flash存储器信号，参考 JS28F640 芯片手册
    output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
    inout  wire [15:0]flash_d,      //Flash数据
    output wire flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧写
    output wire flash_ce_n,         //Flash片选信号，低有效
    output wire flash_oe_n,         //Flash读使能信号，低有效
    output wire flash_we_n,         //Flash写使能信号，低有效
    output wire flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

    //USB 控制器信号，参考 SL811 芯片手册
    output wire sl811_a0,
    //inout  wire[7:0] sl811_d,     //USB数据线与网络控制器的dm9k_sd[7:0]共享
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    //网络控制器信号，参考 DM9000A 芯片手册
    output wire dm9k_cmd,
    inout  wire[15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input  wire dm9k_int,

    //图像输出信号
    output wire[2:0] video_red,    //红色像素，3位
    output wire[2:0] video_green,  //绿色像素，3位
    output wire[1:0] video_blue,   //蓝色像素，2位
    output wire video_hsync,       //行同步（水平同步）信号
    output wire video_vsync,       //场同步（垂直同步）信号
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐区
);

// main clock
wire clock;
assign clock = clock_btn;
// reset
wire reset;
assign reset = reset_btn;

wire[31:0] pc_current;
wire stall_pc; // un
wire[31:0] pc_plus_4_if;
wire[31:0] inst_if;
wire con_pc_jump;
wire[31:0] pc_jump;

// TODO
assign stall_pc = 1'b0;

pc _pc(
    .clk(clock),
    .rst(reset),
    .stall(stall_pc),
    .inst(inst_if),  
    .pc_jump(pc_jump),
    .con_pc_jump(con_pc_jump),  
    .pc_plus_4(pc_plus_4_if),
    .pc_current(pc_current)
);

inst_mem _inst_mem(
    .address(pc_current),
    .data(inst_if),
    .ram_data(ext_ram_data),
    .ram_addr(ext_ram_addr),
    .ram_be_n(ext_ram_be_n),
    .ram_ce_n(ext_ram_ce_n),
    .ram_oe_n(ext_ram_oe_n),
    .ram_we_n(ext_ram_we_n)
);

wire[31:0] inst_id, pc_plus_4_id;
if_id _if_id(
    .clk(clock),
    .rst(reset),
    .stall(1'b0), // TODO
    .inst_in(inst_if),
    .pc_plus_4_in(pc_plus_4_if),
    .inst_out(inst_id),
    .pc_plus_4_out(pc_plus_4_id)
);

wire con_reg_write;
wire[4:0] reg_write_address;
wire[31:0] reg_write_data;
wire[31:0] reg_read_data_1, reg_read_data_2;
wire[31:0] result;
registers _registers(
    .clk(clock),
    .rst(reset),
    .read_address_1(inst_id[25:21]),
    .read_address_2(inst_id[20:16]),
    .write_address(reg_write_address),
    .write_data(reg_write_data),
    .con_reg_write(con_reg_write),
    .read_data_1(reg_read_data_1),
    .read_data_2(reg_read_data_2),
    .result(result) // for debug
);
assign leds = result[15:0];

jump_control _jump_control(
    .inst(inst_id),
    .pc_plus_4(pc_plus_4_id),
    .data_a(reg_read_data_1),
    .data_b(reg_read_data_2),
    .con_pc_jump(con_pc_jump),
    .pc_jump(pc_jump)
);

// id
wire con_alu_immediate, con_alu_signed, con_alu_sa;
wire con_jal;

// exe
wire[3:0] con_alu_op_id;
wire[3:0] con_alu_op;
wire con_reg_write_id, con_mov_cond_id;
wire con_reg_write_exe, con_mov_cond;

// mem
wire con_mem_write_id, con_mem_write_exe, con_mem_write;
wire con_mem_signed_extend_id, con_mem_signed_extend_exe, con_mem_signed_extend;
wire[3:0] con_mem_mask_id, con_mem_mask_exe, con_mem_mask;
wire[1:0] con_wb_src, con_wb_src_id, con_wb_src_exe;

control _control(
    .inst(inst_id),

    .con_alu_immediate(con_alu_immediate),
    .con_alu_signed(con_alu_signed),
    .con_alu_sa(con_alu_sa),
    .con_jal(con_jal),

    .con_alu_op(con_alu_op_id),
    .con_reg_write(con_reg_write_id),
    .con_mov_cond(con_mov_cond_id),

    .con_mem_mask(con_mem_mask_id),
    .con_mem_write(con_mem_write_id),
    .con_mem_signed_extend(con_mem_signed_extend_id),
    .con_wb_src(con_wb_src_id)
);

wire[31:0] alu_a, alu_b;
wire[4:0] reg_write_address_exe;
wire[31:0] mem_write_data_exe;
wire[31:0] pc_plus_8_exe;
id_exe _id_exe(
    .clk(clock),
    .rst(reset),
    .data_1(reg_read_data_1),
    .data_2(reg_read_data_2),
    .inst_in(inst_id),
    .pc_plus_4(pc_plus_4_id),

    .con_alu_immediate(con_alu_immediate),
    .con_alu_signed(con_alu_signed),
    .con_alu_sa(con_alu_sa),
    .con_jal(con_jal),
    
    .con_alu_op_in(con_alu_op_id),
    .con_reg_write_in(con_reg_write_id),
    .con_mov_cond_in(con_mov_cond_id),   
    .con_alu_op_out(con_alu_op),    
    .con_reg_write_out(con_reg_write_exe),
    .con_mov_cond_out(con_mov_cond),     

    .con_mem_mask_in(con_mem_mask_id),
    .con_mem_write_in(con_mem_write_id),
    .con_mem_signed_extend_in(con_mem_signed_extend_id),
    .con_mem_mask_out(con_mem_mask_exe),
    .con_mem_write_out(con_mem_write_exe),
    .con_mem_signed_extend_out(con_mem_signed_extend_exe),

    .con_wb_src_in(con_wb_src_id),
    .con_wb_src_out(con_wb_src_exe),
    
    .data_A(alu_a),
    .data_B(alu_b),
    .reg_write_address(reg_write_address_exe),
    .mem_write_data(mem_write_data_exe),
    .pc_plus_8(pc_plus_8_exe)
);

wire[31:0] alu_res;
wire alu_z;
wire alu_s, alu_c, alu_v; // unused
alu _alu(
    .op(con_alu_op),
    .A(alu_a),
    .B(alu_b),
    .res(alu_res),
    .S(alu_s),
    .Z(alu_z),
    .C(alu_c),
    .V(alu_v)
);

wire[31:0] pc_plus_8_mem;
wire[31:0] mem_address;
wire[31:0] mem_write_data;

wire[4:0] reg_write_address_mem;
wire[31:0] reg_write_data_mem;
wire con_reg_write_mem;
wire[31:0] alu_res_mem, mov_data_mem;

exe_mem _exe_mem(
    .clk(clock),
    .rst(reset),
    .alu_z(alu_z),
    .alu_res(alu_res),
    .pc_plus_8_in(pc_plus_8_exe),
    .reg_write_address_in(reg_write_address_exe),
    .mem_write_data_in(mem_write_data_exe),
    .data_A(alu_a),

    .con_reg_write(con_reg_write_exe),
    .con_mov_cond(con_mov_cond),

    .con_mem_mask_in(con_mem_mask_exe),
    .con_mem_write_in(con_mem_write_exe),
    .con_mem_signed_extend_in(con_mem_signed_extend_exe),
    .con_mem_mask_out(con_mem_mask),
    .con_mem_write_out(con_mem_write),
    .con_mem_signed_extend_out(con_mem_signed_extend),
    .con_wb_src_in(con_wb_src_exe),
    .con_wb_src_out(con_wb_src),

    .pc_plus_8_out(pc_plus_8_mem),
    .mem_address(mem_address),
    .reg_write_address(reg_write_address_mem),
    .mem_write_data(mem_write_data),
    .reg_write(con_reg_write_mem),
    .alu_res_out(alu_res_mem),
    .mov_data(mov_data_mem)
);

wire[31:0] mem_read_data;
data_mem _data_mem(
    .clk(clock),
    .mask(con_mem_mask),
    .write(con_mem_write),
    .address(mem_address),
    .data_in(mem_write_data),
    .data_out(mem_read_data),
    
    .ram_data(base_ram_data),
    .ram_addr(base_ram_addr),
    .ram_be_n(base_ram_be_n),
    .ram_ce_n(base_ram_ce_n),
    .ram_oe_n(base_ram_oe_n),
    .ram_we_n(base_ram_we_n)
);

mem_wb _mem_wb(
    .clk(clock),
    .rst(reset),
    .reg_write_in(con_reg_write_mem),
    .reg_write_address_in(reg_write_address_mem),
    .pc_plus_8(pc_plus_8_mem),
    .mov_data(mov_data_mem),
    .mem_read_data(mem_read_data),
    .alu_res(alu_res_mem),
    .con_wb_src(con_wb_src),
    .con_mem_signed_extend(con_mem_signed_extend),
    .reg_write_out(con_reg_write),
    .reg_write_address_out(reg_write_address),
    .reg_write_data(reg_write_data)
);

// ********************************************************
// test 


// data_mem_test _data_mem_test(
//     .clk(clock_btn),
//     .dip_sw(dip_sw),
//     .leds(leds),
//     .base_ram_data(base_ram_data),  
//     .base_ram_addr(base_ram_addr), 
//     .base_ram_be_n(base_ram_be_n),  
//     .base_ram_ce_n(base_ram_ce_n),       
//     .base_ram_oe_n(base_ram_oe_n),       
//     .base_ram_we_n(base_ram_we_n)         
// );

// inst_mem_test _inst_mem_test(
//     .dip_sw(dip_sw),
//     .leds(leds),
//     .base_ram_data(base_ram_data),  
//     .base_ram_addr(base_ram_addr), 
//     .base_ram_be_n(base_ram_be_n),  
//     .base_ram_ce_n(base_ram_ce_n),       
//     .base_ram_oe_n(base_ram_oe_n),       
//     .base_ram_we_n(base_ram_we_n)      
// );

//pc _pc();

// ********************************************************
// Project III

// reg[15:0] disp;
// reg ce_ram, oe_ram, we_ram;
// reg oe_uart, we_uart;
// reg[7:0] data_uart_in;
// wire[7:0] data_uart_out;
// reg[31:0] data_mem_in;
// wire[31:0] data_mem_out;
// reg[19:0] address;

// uart_io _uart_io(
//     .clk(clk_50M),
//     .rst(reset_btn),
//     .oe(oe_uart),
//     .we(we_uart),
//     .data_in(data_uart_in),
//     .data_out(data_uart_out),

//     .base_ram_data_wire(base_ram_data),

//     .uart_rdn(uart_rdn), 
//     .uart_wrn(uart_wrn), 
//     .uart_dataready(uart_dataready),
//     .uart_tbre(uart_tbre), 
//     .uart_tsre(uart_tsre)
// );

// ram_controller _ram_controller(
//     .clk(clk_50M),
//     .rst(reset_btn),
//     .ce(ce_ram),
//     .oe(oe_ram),
//     .we(we_ram),
//     .address(address),
//     .data_in(data_mem_in),
//     .data_out(data_mem_out),

//     .base_ram_data_wire(base_ram_data),
//     .base_ram_addr(base_ram_addr),
//     .base_ram_be_n(base_ram_be_n),
//     .base_ram_ce_n(base_ram_ce_n),
//     .base_ram_oe_n(base_ram_oe_n),
//     .base_ram_we_n(base_ram_we_n),
//     .ext_ram_data_wire(ext_ram_data),
//     .ext_ram_addr(ext_ram_addr),
//     .ext_ram_be_n(ext_ram_be_n),
//     .ext_ram_ce_n(ext_ram_ce_n),
//     .ext_ram_oe_n(ext_ram_oe_n),
//     .ext_ram_we_n(ext_ram_we_n)
// );

// localparam s0 = 3'b000;
// localparam s1 = 3'b001;
// localparam s2 = 3'b010;
// localparam s3 = 3'b011;
// localparam s4 = 3'b100;
// reg[2:0] state;
// g
// SEG7_LUT _SEG7_LUT_1(dpy1, {1'b0, state});
// assign leds = disp;

// always @(posedge clock_btn or posedge reset_btn) begin
//     if (reset_btn) begin
//         { ce_ram, oe_ram, we_ram } <= 3'b1011;
//         { oe_uart, we_uart } <= 2'b11;
//         state <= s0;
//         disp <= 16'h0000;
//     end
//     else begin
//         case (state) 
//             s0: begin // input data from uart
//                 oe_uart <= 1'b0;
//                 state <= s1;
//             end
//             s1: begin // write data into memory
//                 oe_uart <= 1'b1;
//                 we_ram <= 1'b0;
//                 disp <= { dip_sw[7:0], data_uart_out};
//                 address <= dip_sw;
//                 data_mem_in <= { 24'h000000, data_uart_out};
//                 state <= s2;
//             end
//             s2: begin // read data from memory
//                 we_ram <= 1'b1;
//                 oe_ram <= 1'b0;
//                 disp <= 16'h0000;
//                 state <= s3;
//             end
//             s3: begin // display data received from memory and send it via uart
//                 disp <= { dip_sw[7:0], data_mem_out[7:0]};
//                 oe_ram <= 1'b1;
//                 we_uart <= 1'b0;
//                 data_uart_in <= data_mem_out[7:0];
//                 state <= s4;
//             end
//         endcase
//     end
// end


// ********************************************************
// Project III before the requirement was changed

// wire ce, oe, we;
// wire[19:0] address;
// wire[31:0] data_mem_in, data_mem_out;
// wire[3:0] index;
// wire[1:0] state;

// assign uart_rdn = ~(oe & we);
// assign uart_wrn = ~(oe & we);

// fsm_ram _fsm_ram(
//     .clk(clock_btn),
//     .rst(reset_btn),
//     .inp(dip_sw),
//     .disp(leds),
//     .data_res(data_mem_out),
//     .ce(ce),
//     .oe(oe),
//     .we(we),
//     .address(address),
//     .data(data_mem_in),
//     .index(index),
//     .state(state)
// );

// ram_controller _ram_controller(
//     .clk(clk_50M),
//     .rst(reset_btn),
//     .ce(ce),
//     .oe(oe),
//     .we(we),
//     .address(address),
//     .data_in(data_mem_in),
//     .data_out(data_mem_out),

//     .base_ram_data_wire(base_ram_data),
//     .base_ram_addr(base_ram_addr),
//     .base_ram_be_n(base_ram_be_n),
//     .base_ram_ce_n(base_ram_ce_n),
//     .base_ram_oe_n(base_ram_oe_n),
//     .base_ram_we_n(base_ram_we_n),
//     .ext_ram_data_wire(ext_ram_data),
//     .ext_ram_addr(ext_ram_addr),
//     .ext_ram_be_n(ext_ram_be_n),
//     .ext_ram_ce_n(ext_ram_ce_n),
//     .ext_ram_oe_n(ext_ram_oe_n),
//     .ext_ram_we_n(ext_ram_we_n)
// );

// SEG7_LUT _SEG7_LUT_1(dpy1, state);
// SEG7_LUT _SEG7_LUT_0(dpy0, index);

// ********************************************************
// Project II

//fsm_alu main(clock_btn, reset_btn, dip_sw, leds);

endmodule
