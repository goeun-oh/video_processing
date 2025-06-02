`timescale 1ns / 1ps

module frame_diff_counter (
    input logic clk_25MHz,
    input logic reset,
    input logic frame_done,  // Signal indicating completion of a frame.
    input logic [3:0] sobel_out_5x5_0,
    input logic [3:0] sobel_out_5x5_1,
    input logic [3:0] sobel_out_5x5_2,
    output logic [3:0] diff_pixel,  // 4-bit pixel value indicating difference
    output logic [$clog2(320 * 240) - 1 : 0] diff_pixel_cnt  // Counter for differing pixels
);

    // STEP 7: Frame-to-Frame Difference Detection
    // Compares consecutive Sobel-filtered frames to detect changes.
    logic diff_detected_0;  // Difference detected between frames 0 and 1
    logic diff_detected_1;  // Difference detected between frames 1 and 2

    diff_detector_pixel U_DIFF_DETECTOR_0 (
        .prev_pixel(sobel_out_5x5_0),  // Previous frame pixel (frame 0)
        .curr_pixel(sobel_out_5x5_1),  // Current frame pixel (frame 1)
        .diff_detected(diff_detected_0)  // Difference detection output
    );
    diff_detector_pixel U_DIFF_DETECTOR_1 (
        .prev_pixel(sobel_out_5x5_1),  // Previous frame pixel (frame 1)
        .curr_pixel(sobel_out_5x5_2),  // Current frame pixel (frame 2)
        .diff_detected(diff_detected_1)  // Difference detection output
    );

    // STEP 8: Aggregate Frame Differences for Robust Motion Detection
    // Combines difference signals and counts differing pixels across frames.

    assign diff_detected = (diff_detected_0 && diff_detected_1); // Require both comparisons to confirm difference
    assign diff_pixel = (diff_detected) ? 4'hf : 4'h0; // Set to max (white) if difference detected, else black

    diff_pixel_counter U_DIFF_PIXEL_COUNTER (
        .clk(clk_25MHz),  // Clock for counting differences
        .reset(reset),  // Reset signal
        .frame_done(frame_done),  // Frame completion signal to reset counter
        .diff_detected(diff_detected),  // Input difference signal
        .diff_pixel_cnt(diff_pixel_cnt)  // Output count of differing pixels
    );
endmodule
