`timescale 1ns / 1ps

module ISP_UpScale_Filter (
    input  logic        clk_25MHz,
    input  logic        clk_100MHz,
    input  logic        reset,
    input  logic        start,
    input  logic        display_enable,
    // UpScale
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [11:0] in_camera,
    input  logic [15:0] in_backGround,
    output logic        oe,
    output logic [16:0] addr_camera,
    output logic [14:0] addr_backGround,
    output logic [11:0] vga_camera,
    // Filter
    input  logic [ 7:0] temp_data,
    input  logic [ 7:0] humi_data,
    output logic [11:0] filtered_pixel,
    // mux
    input  logic        color_Diff
);
    logic [11:0] raw_pixel, vga_backGround;

    UpScale U_UpScale (
        .clk_25MHz      (clk_25MHz),
        .reset          (reset),
        .display_enable (display_enable),
        .x_pixel        (x_pixel),
        .y_pixel        (y_pixel),
        .in_camera      (in_camera),
        .in_backGround  (in_backGround),
        .oe             (oe),
        .addr_camera    (addr_camera),
        .addr_backGround(addr_backGround),
        .vga_camera     (vga_camera),
        .vga_backGround (vga_backGround)
    );

     mux U_mux (
        .sel(color_Diff),
        .x0 (vga_camera),
        .x1 (vga_backGround),
        .y  (raw_pixel)
    );

    Temp_Humi_Filter U_Filter (
        .clk_100MHz    (clk_100MHz),
        .clk_25MHz     (clk_25MHz),
        .reset         (reset),
        .start         (start),
        .display_enable(display_enable),
        .temp_data     (temp_data),
        .humi_data     (humi_data),
        .raw_pixel     (raw_pixel),
        .filtered_pixel(filtered_pixel)
    );
endmodule





module mux (
    input logic sel,
    input logic [11:0] x0,
    input logic [11:0] x1,
    output logic [11:0] y
);
    always_comb begin
        y = x0;
        case (sel)
            1'b0: y = x0;
            1'b1: y = x1;
        endcase
    end
endmodule


module UpScale (
    input  logic        clk_25MHz,
    input  logic        reset,
    input  logic        display_enable,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [11:0] in_camera,
    input  logic [15:0] in_backGround,
    output logic        oe,
    output logic [16:0] addr_camera,
    output logic [14:0] addr_backGround,
    output logic [11:0] vga_camera,
    output logic [11:0] vga_backGround
);


    // upscaler U_UpScale_Camera (
    //     .clk           (clk_25MHz),
    //     .reset         (reset),
    //     .x_pixel       (x_pixel),
    //     .y_pixel       (y_pixel),
    //     .display_enable(display_enable),
    //     .inData        (in_camera),
    //     .outAddr       (addr_camera),
    //     .outData       (vga_camera)
    // );

    upscaler_bilinear_fsm U_UpScale_Camera (
        .clk_25MHz     (clk_25MHz),
        .reset         (reset),
        .display_enable(display_enable),
        .x_pixel       (x_pixel),
        .y_pixel       (y_pixel),
        .rAddr         (addr_camera),
        .oe            (oe),
        .rData         (in_camera),
        .pixel_out     (vga_camera)
    );

    upScaler_Background U_upScaler_Background (
        .x_pixel       (x_pixel),
        .y_pixel       (y_pixel),
        .display_enable(display_enable),
        .qqvga_data    (in_backGround),
        .qqvga_addr    (addr_backGround),
        .vga_image     (vga_backGround)
    );

endmodule

module Temp_Humi_Filter (
    input  logic        clk_100MHz,
    input  logic        clk_25MHz,
    input  logic        reset,
    input  logic        start,
    input  logic        display_enable,
    input  logic [ 7:0] temp_data,
    input  logic [ 7:0] humi_data,
    input  logic [11:0] raw_pixel,
    output logic [11:0] filtered_pixel
);
    logic [7:0] temp, humi;
    logic [11:0] humi_filter_pixel;

    // test_temp U_TEST_TEMP (
    //     .clk  (clk_100MHz),
    //     .reset(reset),
    //     .start(start),
    //     .data ()
    // );

    // test_humi U_TEST_HUMI (
    //     .clk  (clk_100MHz),
    //     .reset(reset),
    //     .start(start),
    //     .data ()
    // );

    temperture_filter U_Temp_Filter (
        .clk           (clk_25MHz),
        .reset         (reset),
        .temp_data     (temp_data),
        .raw_pixel     (humi_filter_pixel),
        .filtered_pixel(filtered_pixel)
    );

    humidity_filter U_HUMIDITY_Filter (
        .clk           (clk_25MHz),
        .reset         (reset),
        .display_enable(display_enable),
        .humi_data     (humi_data),
        .raw_pixel     (raw_pixel),
        .filtered_pixel(humi_filter_pixel)
    );

endmodule

