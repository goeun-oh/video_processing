`timescale 1ns / 1ps

module OV7670_Camera (
    input  logic       clk,
    input  logic       reset,
    // OV7670 side
    output logic       xclk,
    input  logic       pclk,
    input  logic [7:0] ov7670_data,
    input  logic       href,
    input  logic       v_sync,
    output logic       sioc,
    output logic       siod,
    //VGA side
    output logic       h_sync_controller,
    output logic       v_sync_controller,
    output logic [3:0] red_port,
    output logic [3:0] blue_port,
    output logic [3:0] green_port,
    //DHT11
    input  logic       start,
    inout  logic       dht_11,
    // FND
    output logic [7:0] fndFont,
    output logic [3:0] fndCom
);

  logic        clk_25MHz;

  logic [ 9:0] x_pixel;
  logic [ 9:0] y_pixel;
  logic        we;
  logic        oe;
  logic [16:0] wAddr;
  logic [11:0] wData;
  logic [11:0] rData;
  logic [11:0] vgaData;
  logic        display_enable;

  //----chroma key ----
  logic [ 1:0] dominant_color;
  logic [11:0] chromaData;
  logic [11:0] chromaData_result;
  //----chroma key ----

  //----back ground image ----
  logic [15:0] image_565;
  logic [16:0] qvga_addr;
  logic [14:0] qqvga_addr;
  logic [ 1:0] color_Diff;
  //----back ground image ----

  logic [11:0] Filtered_pixel;
  logic [7:0] temp_data, humi_data;
  logic is_text_pixel;

  assign xclk = clk_25MHz;

  camera_configure U_SCCB (
      .clk  (clk_25MHz),
      .reset(reset),
      .sioc (sioc),
      .siod (siod),
      .done ()
  );

  clk_wiz_0 U_CLK_WIZ (
      .clk_in1   (clk),
      .reset     (reset),
      .clk_25MHz (clk_25MHz),
      .clk_100MHz(clk_100MHz)
  );

  vga_controller U_VGA_Controller (
      .clk           (clk_25MHz),
      .reset         (reset),
      .h_sync        (h_sync_controller),
      .v_sync        (v_sync_controller),
      .x_pixel       (x_pixel),
      .y_pixel       (y_pixel),
      .display_enable(display_enable)
  );

  ov7670_controller U_OV7670_Controller (
      .pclk       (pclk),
      .reset      (reset),
      .href       (href),
      .v_sync     (v_sync),
      .ov7670_data(ov7670_data),
      .we         (we),
      .wAddr      (wAddr),
      .wData      (wData)
  );

  frameBuffer U_FrameBuffer (
      // write side
      .wclk (pclk),
      .we   (we),
      .wAddr(wAddr),
      .wData(wData),
      // read side
      .rclk (clk_25MHz),
      .oe   (oe),
      .rAddr(qvga_addr),
      .rData(rData)

  );

  chromakey U_Chromakey (
      .clk_25MHz     (clk_25MHz),
      .reset         (reset),
      .x_pixel       (x_pixel),
      .y_pixel       (y_pixel),
      .pixel_in      (vgaData),
      .color_Diff    (color_Diff),
      .dominant_color(dominant_color)
  );

  ISP_UpScale_Filter U_ISP_UpScale_Filter (
      .clk_25MHz      (clk_25MHz),
      .clk_100MHz     (clk_100MHz),
      .reset          (reset),
      .start          (start),
      .display_enable (display_enable),
      .x_pixel        (x_pixel),
      .y_pixel        (y_pixel),
      .in_camera      (rData),
      .in_backGround  (image_565),
      .oe             (oe),
      .addr_camera    (qvga_addr),
      .addr_backGround(qqvga_addr),
      .vga_camera     (vgaData),
      .temp_data      (temp_data),
      .humi_data      (humi_data),
      .filtered_pixel (Filtered_pixel),
      .color_Diff     (color_Diff)
  );

  image_rom U_Image_ROM (
      .addr          (qqvga_addr),
      .dominant_color(dominant_color),
      .data          (image_565)
  );

  dht_text_fnd U_DHT11_FND_TEXT (
      .clk_100MHz    (clk_100MHz),
      .reset         (reset),
      .btn_start     (start),
      .dht_11        (dht_11),
      .HR            (humi_data),
      .TR            (temp_data),
      .fndCom        (fndCom),
      .fndFont       (fndFont),
      .x_pixel       (x_pixel),
      .y_pixel       (y_pixel),
      .display_enable(display_enable),
      .is_text_pixel (is_text_pixel)
  );

  output_select U_Output_Select (
      .x_pixel       (x_pixel),
      .y_pixel       (y_pixel),
      .display_enable(display_enable),
      .is_text_pixel (is_text_pixel),
      .Filtered_pixel(Filtered_pixel),
      .red_port      (red_port),
      .blue_port     (blue_port),
      .green_port    (green_port)
  );


endmodule


module output_select (
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic        display_enable,
    input  logic        is_text_pixel,
    input  logic [11:0] Filtered_pixel,
    output logic [ 3:0] red_port,
    output logic [ 3:0] blue_port,
    output logic [ 3:0] green_port
);

  always_comb begin
    if (display_enable && (is_text_pixel || (x_pixel < 15 || x_pixel > 625) || (y_pixel < 5 || y_pixel > 475))) begin
      {red_port, green_port, blue_port} = 12'b0;
    end else begin
      if (display_enable) begin
        {red_port, green_port, blue_port} = Filtered_pixel;
      end else begin
        {red_port, green_port, blue_port} = 12'b0;
      end
    end
  end


endmodule
