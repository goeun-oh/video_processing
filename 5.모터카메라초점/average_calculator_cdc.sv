`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/28 17:22:03
// Design Name: 
// Module Name: average_calculator_cdc
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


module average_calculator_cdc (
    input logic clk_25MHz,
    input logic clk_12_5MHz,  // 12.5MHz 
    input logic reset,
    input logic addcount_done,
    input logic [24:0] wtransdata_sum,
    input logic [14:0] wtransdata_cnt,
    output logic [7:0] avg_data
);

    logic [24:0] rtransdata_sum;
    logic [14:0] rtransdata_cnt;
    logic [7:0] whole_frame_avg;

    CDC_Buffer U_CDC_Buffer (
        //write
        .clk_25MHz(clk_25MHz),
        .wtransdata_sum(wtransdata_sum),
        .wtransdata_cnt(wtransdata_cnt),
        .addcount_done(addcount_done),

        //read
        .clk_12_5MHz(clk_12_5MHz),
        .rtransdata_sum(rtransdata_sum),
        .rtransdata_cnt(rtransdata_cnt),

        //mean flag
        .whole_frame_avg(whole_frame_avg),
        .avg_data(avg_data)
    );

    output_Filtered_data U_average_cal (
        .clk_12_5MHz(clk_12_5MHz),
        .reset(reset),
        .transdata_sum(rtransdata_sum),
        .transdata_cnt(rtransdata_cnt),
        .whole_frame_avg(whole_frame_avg)
    );
endmodule


module CDC_Buffer (
    //write
    input logic        clk_25MHz,
    input logic [24:0] wtransdata_sum,
    input logic [14:0] wtransdata_cnt,
    input logic        addcount_done,

    //read
    input  logic        clk_12_5MHz,
    output logic [24:0] rtransdata_sum,
    output logic [14:0] rtransdata_cnt,

    //mean flag
    input logic [7:0] whole_frame_avg,
    output logic [7:0] avg_data
);

    logic [24:0] mem_sum;
    logic [14:0] mem_cnt;
    logic [ 7:0] avg_data_reg;


    //write side
    always_ff @(posedge clk_25MHz) begin
        avg_data <= avg_data_reg;
        if (addcount_done) begin
            mem_sum <= wtransdata_sum;
            mem_cnt <= wtransdata_cnt;
        end
    end

    //read side
    always_ff @(posedge clk_12_5MHz) begin
        rtransdata_sum <= mem_sum;
        rtransdata_cnt <= mem_cnt;
        avg_data_reg <= whole_frame_avg;
    end

endmodule




module output_Filtered_data (
    input  logic        clk_12_5MHz,
    input  logic        reset,
    input  logic [24:0] transdata_sum,
    input  logic [14:0] transdata_cnt,
    output logic [ 7:0] whole_frame_avg
);

    always_ff @(posedge clk_12_5MHz, posedge reset) begin
        if (reset) begin
            whole_frame_avg <= 0;
        end else begin
            if(transdata_cnt == 0)begin
                whole_frame_avg <= 0;
            end
            else begin
                whole_frame_avg <= transdata_sum / transdata_cnt;
            end
        end
    end
endmodule
