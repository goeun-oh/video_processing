`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/25 12:50:22
// Design Name: 
// Module Name: rgb2gray
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


module rgb2gray (
    input  logic [11:0] color_rgb,
    output logic [11:0] gray_rbg
);
    localparam RW = 8'h47;  // weight for red
    localparam GW = 8'h96;  // weight for green
    localparam BW = 8'h1D;  // weight for blue

    logic [3:0] r, g, b, gray;
    logic [11:0] gray12;

    assign r = color_rgb[11:8];
    assign g = color_rgb[7:4];
    assign b = color_rgb[3:0];
    assign gray12 = r * RW + g * GW + b * BW;
    assign gray = gray12[11:8];
    assign gray_rbg = {gray, gray, gray};

endmodule