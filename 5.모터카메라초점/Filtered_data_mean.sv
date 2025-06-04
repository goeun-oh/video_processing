`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/24 10:22:53
// Design Name: 
// Module Name: Filtered_data_mean
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


module Filtered_data_Collector (
    input  logic        clk,
    input  logic        reset,
    input  logic        mean_start,
    input  logic        focus_done,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [ 7:0] filtered_data,
    output logic        mean_done,
    output logic [24:0] wtransdata_sum,
    output logic [14:0] wtransdata_cnt,
    output logic        divide_cmplt
    //output logic [3:0] led
);

    logic [24:0] data_sum;
    logic [14:0] pixel_cnt;
    logic mean_enable;
    logic [3:0] divide_cnt;

    localparam IDLE = 2'b00, DATA_SCAN = 2'b01, MEAN_TRANS = 2'b10, CLR = 2'b11;
    logic [1:0] cstate;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            cstate <= IDLE;
            data_sum <= 0;
            pixel_cnt <= 0;
            mean_done <= 1'b0;
        end else begin
            case (cstate)
                IDLE: begin
                    //led <= 4'b0001;
                    mean_done <= 1'b0;
                    if (mean_start == 1'b1) begin
                        cstate <= DATA_SCAN;
                    end else begin
                        cstate <= IDLE;
                    end
                end

                DATA_SCAN: begin
                    //led <= 4'b0010;
                    mean_done <= 1'b0;
                    if (focus_done == 1'b1) begin
                        cstate <= IDLE;
                    end else begin
                        if (mean_enable == 1'b1) begin
                            if (filtered_data == 8'h0) begin
                                data_sum  <= data_sum;
                                pixel_cnt <= pixel_cnt;
                            end else if (filtered_data == 8'bx) begin
                                data_sum  <= data_sum;
                                pixel_cnt <= pixel_cnt;
                            end else begin
                                data_sum  <= data_sum + filtered_data;
                                pixel_cnt <= pixel_cnt + 1;
                            end
                        end else if ((x_pixel == 320) && (y_pixel == 240)) begin
                            cstate <= MEAN_TRANS;
                        end else begin
                            cstate <= DATA_SCAN;
                        end
                    end
                end

                MEAN_TRANS: begin
                    //led <= 4'b0100;
                    mean_done <= 1'b1;
                    wtransdata_sum <= data_sum;
                    wtransdata_cnt <= pixel_cnt;
                    cstate <= CLR;
                end

                CLR: begin
                    //led <= 4'b1000;
                    data_sum  <= 0;
                    pixel_cnt <= 0;
                    mean_done <= 1'b0;
                    if (focus_done) begin
                        cstate <= IDLE;
                    end else begin
                        if ((x_pixel > 500) && (y_pixel > 500)) begin
                            cstate <= DATA_SCAN;
                        end else begin
                            cstate <= CLR;
                        end
                    end
                end
            endcase
        end
    end

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            mean_enable <= 1'b0;
        end else begin
            if((x_pixel < 240) && (x_pixel >= 80) && (y_pixel >= 60) && (y_pixel <180))begin
                mean_enable <= 1'b1;
            end else begin
                mean_enable <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            divide_cnt   <= 0;
            divide_cmplt <= 1'b0;
        end else begin
            if (mean_done == 1'b1) begin
                divide_cnt <= 1;
            end else begin
                if (divide_cnt != 0) begin
                    if (divide_cnt == 8) begin
                        divide_cnt   <= 0;
                        divide_cmplt <= 1'b1;
                    end else begin
                        divide_cnt   <= divide_cnt + 1;
                        divide_cmplt <= 1'b0;
                    end
                end else begin
                    divide_cmplt <= 1'b0;
                    divide_cnt   <= 0;
                end
            end
        end
    end
endmodule
