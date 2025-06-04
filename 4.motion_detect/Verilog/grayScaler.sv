`timescale 1ns / 1ps

module grayScaler (
    input logic [11:0] upscaled_image0,
    input logic [11:0] upscaled_image1,
    input logic [11:0] upscaled_image2,
    output logic [3:0] gray_4bit_read_0,
    output logic [3:0] gray_4bit_read_1,
    output logic [3:0] gray_4bit_read_2
);

    rgb2gray U_RGB2GRAY0 (
        .color_rgb (upscaled_image0),   // Input 12-bit RGB data
        .gray_4bit (gray_4bit_read_0),  // Output 4-bit grayscale data
        .gray_8bit (),                  // Unused 8-bit grayscale output
        .gray_12bit()                   // Unused 12-bit grayscale output
    );

    rgb2gray U_RGB2GRAY1 (
        .color_rgb (upscaled_image1),   // Input 12-bit RGB data
        .gray_4bit (gray_4bit_read_1),  // Output 4-bit grayscale data
        .gray_8bit (),                  // Unused 8-bit grayscale output
        .gray_12bit()                   // Unused 12-bit grayscale output
    );

    rgb2gray U_RGB2GRAY2 (
        .color_rgb (upscaled_image2),   // Input 12-bit RGB data
        .gray_4bit (gray_4bit_read_2),  // Output 4-bit grayscale data
        .gray_8bit (),                  // Unused 8-bit grayscale output
        .gray_12bit()                   // Unused 12-bit grayscale output
    );
    
endmodule
