module fpga_write_to_fx2 (
    input        usb_clk_60m,  //FT232输出的60M时钟
    input        sys_rst_n,    //系统复位 ,低电平
    input        usb_rxf_n,    //FT232H中FIFO数据的可读标
    input        usb_txe_n,    //FT232H中FIFO数据的可写标
    output       usb_oe_n,     //FT232H数据输出使能
    output       usb_rd_n,     //FT232H读使能信号
    output       usb_wr_n,     //FT232H写使能信号
    output       usb_siwu_n,   //send immediate/wake up
    output       c7,         //send immediate/wake up
    inout  [7:0] usb_data      //FT232H双向数据总线
);
    //wire define
    wire [7:0] fifo_data_in;  //从FT232进到FPGA的数据
    wire [7:0] fifo_data_out;  //从FPGA输出到FT232的数据
    wire       wr_en;  //FPGA FIFO写使能
    wire       rd_en;  //FPGA FIFO读使能
    wire       full;  //FPGA FIFO写满信号
    wire       empty;  //FPGA FIFO读空信号
    //*****************************************************
    //** main code
    //*****************************************************
    assign usb_siwu_n = 1'b1;  //立即发送，唤醒
    assign c7 = 1'b1;  //立即发送，唤醒
    //USB 同步FIFO读写
    usb_rw u_usb_rw (
        .usb_clk_60m(usb_clk_60m),
        .rst_n      (sys_rst_n),
        .usb_rxf_n  (usb_rxf_n),
        .usb_txe_n  (usb_txe_n),
        .usb_oe_n   (usb_oe_n),
        .usb_rd_n   (usb_rd_n),
        .usb_wr_n   (usb_wr_n),
        .fifo_wr_en (wr_en),
        .fifo_rd_en (rd_en),
        .empty      (empty),
        .usb_data   (usb_data),
 
        .fifo_data_in (fifo_data_in),
        .fifo_data_out(fifo_data_out)
    );
    //FPGA FIFO调用
    //fifo_generator_0 u_fifo_generator_0 (
      //  .clk  (usb_clk_60m),    // input wire clk
       // .srst (1'b0),           // input wire srst
        //.din  (fifo_data_in),   // input wire [7 : 0] din
        //.wr_en(wr_en),          // input wire wr_en
        //.rd_en(rd_en),          // input wire rd_en
        //.dout (fifo_data_out),  // output wire [7 : 0] dout
        //.full (full),           // output wire full
        //.empty(empty)           // output wire empty
    //);
    
	 
	 

// ila_0 u_ila_0 (
// 	.clk(usb_clk_60m), // input wire clk
// 	.probe0(fifo_data_out), // input wire [7:0]  probe0  
// 	.probe1(fifo_data_in), // input wire [7:0]  probe1 
// 	.probe2({usb_rxf_n,usb_txe_n,usb_oe_n,usb_rd_n,usb_wr_n}), // input wire [7:0]  probe2 
// 	.probe3(0) // input wire [7:0]  probe3
// );
/* fifo_generator_0 u_fifo_generator_0 (
        .aclr (1'b0),
	     .clock(usb_clk_60m),
	     .data(fifo_data_in),
	     .rdreq (rd_en),
	     .wrreq(wr_en),
	     .empty(empty),
	     .full(full),
	     .q(fifo_data_out));       // output wire empty */


    

fifo input_fifo (
    .clk(usb_clk_60m),          // input wire clk
    .srst(sys_rst_n),           // input wire srst
    .din(fifo_data_in),         // input wire [7 : 0] din
    .wr_en(wr_en),              // input wire wr_en
    .rd_en(),              // input wire rd_en
    .dout(),       // output wire [7 : 0] dout
    .full(full),                // output wire full
    .empty(empty)               // output wire empty
);

fifo output_fifo (
    .clk(usb_clk_60m),          // input wire clk
    .srst(sys_rst_n),           // input wire srst
    .din(fifo_data_out),        // input wire [7 : 0] din
    .wr_en(rd_en),              // input wire wr_en
    .rd_en(wr_en),              // input wire rd_en
    .dout(fifo_data_in),        // output wire [7 : 0] dout
    .full(),                    // output wire full (not used)
    .empty()                    // output wire empty (not used)
);





endmodule