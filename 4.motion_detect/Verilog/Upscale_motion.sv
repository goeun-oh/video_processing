`timescale 1ns / 1ps

module Upscale_motion (
    input  logic        clk_25MHz,
    input  logic        reset,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [11:0] stored_image0,
    input  logic [11:0] stored_image1,
    input  logic [11:0] stored_image2,
    output logic [11:0] upscaled_image0,
    output logic [11:0] upscaled_image1,
    output logic [11:0] upscaled_image2
);
    upscale U_UPSCALER0 (
        .clk_25MHz(clk_25MHz),
        .reset(reset),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .image(stored_image0),
        .upscaled_image(upscaled_image0)
    );

    upscale U_UPSCALER1 (
        .clk_25MHz(clk_25MHz),
        .reset(reset),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .image(stored_image1),
        .upscaled_image(upscaled_image1)
    );

    upscale U_UPSCALER2 (
        .clk_25MHz(clk_25MHz),
        .reset(reset),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .image(stored_image2),
        .upscaled_image(upscaled_image2)
    );
endmodule
