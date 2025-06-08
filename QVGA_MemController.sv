`timescale 1ns / 1ps

module QVGA_MemController (
    // VGA Controller side
    input logic clk,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic        DE,
    
    // frame buffer side
    output logic rclk,
    output logic d_en,
    //output logic diplay_en,
    output logic [16:0] rAddr,
    input  logic [15:0] rData,

    // export side
    // output logic [ 3:0] red_port,
    // output logic [ 3:0] green_port,
    // output logic [ 3:0] blue_port,

    output logic [15:0] camera_pixel,
    input logic upscale
);

    logic diplay_en;

    assign rclk = clk;
    assign diplay_en = (x_pixel < 320 && y_pixel < 240);
    assign diplay_en2 = (x_pixel < 640 && y_pixel < 480);
    assign d_en = upscale ? diplay_en2 : diplay_en;

    assign rAddr = ~upscale ?
            ((x_pixel < 320 && y_pixel < 240) ? (y_pixel*320 + x_pixel) : 0) : (320 * (y_pixel/2) + (x_pixel/2));

    assign camera_pixel = rData;

    // assign {red_port, green_port, blue_port} = ~upscale ?
    //         (diplay_en ? {rData[15:12], rData[10:7], rData[4:1]} : 12'b0) : diplay_en2 ?
    //         {rData[15:12], rData[10:7], rData[4:1]} : 12'b0;


endmodule
