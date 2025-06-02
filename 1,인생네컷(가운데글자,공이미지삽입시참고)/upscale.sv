`timescale 1ns / 1ps


module upscaler_interpolation (
    input  logic        clk_25MHz,
    input  logic        reset,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [11:0] final_data,
    output logic [11:0] up_scale_data
);

    logic [3:0] red, green, blue;

    logic [11:0] buffer[0:319];
    logic [11:0] buffer_prev[0:319];
    logic [11:0] final_data_prev;

    logic [5:0] r_sum, g_sum, b_sum;

    integer i;

    always_ff @(posedge clk_25MHz, posedge reset) begin
        if (reset) begin
            final_data_prev <= 0;
            buffer          <= '{default: 0};
            buffer_prev     <= '{default: 0};
        end else begin
            final_data_prev <= final_data;
            if (x_pixel < 320) begin
                buffer[x_pixel]      <= final_data;
                buffer_prev[x_pixel] <= buffer[x_pixel];
            end
        end
    end

    always_comb begin
        if (x_pixel < 320 && y_pixel < 240) begin
            r_sum = final_data[11:8] + final_data_prev[11:8] + buffer[x_pixel][11:8] + buffer_prev[x_pixel][11:8];
            g_sum = final_data[7:4]  + final_data_prev[7:4]  + buffer[x_pixel][7:4]  + buffer_prev[x_pixel][7:4];
            b_sum = final_data[3:0]  + final_data_prev[3:0]  + buffer[x_pixel][3:0]  + buffer_prev[x_pixel][3:0];
            red = r_sum >> 2;
            green = g_sum >> 2;
            blue = b_sum >> 2;
            up_scale_data = {red, green, blue};
        end else begin
            up_scale_data = final_data;
        end
    end
endmodule
