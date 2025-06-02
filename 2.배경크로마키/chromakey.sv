`timescale 1ns / 1ps

module chromakey (
    input  logic        clk_25MHz,
    input  logic        reset,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [11:0] pixel_in,
    output logic        color_Diff,
    output logic [ 1:0] dominant_color
);


    color_detector U_color_detector (
        .clk           (clk_25MHz),
        .reset         (reset),
        .pixel_in      (pixel_in),
        .x_pixel       (x_pixel),
        .y_pixel       (y_pixel),
        .dominant_color(dominant_color)
    );

    dominant_color_chroma_key U_dominant_color_chroma_key (
        .dominant_color(dominant_color),
        .pixel_in      (pixel_in),
        .color_Diff    (color_Diff)
    );

endmodule




module color_detector (
    input logic clk,
    input logic reset,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic [11:0] pixel_in,
    output logic [1:0] dominant_color
);
    logic frame_done;
    logic [21:0] sum_r, sum_g, sum_b;
    localparam margin = 500, margin_GB = 300;

    assign frame_done = (x_pixel == 639) && (y_pixel == 479);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sum_r <= 0;
            sum_g <= 0;
            sum_b <= 0;
            dominant_color <= 2'b00;
        end else begin
            if (frame_done) begin
                if ((sum_r > (sum_g + margin)) && (sum_r > (sum_b+ margin)) && (sum_r > 20'h10000)) begin
                    dominant_color <= 2'b01;
                end else if ((sum_g > (sum_r + margin_GB)) && (sum_g > (sum_b + margin_GB)) && (sum_g > 20'h10000)) begin
                    dominant_color <= 2'b10;
                end else if ((sum_b > (sum_r + margin_GB)) && (sum_b > (sum_g + margin_GB)) && (sum_b > 20'h10000)) begin
                    dominant_color <= 2'b11;
                end else begin
                    dominant_color <= 2'b00;
                end
                sum_r <= 0;
                sum_g <= 0;
                sum_b <= 0;
            end else begin
                sum_r <= sum_r + pixel_in[11:8];
                sum_g <= sum_g + pixel_in[7:4];
                sum_b <= sum_b + pixel_in[3:0];
            end
        end
    end
endmodule


module dominant_color_chroma_key (
    input  logic [ 1:0] dominant_color,
    input  logic [11:0] pixel_in,
    output logic        color_Diff
);

    localparam margin_red = 5;
    localparam margin_green = 2;
    localparam margin_blue = 3;

    logic [3:0] red, green, blue;
    assign red   = pixel_in[11:8];
    assign green = pixel_in[7:4];
    assign blue  = pixel_in[3:0];

    always_comb begin
        color_Diff = 1'b0;
        case (dominant_color)
            2'b01: begin
                if ((red >= green + margin_red) && (red >= blue + margin_red) && (red >= 4'd10)) begin
                    color_Diff = 1'b1;
                end else begin
                    color_Diff = 1'b0;
                end
            end

            2'b10: begin
                if ((green >= red + margin_green) && (green >= blue + margin_green) && green >= 4'd5) begin
                    color_Diff = 1'b1;
                end else begin
                    color_Diff = 1'b0;
                end
            end

            2'b11: begin
                if ((blue >= red + margin_blue) && (blue >= green + margin_blue ) && (blue >= 4'd8)) begin
                    color_Diff = 1'b1;
                end else begin
                    color_Diff = 1'b0;
                end
            end
            2'b00: begin
                color_Diff = 1'b0;
            end
        endcase
    end

endmodule

