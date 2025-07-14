module usb_rw (
    input            usb_clk_60m,  //FT232 输出的60M 时钟
    input            rst_n,        //系统复位 ,低电平
    //FT232H
    input            usb_rxf_n,    //FT232H 中FIFO 数据的可读标志
    input            usb_txe_n,    //FT232H 中FIFO 数据的可写标志
    output reg       usb_oe_n,     //FT232H 数据输出使能
    output reg       usb_rd_n,     //FT232H 读使能信号
    output reg       usb_wr_n,     //FT232H 写使能信号
    inout      [7:0] usb_data,     //FT232H 双向数据总线
    //FPGA FIFO
 
    output reg       fifo_wr_en,     //FPGA FIFO写使能
    output reg       fifo_rd_en,     //FPGA FIFO读使能
    input            empty,          //FPGA FIFO读空信号
    input      [7:0] fifo_data_out,  //FPGA FIFO中读出的数据
    output reg [7:0] fifo_data_in    //写入FPGA FIFO的数据
);
    // localparam define
    localparam IDLE = 4'b001;  //FT232H 空闲
    localparam READ = 4'b010;  //FT232H 读状态，此时数据从FT232H发送到FPGA
    localparam WRITE = 4'b100;  //FT232H 写状态，此时数据从FPGA发送到FT232H
    //reg define
    reg [2:0] cur_state;  //读写现状态
    reg [2:0] next_state;  //读写次状态
    reg       usb_oe_n_d1;  //usb_oe_n下一拍
    //*****************************************************
    //** main code
    //*****************************************************
    //在FT232H写状态，将FIFO的数据输出赋值给将USB数据总线，其他时候为高阻态
    assign usb_data = (next_state == WRITE) ? fifo_data_out : 8'hzz;
 
 
    //产生FT232H数据输出使能usb_oe_n
    always @(posedge usb_clk_60m or negedge rst_n) begin
        if (!rst_n) usb_oe_n <= 1'b1;
        else if (!usb_rxf_n) usb_oe_n <= 1'b0;
        else usb_oe_n <= 1'b1;
    end
    //FT232H数据输出使能usb_oe_n打一拍
    always @(posedge usb_clk_60m or negedge rst_n) begin
        if (!rst_n) usb_oe_n_d1 <= 1'b1;
        else usb_oe_n_d1 <= usb_oe_n;
    end
 
    //状态跳转
    always @(posedge usb_clk_60m or negedge rst_n) begin
        if (!rst_n) cur_state <= IDLE;
        else cur_state <= next_state;
    end
    //读写状态跳转条件
    always @(*) begin
        case (cur_state)
            IDLE: begin
                if (usb_rxf_n == 1'b0)  //usb_rxf_n拉低，，ft232中数据可读，下一时钟进入去读FT232H数据
                    next_state <= READ;  //usb_txe_n拉低且FPGA FIFO不空进入FT232H写
                else if ((usb_txe_n == 1'b0) && (empty == 1'b0)) next_state <= WRITE;//ft232可写且本地fifo不为空
                else next_state <= IDLE;
            end
            READ: begin  //usb_rxf_n拉高，ft232数据读空，从FT232H读回到空闲状态
                if ((usb_oe_n_d1 == 1'b1) && (usb_rxf_n == 1'b1)) next_state <= IDLE;
                else next_state <= READ;
            end
            WRITE: begin  //usb_txe_n拉高或者FPGA FIFO被读空，回到空闲状态
                if ((usb_txe_n == 1'b1) || (empty == 1'b1)) next_state <= IDLE;
                else next_state <= WRITE;
            end
            default: next_state <= IDLE;
        endcase
    end
    //状态赋值
    always @(*) begin
        case (next_state)
            IDLE: begin
                fifo_data_in <= 8'hzz;
                usb_rd_n <= 1'b1;
                usb_wr_n <= 1'b1;
                fifo_wr_en <= 1'b0;
                fifo_rd_en <= 1'b0;
            end
 
            //读状态时，将usb数据赋值给fifo_data_in
            READ: begin
                fifo_data_in <= usb_data;
                usb_wr_n <= 1'b1;
                fifo_rd_en <= 1'b0;
                //在usb_oe_n为低且在usb_oe_n下一拍也为低时拉低usb_rd_n，其他时候为高
                if ((usb_oe_n_d1 == 0) && (usb_oe_n == 0)) usb_rd_n <= 1'b0;//拉低读取标志位，开始读取ft232数据
                else usb_rd_n <= 1'b1;
                //在usb_oe_n下一拍为低，且usb_rxf_n也为低时使能FIFO写
                if ((usb_oe_n_d1 == 0) && (usb_rxf_n == 0)) fifo_wr_en <= 1'b1;//使能本地fifo写入数据
                else fifo_wr_en <= 1'b0;
            end
 
            //写状态时，使能fifo_rd_en和usb_wr_n
            WRITE: begin
                fifo_data_in <= 8'hzz;
                usb_rd_n <= 1'b1;
                fifo_wr_en <= 1'b0;
                usb_wr_n <= 1'b0;
                fifo_rd_en <= 1'b1;
            end
            
            default: begin
                fifo_data_in <= 8'hzz;
                usb_rd_n <= 1'b1;
                usb_wr_n <= 1'b1;
 
                fifo_wr_en <= 1'b0;
                fifo_rd_en <= 1'b0;
            end
        endcase
    end
endmodule