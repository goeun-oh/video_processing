`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/24 13:12:30
// Design Name: 
// Module Name: max_mean_capture
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


module max_avg_capture(
    input logic clk_25MHz,
    input logic reset,
    input logic start,
    input logic [7:0] average,  // [11:0] gray_Data, gray_Data[3:0]
    input logic scan_done,
    output logic buzzer_trig,
    output logic [$clog2(250000000)-1 : 0] counter_rotate_time,
    output logic [3:0] led
    );

    typedef enum  {IDLE, COMPARE, STAY, DONE} states;

    states cstate;

    logic [7:0] current_avg;
    logic [7:0] max_avg;
    logic neg_slope;
    logic equal;
    logic clr;

    assign neg_slope = ((max_avg > current_avg)) ? 1'b1 : 1'b0;
    assign equal = (max_avg == current_avg) ? 1'b1 : 1'b0;

    always_ff @( posedge clk_25MHz, posedge reset ) begin
        if(reset)begin
            counter_rotate_time <= 0;
        end
        else begin
            if(clr == 1'b1)begin
                counter_rotate_time <= 0;
            end
            else if(cstate == DONE)begin
                counter_rotate_time <= counter_rotate_time;
            end
            else if(cstate == IDLE)begin
                counter_rotate_time <= 0;
            end
            else begin
                counter_rotate_time <= counter_rotate_time + 1;
            end
        end
    end

    always_ff @( posedge clk_25MHz, posedge reset ) begin
        if(reset)begin
            current_avg <= 0;
            cstate <= IDLE;
            buzzer_trig <= 1'b0;
            max_avg <= 0;
            clr <= 1'b0;
        end
        else begin
            case(cstate)
            IDLE : begin
                led <= 4'b0001;
                buzzer_trig <= 1'b0;
                if(start)begin
                    cstate <= COMPARE;
                    current_avg <= average;
                end
                else begin
                    cstate <= IDLE;
                end
            end

            COMPARE : begin
                led <= 4'b0010;
                if(scan_done == 1'b1)begin
                    cstate <= DONE;
                end
                else begin
                    if(neg_slope == 1'b1)begin
                        cstate <= STAY;
                    end
                    else if(equal == 1'b1)begin
                        cstate <= STAY;
                    end
                    else begin
                        cstate <= STAY;
                        max_avg <= current_avg;
                        clr <= 1'b1;
                    end
                end
            end

            STAY : begin
                led <= 4'b0100;
                max_avg <= max_avg;
                clr <= 1'b0;
                current_avg <= current_avg;
                if(scan_done)begin
                    cstate <= DONE;
                end else begin
                    if(start)begin
                        cstate <= COMPARE;
                        current_avg <= average;
                    end
                end
            end

            DONE : begin
                led <= 4'b1000;
                buzzer_trig <= 1'b1;
                cstate <= IDLE;
                max_avg <= 0;
                current_avg <= 0;
            end
            endcase
        end
    end
endmodule


