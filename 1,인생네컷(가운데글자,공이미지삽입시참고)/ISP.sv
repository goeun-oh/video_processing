`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/27 13:08:55
// Design Name: 
// Module Name: ISP
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ISP (
    input  logic        clk,
    input  logic        reset,
    input  logic        qvga_en,
    input  logic [16:0] qvga_addr,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [11:0] rData,
    input  logic [11:0] rData2,
    input  logic [11:0] rData3,
    input  logic [11:0] rData4,
    input  logic        image_mode1,
    input  logic        image_mode2,
    input  logic        image_mode3,
    input  logic        image_mode4,
    output logic [11:0] final_output1,
    output logic [11:0] final_output2,
    output logic [11:0] final_output3,
    output logic [11:0] final_output4
);

    logic [11:0] image_444_1, image_1_upscale;

    logic [11:0] image_444_2, gray_output2, image_2_sobel;

    logic [11:0] image_444_3, image_3_gaussian;

    logic [11:0] image_444_4, image_4_gray;

    mux U_datamux (
        .sel(qvga_en),
        .x0 (12'b0),
        .x1 (rData),
        .y  (image_444_1)
    );

    mux U_datamux2 (
        .sel(qvga_en),
        .x0 (12'b0),
        .x1 (rData2),
        .y  (image_444_2)
    );

    mux U_datamux3 (
        .sel(qvga_en),
        .x0 (12'b0),
        .x1 (rData3),
        .y  (image_444_3)
    );

    mux U_datamux4 (
        .sel(qvga_en),
        .x0 (12'b0),
        .x1 (rData4),
        .y  (image_444_4)
    );

    upscaler_interpolation U_upscaler_interpolation1 (
        .clk_25MHz(clk),
        .reset(reset),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .final_data(image_444_1),
        .up_scale_data(image_1_upscale)
    );

    rgb2gray U_RGB2GRAY2 (
        .color_rgb(image_444_2),
        .gray_rbg (gray_output2)
    );

    GraytoSobel U_Sobel2 (
        .clk(clk),
        .reset(reset),
        .pixel_in(gray_output2),
        .addr(qvga_addr),
        .edge_out(image_2_sobel)
    );

    gaussian U_image3_gaussian (
        .clk(clk),
        .reset(reset),
        .pixel_in(image_444_3),
        .addr(qvga_addr),
        .edge_out(image_3_gaussian)
    );

    rgb2gray U_RGB2GRAY4 (
        .color_rgb(image_444_4),
        .gray_rbg (image_4_gray)
    );

    mux U_image_1 (
        .sel(image_mode1),
        .x0 (image_444_1),
        .x1 (image_1_upscale),
        .y  (final_output1)
    );
    mux U_image_2 (
        .sel(image_mode2),
        .x0 (image_444_2),
        .x1 (image_2_sobel),
        .y  (final_output2)
    );

    mux U_image_3 (
        .sel(image_mode3),
        .x0 (image_444_3),
        .x1 (image_3_gaussian),
        .y  (final_output3)
    );

    mux U_image_4 (
        .sel(image_mode4),
        .x0 (image_444_4),
        .x1 (image_4_gray),
        .y  (final_output4)
    );

endmodule

module mux (
    input  logic        sel,
    input  logic [11:0] x0,
    input  logic [11:0] x1,
    output logic [11:0] y
);
    always_comb begin
        case (sel)
            1'b0: y = x0;
            1'b1: y = x1;
            default: y = 12'b0;
        endcase
    end
endmodule
