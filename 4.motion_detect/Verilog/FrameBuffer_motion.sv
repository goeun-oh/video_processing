
module FrameBuffer_motion (
    input  logic        clk_25MHz,
    input  logic        pclk,
    input  logic        reset,
    input  logic        vref,
    input  logic        pixel_we,
    input  logic        display_enable,
    input  logic [11:0] ov7670_image,
    input  logic [16:0] wAddr,
    input  logic [16:0] rAddr,
    output logic        frame_done,
    output logic [11:0] stored_image0,
    output logic [11:0] stored_image1,
    output logic [11:0] stored_image2
);
    logic [1:0] frame_count;  // 2-bit counter for tracking frame sequence


    frame_counter U_FRAME_COUNTER (
        .clk        (pclk),         // Pixel clock for frame counting
        .reset      (reset),        // Reset to initialize frame counter
        .vref       (vref),         // Vertical sync to detect frame boundaries
        .frame_count(frame_count),  // Current frame index (0, 1, 2)
        .frame_done (frame_done)    // Frame completion flag
    );

    frameBuffer U_FrameBuffer0 (
        .wclk (pclk),
        .we   (pixel_we && frame_count == 0),
        .wAddr(wAddr),
        .wData(ov7670_image),
        .rclk (clk_25MHz),
        .oe   (display_enable),
        .rAddr(rAddr),
        .rData(stored_image0)
    );

    frameBuffer U_FrameBuffer1 (
        .wclk (pclk),
        .we   (pixel_we && frame_count == 1),
        .wAddr(wAddr),
        .wData(ov7670_image),
        .rclk (clk_25MHz),
        .oe   (display_enable),
        .rAddr(rAddr),
        .rData(stored_image1)
    );

    frameBuffer U_FrameBuffer2 (
        .wclk (pclk),
        .we   (pixel_we && frame_count == 2),
        .wAddr(wAddr),
        .wData(ov7670_image),
        .rclk (clk_25MHz),
        .oe   (display_enable),
        .rAddr(rAddr),
        .rData(stored_image2)
    );
endmodule
