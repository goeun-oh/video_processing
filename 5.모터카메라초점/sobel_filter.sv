`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/21 19:00:09
// Design Name: 
// Module Name: sobel_filter
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


module sobel_filter(
    input logic clk_25MHz,
    input logic reset,
    input logic sobel_en,
    input logic [9:0] x_pixel,
    input logic [9:0] w_x_pixel,
    input logic [9:0] y_pixel,
    input logic [7:0] gray,
    output logic [3:0] sobel_filtered_data,
    output logic [10:0] integrated_data
    );

    //logic [8:0] kernel_locator;
    logic [10:0] x_filtered_data;
    logic [10:0] y_filtered_data;

    logic [7:0] reg0[0 : 319];
    logic [7:0] reg1[0 : 319];
    logic [7:0] reg2[0 : 319];
    logic [7:0] reg3[0 : 319];

    always_comb begin
        if(y_pixel == 0)begin
            sobel_filtered_data = 4'b0;
        end
        else if(y_pixel == 239)begin
            sobel_filtered_data = 4'b0;
        end
        else if(x_pixel == 0)begin
            sobel_filtered_data = 4'b0;
        end
        else if(x_pixel == 319)begin
            sobel_filtered_data = 4'b0;
        end
        else begin
            if(integrated_data > 200)begin
                sobel_filtered_data = 4'hf;
            end
            else begin
                sobel_filtered_data = 4'h0;
            end
        end
    end

    always_ff @( posedge clk_25MHz ) begin
        if(sobel_en)begin
            reg3[w_x_pixel] <= gray;
        end
    end

    always_ff @( posedge clk_25MHz ) begin 
        if(sobel_en)begin
            reg0[w_x_pixel] <= reg1[w_x_pixel];
            reg1[w_x_pixel] <= reg2[w_x_pixel];
            reg2[w_x_pixel] <= reg3[w_x_pixel];
        end
    end

    sobel_y_kernel U_VERTICAL(
        .reg0_data_0(reg0[x_pixel]), 
        .reg0_data_2(reg0[x_pixel+2]), 
        .reg1_data_0(reg1[x_pixel]),
        .reg1_data_2(reg1[x_pixel+2]),
        .reg2_data_0(reg2[x_pixel]),
        .reg2_data_2(reg2[x_pixel+2]),
        .y_filtered_data(y_filtered_data)
    );

    sobel_x_kernel U_HORIZONTAL(
        .reg0_data_0(reg0[x_pixel]),
        .reg0_data_1(reg0[x_pixel+1]),
        .reg0_data_2(reg0[x_pixel+2]),
        .reg1_data_0(reg1[x_pixel]),
        .reg1_data_1(reg1[x_pixel+1]),
        .reg1_data_2(reg1[x_pixel+2]),
        .reg2_data_0(reg2[x_pixel]),
        .reg2_data_1(reg2[x_pixel+1]),
        .reg2_data_2(reg2[x_pixel+2]),
        .x_filtered_data(x_filtered_data)
    );

    X_Y_Integrator U_INTEGRATOR(
        .x_filtered_data(x_filtered_data),
        .y_filtered_data(y_filtered_data),
        .integrated_data(integrated_data)
    );

endmodule

module sobel_y_kernel(
    input logic [7:0] reg0_data_0,
    input logic [7:0] reg0_data_2,
    input logic [7:0] reg1_data_0,
    input logic [7:0] reg1_data_2,
    input logic [7:0] reg2_data_0,
    input logic [7:0] reg2_data_2,
    output logic signed [10:0] y_filtered_data
);

    assign y_filtered_data = reg0_data_2 - reg0_data_0 + (reg1_data_2 * 2) - (reg1_data_0 * 2) + reg2_data_2 - reg2_data_0;

endmodule

module sobel_x_kernel(
    input logic [7:0] reg0_data_0,
    input logic [7:0] reg0_data_1,
    input logic [7:0] reg0_data_2,
    input logic [7:0] reg1_data_0,
    input logic [7:0] reg1_data_1,
    input logic [7:0] reg1_data_2,
    input logic [7:0] reg2_data_0,
    input logic [7:0] reg2_data_1,
    input logic [7:0] reg2_data_2,
    output logic signed [10:0] x_filtered_data
);

    assign x_filtered_data = reg0_data_2 + (reg0_data_1 * 2) + reg0_data_0 - reg2_data_2 - (reg2_data_1 * 2) - reg2_data_0;

endmodule

module X_Y_Integrator(
    input logic signed [10:0] x_filtered_data,
    input logic signed [10:0] y_filtered_data,
    output logic signed [10:0] integrated_data
);
    logic [10:0] Gx, Gy;
    //logic signed [10:0] max;
    //logic signed [10:0] min;

    assign Gx = (x_filtered_data < 0) ? -x_filtered_data : x_filtered_data;
    assign Gy = (y_filtered_data < 0) ? -y_filtered_data : y_filtered_data;
    //assign max = (x_filtered_data > y_filtered_data) ? x_filtered_data : y_filtered_data;
    //assign min = (x_filtered_data > y_filtered_data) ? y_filtered_data : x_filtered_data;
    assign integrated_data = Gx + Gy;
endmodule
