`default_nettype wire

module thinpad_top(
    input wire clk_50M,           //50MHz 时钟输入
    input wire clk_11M0592,       //11.0592MHz 时钟输入

    input wire clock_btn,         //BTN5手动时钟按钮�???关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮�???关，带消抖电路，按下时为1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到“ON”时�???1
    output wire[15:0] leds,       //16位LED，输出时1点亮
    output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮

    //CPLD串口控制器信�???
    output wire uart_rdn,         //读串口信号，低有�???
    output wire uart_wrn,         //写串口信号，低有�???
    input wire uart_dataready,    //串口数据准备�???
    input wire uart_tbre,         //发�?�数据标�???
    input wire uart_tsre,         //数据发�?�完毕标�???

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共�???
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持�???0
    output wire base_ram_ce_n,       //BaseRAM片�?�，低有�???
    output wire base_ram_oe_n,       //BaseRAM读使能，低有�???
    output wire base_ram_we_n,       //BaseRAM写使能，低有�???

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持�???0
    output wire ext_ram_ce_n,       //ExtRAM片�?�，低有�???
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有�???
    output wire ext_ram_we_n,       //ExtRAM写使能，低有�???

    //直连串口信号
    output wire txd,  //直连串口发�?�端
    input  wire rxd,  //直连串口接收�???

    //Flash存储器信号，参�?? JS28F640 芯片手册
    output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效�???16bit模式无意�???
    inout  wire [15:0]flash_d,      //Flash数据
    output wire flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧�???
    output wire flash_ce_n,         //Flash片�?�信号，低有�???
    output wire flash_oe_n,         //Flash读使能信号，低有�???
    output wire flash_we_n,         //Flash写使能信号，低有�???
    output wire flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash�???16位模式时请设�???1

    //USB 控制器信号，参�?? SL811 芯片手册
    output wire sl811_a0,
    //inout  wire[7:0] sl811_d,     //USB数据线与网络控制器的dm9k_sd[7:0]共享
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    //网络控制器信号，参�?? DM9000A 芯片手册
    output wire dm9k_cmd,
    inout  wire[15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input  wire dm9k_int,

    //图像输出信号
    output wire[2:0] video_red,    //红色像素�???3�???
    output wire[2:0] video_green,  //绿色像素�???3�???
    output wire[1:0] video_blue,   //蓝色像素�???2�???
    output wire video_hsync,       //行同步（水平同步）信�???
    output wire video_vsync,       //场同步（垂直同步）信�???
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐�???
);

// reset
wire reset;
assign reset = reset_btn;

wire clock;
wire clock_8;
pll_example clock_gen(
    .clk_out1(clock),
    .reset(reset),
    .clk_in1(clk_50M)
);

wire flush;

// if
wire[31:0] pc_current;
wire[31:0] pc_plus_4_if;
wire[31:0] inst_if;
wire[31:0] pc_flush;
wire con_pc_jump;
wire[31:0] pc_jump;

// id
wire[31:0] inst_id, pc_plus_4_id;
wire con_alu_immediate, con_alu_signed, con_alu_sa;
wire[31:0] read_address_1_out;
wire[31:0] read_address_2_out;
wire con_jal;
wire con_mfc0;
wire con_muls;
wire con_muls_out;
wire con_divs;
wire con_divs_out;
wire con_reg_write;
wire[4:0] reg_write_address;
wire[31:0] reg_write_data;
wire[31:0] reg_read_data_1, reg_read_data_2;
wire[31:0] result;

// exe
wire[4:0] con_alu_op_id;
wire[4:0] con_alu_op;
wire con_reg_write_id, con_mov_cond_id;
wire con_reg_write_exe, con_mov_cond;
wire[31:0] alu_a, alu_b;
wire[4:0] reg_write_address_exe;
wire[31:0] mem_write_data_exe;
wire[31:0] pc_plus_8_exe;
wire[31:0] inst_exe;
wire[31:0] alu_res;
wire alu_z;
wire alu_s, alu_c, alu_v; // unused

wire exe_cp0_we_out;
wire[4:0] exe_cp0_write_addr_out;
wire[31:0] exe_cp0_data_out;

// mem
wire con_mem_read_id, con_mem_read_exe, con_mem_read;
wire con_mem_write_id, con_mem_write_exe, con_mem_write;

wire con_mem_byte_id, con_mem_byte_exe, con_mem_byte;
wire con_mem_unsigned_id, con_mem_unsigned_exe, con_mem_unsigned;
wire[1:0] con_wb_src, con_wb_src_id, con_wb_src_exe;
wire[31:0] pc_plus_8_mem;
wire[31:0] mem_address;
wire[31:0] mem_write_data;
wire[4:0] reg_write_address_mem;
wire[31:0] reg_write_data_mem;
wire con_reg_write_mem;
wire[31:0] alu_res_mem, mov_data_mem;
wire[31:0] mem_read_data, uart_read_data;
wire[1:0] ram_state;
wire[3:0] uart_state;

wire mem_cp0_we_in;
wire[4:0] mem_cp0_write_addr_in;
wire[31:0] mem_cp0_data_in;

wire mem_cp0_we_out;
wire[4:0] mem_cp0_write_addr_out;
wire[31:0] mem_cp0_data_out;

// end
wire[4:0] reg_write_address_end;
wire reg_write_end;
wire[31:0] reg_write_data_end;

wire wb_cp0_we_in;
wire[4:0] wb_cp0_write_addr_in;
wire[31:0] wb_cp0_data_in;

// cp0
wire[31:0] cp0_data_out;
wire[4:0] cp0_raddr_in;
wire[31:0] cp0_count;
wire[31:0] cp0_compare;
wire[31:0] cp0_status;
wire[31:0] cp0_cause;
wire[31:0] cp0_epc;

// exception
wire[31:0] id_exception_out;
wire[31:0] id_exception_address_out;
wire[31:0] exe_exception_in;
wire[31:0] exe_exception_address_in;
wire[31:0] exe_exception_out;
wire[31:0] exe_exception_address_out;
wire[31:0] mem_exception_in;
wire[31:0] mem_exception_address_in;
wire[31:0] mem_exception_out;
wire[31:0] mem_exception_address_out;
wire[31:0] mem_epc_out;
wire reg_write_disable;

// delayslot
wire this_delayslot_in;
wire this_delayslot_out;
wire next_delayslot_out;
wire exe_this_delayslot_in;
wire exe_this_delayslot_out;
wire mem_this_delayslot_in;
wire mem_this_delayslot_out;

// hazard
wire[0:3] stall, nop;

wire mem_conflict;
wire mem_ram_en, mem_uart_en, mem_graph_en; 
wire[31:0] mem_ram_read_data, mem_uart_read_data;

// vga
wire[6:0] letter_out;
wire[2:0] letter_h_out;
wire[3:0] letter_v_out;

// flash
wire clk_8;
wire flash_flag;
wire[22:0] flash_address;
wire[2:0] flash_state;
wire flash_complete;
wire[15:0] flash_data;
wire[31:0] flash_data_out;
wire[19:0] flash_data_address_out;
wire flash_data_en_out;
wire flash_stall;

wire[31:0] flash_ram_data_addr;
wire flash_ram_byte;
wire[31:0] flash_ram_data;
wire flash_ram_data_en;
wire flash_ram_data_read;
wire flash_ram_data_write;

//keyboard
wire[7:0] keyboard_data;

// div
wire div_ready;
wire[31:0] div_result;
wire[31:0] div_opdata1;
wire[31:0] div_opdata2;
wire div_start;
wire div_signed;
wire div_stall;

clock_8 _clock_8(
    .clk(clock),
    .clk_8(clk_8)
);

/*
keyboard _keyboard(
    .clk(clock),
    .rst_n(reset),
    
    .sl811_a0(sl811_a0),
    .sl811_wr_n(sl811_wr_n),
    .sl811_rd_n(sl811_rd_n),
    .sl811_cs_n(sl811_cs_n),
    .sl811_rst_n(sl811_rst_n),
    .sl811_dack_n(sl811_dack_n),
    
    .data(dm9k_sd[7:0]),
    .char_data(keyboard_data)
);
*/


flash_controller _flash_controller(
    .clk(clk_8),
    .rst(reset),
    .flash_address(flash_address),
    .flag(flash_flag),
    
    // flash io
    .flash_a(flash_a),
    .flash_d(flash_d),
    .flash_rp(flash_rp_n),
    .flash_vpen(flash_vpen),
    .flash_ce(flash_ce_n),
    .flash_oe(flash_oe_n),
    .flash_we(flash_we_n),
    .flash_byte(flash_byte_n),
    
    // data
    .data_out(flash_data)
);

init_ram _init_ram(
    .clk(clk_8),
    .rst(reset),
    
    // ram controller
    .flash_data_out(flash_data_out),
    .flash_data_address_out(flash_data_address_out),
    .flash_data_en(flash_data_en_out),
    
    
    .flash_address(flash_address),
    .flash_flag(flash_flag),
    .flash_data_in(flash_data),
    
    
    .ram_data_addr(flash_ram_data_addr),
    .ram_byte(flash_ram_byte),
    .ram_data(flash_ram_data),
    .ram_data_read(flash_ram_data_read),
    .ram_data_write(flash_ram_data_write),
    
    .flash_stall(flash_stall)
);

pc _pc(
    .clk(clock),
    .rst(reset),
    .flush(flush),
    .pc_flush(pc_flush),
    .stall(stall[0]),
    .inst(inst_if),  
    .pc_jump(pc_jump),
    .con_pc_jump(con_pc_jump),  
    .pc_plus_4(pc_plus_4_if),
    .pc_current(pc_current)
);

ram_controller _ram_controller(
    .clk(clock),
    .rst(reset),
    .byte(con_mem_byte),
    .inst_addr(pc_current),
    .data_addr(mem_address),
    .data(mem_write_data),
    .data_en(mem_ram_en),
    .data_read(con_mem_read),    
    .data_write(con_mem_write),
    
    .flash_data_addr(flash_data_address_out),
    .flash_data(flash_data_out),
    .flash_data_en(flash_data_en_out),

    .base_ram_data(base_ram_data),
    .base_ram_addr(base_ram_addr),
    .base_ram_be_n(base_ram_be_n),
    .base_ram_ce_n(base_ram_ce_n),
    .base_ram_oe_n(base_ram_oe_n),
    .base_ram_we_n(base_ram_we_n),

    .ext_ram_data(ext_ram_data),
    .ext_ram_addr(ext_ram_addr),
    .ext_ram_be_n(ext_ram_be_n),
    .ext_ram_ce_n(ext_ram_ce_n),
    .ext_ram_oe_n(ext_ram_oe_n),
    .ext_ram_we_n(ext_ram_we_n),

    .result_inst(inst_if),
    .result_data(mem_ram_read_data),
    .conflict(mem_conflict),
    .ram_state(ram_state)
);

uart_controller _uart_controller(
    .clk(clock),
    .address(mem_address),
    .data(mem_write_data[7:0]),
    .en(mem_uart_en),
    .data_read(con_mem_read),
    .data_write(con_mem_write),

    .uart_data(base_ram_data[7:0]),
    .uart_rdn(uart_rdn),
    .uart_wrn(uart_wrn),
    .uart_dataready(uart_dataready),
    .uart_tbre(uart_tbre),
    .uart_tsre(uart_tsre),

    .result_data(mem_uart_read_data),
    .uart_state(uart_state)
);

if_id _if_id(
    .clk(clock),
    .rst(reset),
    .flush(flush),
    .stall(stall[1]),
    .nop(nop[0]),
    .inst_in(inst_if),
    .pc_plus_4_in(pc_plus_4_if),
    .inst_out(inst_id),
    .pc_plus_4_out(pc_plus_4_id)
);

registers _registers(
    .clk(clock),
    .rst(reset),
    
    .stall(stall),

    .read_address_1(read_address_1_out),
    .read_address_2(read_address_2_out),
    .write_address(reg_write_address),
    .write_data(reg_write_data),
    .con_reg_write(con_reg_write),

    .read_data_1(reg_read_data_1),
    .read_data_2(reg_read_data_2),
    .result(result) // for debug
);

assign leds = result;
//assign leds = { 8'b0, keyboard_data[7:0] };
//assign leds = { uart_dataready, result[14:0]};
//assign leds = { stall[0], mem_conflict, con_mem_read, con_mem_write, pc_current[11:0] };

wire[31:0] reg_read_data_1_forw, reg_read_data_2_forw;

forward _forward_id_A(
    .source(3'b100),
    .read_address(inst_id[25:21]),
    .read_data(reg_read_data_1),
    .reg_write_address_mem(reg_write_address_mem),
    .reg_write_mem(con_reg_write_mem),
    .wb_src_mem(con_wb_src),
    .pc_plus_8_mem(pc_plus_8_mem),
    .alu_res_mem(alu_res_mem),
    .read_data_new(reg_read_data_1_forw)
);

forward _forward_id_B(
    .source(3'b100),
    .read_address(inst_id[20:16]),
    .read_data(reg_read_data_2),
    .reg_write_address_mem(reg_write_address_mem),
    .reg_write_mem(con_reg_write_mem),
    .wb_src_mem(con_wb_src),
    .pc_plus_8_mem(pc_plus_8_mem),
    .alu_res_mem(alu_res_mem),
    .read_data_new(reg_read_data_2_forw)
);

jump_control _jump_control(
    .inst(inst_id),
    .pc_plus_4(pc_plus_4_id),
    .data_a(reg_read_data_1_forw),
    .data_b(reg_read_data_2_forw),
    .this_delayslot_in(this_delayslot_in),
    .this_delayslot_out(this_delayslot_out),
    .next_delayslot_out(next_delayslot_out),
    .con_pc_jump(con_pc_jump),
    .pc_jump(pc_jump)
);

control _control(
    .inst(inst_id),
    .pc(pc_plus_4_id),

    .con_alu_immediate(con_alu_immediate),
    .con_alu_signed(con_alu_signed),
    .con_alu_sa(con_alu_sa),
    .con_jal(con_jal),
    .con_mfc0(con_mfc0),
    .con_muls(con_muls),
    .con_divs(con_divs),
    
    // exception
    .exception_out(id_exception_out),
    .exception_address_out(id_exception_address_out),
    
    .read_address_1(read_address_1_out),
    .read_address_2(read_address_2_out),
    
    .con_alu_op(con_alu_op_id),
    .con_reg_write(con_reg_write_id),
    .con_mov_cond(con_mov_cond_id),

    .con_mem_byte(con_mem_byte_id),
    .con_mem_unsigned(con_mem_unsigned_id),
    .con_mem_read(con_mem_read_id),    
    .con_mem_write(con_mem_write_id),
    .con_wb_src(con_wb_src_id)
);

hazard_detector _hazard_detector(
    .inst_id(inst_id),
    .inst_exe(inst_exe),
    //.read_address_1_id(inst_id[25:21]),
    //.read_address_2_id(inst_id[20:16]),
    .reg_write_address_exe(reg_write_address_exe),
    .reg_write_exe(con_reg_write_exe),
    // .read_address_1_exe(inst_exe[25:21]),
    // .read_address_2_exe(inst_exe[20:16]),
    .reg_write_address_mem(reg_write_address_mem),
    .reg_write_mem(con_reg_write_mem),
    .wb_src_mem(con_wb_src),
    .mem_conflict(mem_conflict),
    .con_pc_jump(con_pc_jump),
    .ram_en(mem_ram_en),
    .ram_state(ram_state),
    .mem_write(con_mem_write),
    .uart_en(mem_uart_en),
    .uart_state(uart_state),
    .div_stall(div_stall),
    .flash_stall(flash_stall),
    .stall(stall),
    .nop(nop) 
);

id_exe _id_exe(
    .clk(clock),
    .rst(reset),
    .flush(flush),
    .stall(stall[2]),
    .nop(nop[1]),
    .data_1(reg_read_data_1),
    .data_2(reg_read_data_2),
    .inst_in(inst_id),
    .pc_plus_4(pc_plus_4_id),
    
    // exception
    .id_exception(id_exception_out),
    .id_exception_address(id_exception_address_out),
    .exe_exception(exe_exception_in),
    .exe_exception_address(exe_exception_address_in),

    // for forwarding
    .forw_reg_write_address_mem(reg_write_address_mem),
    .forw_reg_write_mem(con_reg_write_mem),
    .forw_wb_src_mem(con_wb_src),
    .forw_pc_plus_8_mem(pc_plus_8_mem),
    .forw_alu_res_mem(alu_res_mem),
    .forw_reg_write_address_wb(reg_write_address),
    .forw_reg_write_wb(con_reg_write),
    .forw_reg_write_data_wb(reg_write_data),
    .forw_reg_write_address_end(reg_write_address_end),
    .forw_reg_write_end(reg_write_end),
    .forw_reg_write_data_end(reg_write_data_end),    

    .con_alu_immediate(con_alu_immediate),
    .con_alu_signed(con_alu_signed),
    .con_alu_sa(con_alu_sa),
    .con_jal(con_jal),
    .con_mfc0(con_mfc0),
    .con_muls(con_muls),
    .con_muls_out(con_muls_out),
    
    .con_divs(con_divs),
    .con_divs_out(con_divs_out),
    
    .con_alu_op_in(con_alu_op_id),
    .con_reg_write_in(con_reg_write_id),
    .con_mov_cond_in(con_mov_cond_id),   
    .con_alu_op_out(con_alu_op),    
    .con_reg_write_out(con_reg_write_exe),
    .con_mov_cond_out(con_mov_cond),     

    .con_mem_byte_in(con_mem_byte_id),
    .con_mem_unsigned_in(con_mem_unsigned_id),    
    .con_mem_read_in(con_mem_read_id),    
    .con_mem_write_in(con_mem_write_id),
    .con_mem_byte_out(con_mem_byte_exe),    
    .con_mem_unsigned_out(con_mem_unsigned_exe),
    .con_mem_read_out(con_mem_read_exe),    
    .con_mem_write_out(con_mem_write_exe),

    .con_wb_src_in(con_wb_src_id),
    .con_wb_src_out(con_wb_src_exe),
    
    // delayslot
    .id_this_delayslot(this_delayslot_out),
    .id_next_delayslot(next_delayslot_out),
    .this_delayslot_out(this_delayslot_in),
    .exe_this_delayslot(exe_this_delayslot_in),
    
    
    .data_A(alu_a),
    .data_B(alu_b),
    .reg_write_address(reg_write_address_exe),
    .mem_write_data(mem_write_data_exe),
    .pc_plus_8(pc_plus_8_exe),
    .inst_out(inst_exe)
);

alu _alu(
    .op(con_alu_op),
    .A(alu_a),
    .B(alu_b),
    
    .inst_in(inst_exe),
    
    // delayslot
    .this_delayslot_in(exe_this_delayslot_in),
    .this_delayslot_out(exe_this_delayslot_out),
    
    .mem_cp0_we(mem_cp0_we_out),
    .mem_cp0_write_addr(mem_cp0_write_addr_out),
    .mem_cp0_data(mem_cp0_data_out),
    
    .wb_cp0_we(wb_cp0_we_in),
    .wb_cp0_write_addr(wb_cp0_write_addr_in),
    .wb_cp0_data(wb_cp0_data_in),
    
    .cp0_data_in(cp0_data_out),
    .cp0_read_addr(cp0_raddr_in),
    
    .cp0_we_out(exe_cp0_we_out),
    .cp0_write_addr_out(exe_cp0_write_addr_out),
    .cp0_data_out(exe_cp0_data_out),
    
    // exception
    .exception_in(exe_exception_in),
    .exception_address_in(exe_exception_address_in),
    .exception_out(exe_exception_out),
    .exception_address_out(exe_exception_address_out),
    
    // div
    .div_ready_in(div_ready),
    .div_result_in(div_result),
    .div_opdata1_out(div_opdata1),
    .div_opdata2_out(div_opdata2),
    .div_start_out(div_start),
    .div_signed_out(div_signed),
    .div_stall_out(div_stall),
    
    .res(alu_res),
    .S(alu_s),
    .Z(alu_z),
    .C(alu_c),
    .V(alu_v)
);

exe_mem _exe_mem(
    .clk(clock),
    .rst(reset),
    .flush(flush),
    .stall(stall[3]),
    .nop(nop[2]),    
    .inst_in(inst_exe),
    .alu_z(alu_z),
    .alu_res(alu_res),
    
    .exe_cp0_we(exe_cp0_we_out),
    .exe_cp0_write_addr(exe_cp0_write_addr_out),
    .exe_cp0_data(exe_cp0_data_out),
    .mem_cp0_we(mem_cp0_we_in),
    .mem_cp0_write_addr(mem_cp0_write_addr_in),
    .mem_cp0_data(mem_cp0_data_in),
    
    // exception
    .exe_exception(exe_exception_out),
    .exe_exception_address(exe_exception_address_out),
    .mem_exception(mem_exception_in),
    .mem_exception_address(mem_exception_address_in),
    
    //delayslot
    .exe_this_delayslot(exe_this_delayslot_out),
    .mem_this_delayslot(mem_this_delayslot_in),
        
    
    .pc_plus_8_in(pc_plus_8_exe),
    .reg_write_address_in(reg_write_address_exe),
    .mem_write_data_in(mem_write_data_exe),
    .data_A(alu_a),

    // for forwarding
    .forw_reg_write_address_wb(reg_write_address),
    .forw_reg_write_wb(con_reg_write),
    .forw_reg_write_data_wb(reg_write_data),
    .forw_reg_write_address_end(reg_write_address_end),
    .forw_reg_write_end(reg_write_end),
    .forw_reg_write_data_end(reg_write_data_end),
 
    .con_reg_write(con_reg_write_exe),
    .con_mov_cond(con_mov_cond),

    .con_mem_byte_in(con_mem_byte_exe),
    .con_mem_unsigned_in(con_mem_unsigned_exe),
    .con_mem_read_in(con_mem_read_exe),    
    .con_mem_write_in(con_mem_write_exe),
    .con_mem_byte_out(con_mem_byte),
    .con_mem_unsigned_out(con_mem_unsigned),
    .con_mem_read_out(con_mem_read),
    .con_mem_write_out(con_mem_write),
    .con_wb_src_in(con_wb_src_exe),
    .con_wb_src_out(con_wb_src),
    
    .con_muls(con_muls_out),
    .con_divs(con_divs_out),

    .pc_plus_8_out(pc_plus_8_mem),
    .mem_address(mem_address),
    .reg_write_address(reg_write_address_mem),
    .mem_write_data(mem_write_data),
    .reg_write(con_reg_write_mem),
    .alu_res_out(alu_res_mem),
    .mov_data(mov_data_mem)
);

mem _mem(
    .clk(clock),
    .rst(reset),
    .address(mem_address),
    .ram_read_data(mem_ram_read_data),
    .uart_read_data(mem_uart_read_data),
    .mem_read(con_mem_read),
    .mem_write(con_mem_write),
    
    // exception
    .exception_in(mem_exception_in),
    .exception_address_in(mem_exception_address_in),
    .cp0_status_in(cp0_status),
    .cp0_cause_in(cp0_cause),
    .cp0_epc_in(cp0_epc),
    .wb_cp0_we(wb_cp0_we_in),
    .wb_cp0_write_address(wb_cp0_write_addr_in),
    .wb_cp0_data(wb_cp0_data_in),
    .exception_out(mem_exception_out),
    .exception_address_out(mem_exception_address_out),
    .cp0_epc_out(mem_epc_out),
    .reg_write_disable_out(reg_write_disable),
    
    // cp0
    .cp0_we_in(mem_cp0_we_in),
    .cp0_write_addr_in(mem_cp0_write_addr_in),
    .cp0_data_in(mem_cp0_data_in),
    .cp0_we_out(mem_cp0_we_out),
    .cp0_write_addr_out(mem_cp0_write_addr_out),
    .cp0_data_out(mem_cp0_data_out),
    
    //delayslot
    .this_delayslot_in(mem_this_delayslot_in),
    .this_delayslot_out(mem_this_delayslot_out),
    
    .ram_en(mem_ram_en),
    .uart_en(mem_uart_en),
    .graph_en(mem_graph_en),
    .read_data(mem_read_data)
);

mem_wb _mem_wb(
    .clk(clock),
    .rst(reset),
    .flush(flush),
    .stall(stall[3]),
    .nop(nop[3]),   
    .reg_write_in(con_reg_write_mem),
    .reg_write_address_in(reg_write_address_mem),
    .pc_plus_8(pc_plus_8_mem),
    .mov_data(mov_data_mem),
    .mem_read_data(mem_read_data),
    .alu_res(alu_res_mem),
    .con_wb_src(con_wb_src),
    
    // exception
    .reg_write_disable_in(reg_write_disable),
    
    .mem_cp0_we(mem_cp0_we_out),
    .mem_cp0_write_addr(mem_cp0_write_addr_out),
    .mem_cp0_data(mem_cp0_data_out),
    
    .wb_cp0_we(wb_cp0_we_in),
    .wb_cp0_write_addr(wb_cp0_write_addr_in),
    .wb_cp0_data(wb_cp0_data_in),

    .con_mem_byte(con_mem_byte),
    .con_mem_unsigned(con_mem_unsigned),
    .reg_write_out(con_reg_write),
    .reg_write_address_out(reg_write_address),
    .reg_write_data(reg_write_data)
);

wb_end _wb_end(
    .clk(clock),
    .rst(reset),
    .stall(stall[3]), 
    .reg_write_address_in(reg_write_address),
    .reg_write_data_in(reg_write_data),
    .reg_write_in(con_reg_write),
    .reg_write_address_out(reg_write_address_end),
    .reg_write_data_out(reg_write_data_end),
    .reg_write_out(reg_write_end)
);

cp0_reg _cp0_reg(
    .clk(clock),
    .rst(reset),
    .w_in(wb_cp0_we_in),
    .waddr_in(wb_cp0_write_addr_in),
    .raddr_in(cp0_raddr_in),
    .data_in(wb_cp0_data_in),
    
    // exception
    .exception_in(mem_exception_out),
    .exception_address_in(mem_exception_address_out),
    
    // delayslot
    .this_delayslot_in(mem_this_delayslot_out),
    
    .count_out(cp0_count),
    .compare_out(cp0_compare),
    .status_out(cp0_status),
    .cause_out(cp0_cause),
    .epc_out(cp0_epc),
    .data_out(cp0_data_out)
);

flush_controller _flush_controller(
    .rst(reset),
    .exception_in(mem_exception_out),
    .cp0_epc_in(mem_epc_out),
    .flush(flush),
    .pc_flush(pc_flush)  
);

wire[11:0] hdata;

assign video_clk = clk_50M;
vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
    .clk(video_clk),
    .rst(reset),
    .hdata(hdata),
    .vdata(),
    .letter(letter_out),
    .letter_h(letter_h_out),
    .letter_v(letter_v_out),
    .hsync(video_hsync),
    .vsync(video_vsync),
    .data_enable(video_de),
    
    .vga_we_in(mem_graph_en),
    .vga_address_in(mem_address[11:0]),
    .vga_data_in(mem_write_data[7:0])
);

letter_rgb _letter_rgb(
    .rst(reset),
    .letter(letter_out),
    .letter_h(letter_h_out),
    .letter_v(letter_v_out),
    .red(video_red),
    .green(video_green),
    .blue(video_blue)
);

div _div(
    .clk(clock),
    .rst(reset),
    .signed_div_in(div_signed),
    .opdata1_in(div_opdata1),
    .opdata2_in(div_opdata2),
    .start_in(div_start),
    .annul_in(flush),
    .result_out(div_result),
    .ready_out(div_ready)
);

endmodule
