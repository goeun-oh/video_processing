`timescale 1ns / 1ps

module OV7670_Camera_CCTV (
    input  logic       clk,
    input  logic       reset,
    //OV7670 side
    output logic       xclk,
    input  logic       pclk,
    input  logic [7:0] ov7670_data,
    input  logic       href,
    input  logic       v_sync,
    //VGA side
    output logic       vga_h_sync,
    output logic       vga_v_sync,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port,
    // select
    input  logic       image_mode1,
    input  logic       image_mode2,
    input  logic       image_mode3,
    input  logic       image_mode4,
    input  logic       btn,
    input  logic       btn_reset,
    //sccb
    output logic       scl,
    inout  logic       sda,
    output logic       buzz
);

    logic clk_25MHz, clk_100MHz, clk_50MHz;
    logic        we;
    logic [16:0] wAddr;
    logic [11:0] wData, rData, rData2, rData3, rData4;
    assign xclk = clk_25MHz;
    logic [ 2:0] num;

    logic        qvga_en;
    logic [16:0] qvga_addr;
    logic [ 2:0] quadframe;

    logic [ 9:0] x_pixel;
    logic [ 9:0] y_pixel;

    logic [11:0] final_output1, final_output2, final_output3, final_output4;

    ///vga_txt///
    logic [3:0] txt_num;
    wire  [11:0] txt_vga_overlay;


    SCCB U_SCCB (
        .clk  (clk_100MHz),
        .reset(reset),
        .sda  (sda),
        .scl  (scl)
    );

    clk_wiz_0 U_VGA_Clk_25MHz (
        .clk_in1(clk),
        .reset(reset),
        .clk_25MHz(clk_25MHz),
        .clk_50MHz(clk_50MHz),
        .clk_100MHz(clk_100MHz)
    );

    capture_top U_capture_top (
        .clk(clk_100MHz),
        .reset(reset),
        .btn(btn),
        .btn_reset(btn_reset),
        .v_sync(v_sync),
        .num(num),
        .txt_num(txt_num),
        .buzz(buzz)
    );

    vga_controller U_VGA_Controller (
        .clk(clk_25MHz),
        .reset(reset),
        .h_sync(vga_h_sync),
        .v_sync(vga_v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .display_enable(display_enable)
    );

    /*
    ila_0 U_OV7670_ILA (
        .clk(clk_100MHz),  // input wire clk
        .probe0(xclk),  // input wire [0:0]  probe0  
        .probe1(pclk),  // input wire [0:0]  probe1 
        .probe2(ov7670_data),  // input wire [7:0]  probe2 
        .probe3(href),  // input wire [0:0]  probe3 
        .probe4(v_sync)  // input wire [0:0]  probe4
    );
    */

    ov7670_controller U_OV7670_Controller (
        .pclk(pclk),
        .reset(reset),
        .href(href),
        .v_sync(v_sync),
        .ov7670_data(ov7670_data),
        .we(we),
        .wAddr(wAddr),
        .wData(wData)
    );

    frameBuffer U_frameBuffer (
        //write
        .wclk(pclk),
        .we(we),
        .num(num),
        .wAddr(wAddr),
        .wData(wData),
        //read
        .rclk(clk_25MHz),
        .oe(qvga_en),
        .rAddr(qvga_addr),
        .rData(rData),
        .rData2(rData2),
        .rData3(rData3),
        .rData4(rData4)
    );

    qvga_addr_decoder U_QVGA_Addr_Decoder (
        .x_pixel  (x_pixel),
        .y_pixel  (y_pixel),
        .qvga_en  (qvga_en),
        .qvga_addr(qvga_addr),
        .quadframe(quadframe)
    );

    ISP U_ISP (
        .clk(clk_25MHz),
        .reset(reset),
        .qvga_en(qvga_en),
        .qvga_addr(qvga_addr),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .rData(rData),
        .rData2(rData2),
        .rData3(rData3),
        .rData4(rData4),
        .image_mode1(image_mode1),
        .image_mode2(image_mode2),
        .image_mode3(image_mode3),
        .image_mode4(image_mode4),
        .final_output1(final_output1),
        .final_output2(final_output2),
        .final_output3(final_output3),
        .final_output4(final_output4)
    );

    txt_vga U_Txt_Vga (
        .capture_start(capture_start),
        .txt_num(txt_num),
        .h_pos_in(x_pixel),  // vga_controller의 수평 위치 입력
        .v_pos_in(y_pixel),  // vga_controller의 수직 위치 입력
        .txt_vga_out(txt_vga_overlay)
    );

    rgb_out U_out (
        .quadframe(quadframe),
        .final_output1(final_output1),
        .final_output2(final_output2),
        .final_output3(final_output3),
        .final_output4(final_output4),
        .txt_vga_in(txt_vga_overlay),
        .red_port(red_port),
        .green_port(green_port),
        .blue_port(blue_port)
    );

endmodule



module qvga_addr_decoder (
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    output logic        qvga_en,
    output logic [16:0] qvga_addr,
    output logic [ 2:0] quadframe
);
    always_comb begin
        if (x_pixel < 320 && y_pixel < 240) begin
            qvga_addr = (y_pixel[9:1] * 160) + x_pixel[9:1];
            qvga_en   = 1'b1;
            quadframe = 3'b000;
        end else if (x_pixel < 640 && y_pixel < 240) begin
            qvga_addr = (y_pixel[9:1] * 160) + (x_pixel[9:1] - 160);
            qvga_en   = 1'b1;
            quadframe = 3'b001;
        end else if (x_pixel < 320 && y_pixel < 480) begin
            qvga_addr = ((y_pixel[9:1] - 120) * 160) + x_pixel[9:1];
            qvga_en   = 1'b1;
            quadframe = 3'b010;
        end else if (x_pixel < 640 && y_pixel < 480) begin
            qvga_addr = ((y_pixel[9:1] - 120) * 160) + (x_pixel[9:1] - 160);
            qvga_en   = 1'b1;
            quadframe = 3'b011;
        end else begin
            qvga_addr = 0;
            qvga_en   = 1'b0;
            quadframe = 3'b111;
        end
    end
endmodule
