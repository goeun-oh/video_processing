`timescale 1ns / 1ps

module sobelScale (
    input logic       clk_25MHz,
    input logic       reset,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic [7:0] threshold,
    input logic       display_enable,
    input logic       left_top_enable,
    input logic       right_top_enable,
    input logic       left_bot_enable,
    input logic       right_bot_enable,
    input logic [3:0] gray_4bit_read_0,
    input logic [3:0] gray_4bit_read_1,
    input logic [3:0] gray_4bit_read_2,

    output logic [3:0] sobel_out_5x5_0,        // 4-bit Sobel-filtered output for frame 0, representing edge intensity
    output logic [3:0] sobel_out_5x5_1,       // 4-bit Sobel-filtered output for frame 1, representing edge intensity
    output logic [3:0] sobel_out_5x5_2        // 4-bit Sobel-filtered output for frame 2, representing edge intensity
);

    logic [9:0] x_pixel_filter;         // Adjusted X-coordinate for Sobel filter window, quadrant-specific
    logic [9:0] y_pixel_filter;         // Adjusted Y-coordinate for Sobel filter window, quadrant-specific

    // Coordinate adjustment logic to map VGA pixel coordinates to the appropriate quadrant
    // for consistent filter application across the split-screen display (320x240 per quadrant).
    assign x_pixel_filter = (left_top_enable)  ? x_pixel :                   // Left-top quadrant: direct mapping
        (right_top_enable) ? (x_pixel - 320) :          // Right-top: offset by 320 pixels
        (left_bot_enable) ? x_pixel :  // Left-bottom: direct mapping
        (right_bot_enable) ? (x_pixel - 320) : 10'b0;   // Right-bottom: offset by 320 pixels

    assign y_pixel_filter = (left_top_enable)  ? y_pixel :                   // Left-top: direct mapping
        (right_top_enable) ? y_pixel :  // Right-top: direct mapping
        (left_bot_enable)  ? (y_pixel - 240) :          // Left-bottom: offset by 240 lines
        (right_bot_enable) ? (y_pixel - 240) : 10'b0;   // Right-bottom: offset by 240 lines

    (* DONT_TOUCH = "TRUE" *)
    sobel_filter_5x5 sobel_5x5_0 (
        .clk(clk_25MHz),  // Clock for Sobel processing
        .reset(reset),  // Reset signal
        .gray_4bit_0(gray_4bit_read_0),  // Input grayscale data from frame 0
        .gray_4bit_1(gray_4bit_read_1),  // Input grayscale data from frame 1
        .gray_4bit_2(gray_4bit_read_2),  // Input grayscale data from frame 2
        .x_pixel(x_pixel_filter),  // X-coordinate for filter window
        .y_pixel(y_pixel_filter),  // Y-coordinate for filter window
        .display_enable(display_enable),  // Enable signal for active processing
        .threshold(threshold),  // Edge detection threshold
        .sobel_out_0(sobel_out_5x5_0),  // Filtered output for frame 0
        .sobel_out_1(sobel_out_5x5_1),  // Filtered output for frame 1
        .sobel_out_2(sobel_out_5x5_2)  // Filtered output for frame 2
    );

endmodule
