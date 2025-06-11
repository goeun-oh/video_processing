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

    output logic [15:0] camera_pixel,
    input logic upscale,
    input logic [1:0] rand_ball 
);

    logic diplay_en;
    assign rclk = clk;
    assign diplay_en = (x_pixel < 320 && y_pixel < 240);
    assign diplay_en2 = (x_pixel < 640 && y_pixel < 480);
    assign d_en = upscale ? diplay_en2 : diplay_en;

    assign rAddr = ~upscale ?
            ((x_pixel < 320 && y_pixel < 240) ? (y_pixel*320 + x_pixel) : 0) : (320 * (y_pixel/2) + (x_pixel/2));


    logic [16:0] image_addr, image_data;

    rom U_rom(
        .rand_ball(rand_ball),
        .addr(rAddr),
        .data(image_data)
    );


    logic display_en;
    logic [3:0] red   = rData[15:12];
    logic [3:0] green = rData[10:7];
    logic [3:0] blue  = rData[4:1];

    always_comb begin
        if (DE) begin
            if ((green > red + 2) && (green > blue + 2)) begin
                camera_pixel = {image_data[15:12], image_data[10:7], image_data[4:1]};
            end else begin
                camera_pixel = {rData[15:12], rData[10:7], rData[4:1]};
            end
        end else begin
            camera_pixel = {rData[15:12], rData[10:7], rData[4:1]};
        end
    end
endmodule


module rom (
    input  logic [16:0] addr,
    output logic [15:0] data,
    input logic [1:0] rand_ball
);

    logic [15:0] bg_rom[0:320*240-1];

    initial begin
        case (rand_ball)
            2'd0: $readmemh("bg_pingpong.mem", bg_rom);
            2'd1: $readmemh("bg_soccer.mem", bg_rom);
            2'd2: $readmemh("bg_basketball.mem", bg_rom);
            default: $readmemh("bg_pingpong.mem", bg_rom);
        endcase
    end

  
    always_comb begin
        data = bg_rom[addr];
    end
endmodule