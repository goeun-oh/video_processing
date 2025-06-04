`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/25 10:38:32
// Design Name: 
// Module Name: calendar
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


module calendar(
    input logic clk,
    input logic reset,
    input logic tick,               //1hz
    input logic end_of_day,
    output logic [3:0] d_1d,        //day bcd
    output logic [3:0] d_10d,
    output logic [3:0] m_1d,        //month bcd
    output logic [3:0] m_10d,
    output logic [3:0] y_1d,        //year bcd
    output logic [3:0] y_10d,
    output logic [3:0] c_1d,        //century bcd
    output logic [3:0] c_10d
);


    //initial value
    logic  [4:0] r_day;        //31
    logic  [3:0] r_month;      //12
    logic  [6:0] r_year;       //99
    logic  [6:0] r_century;    //99

    logic leap_year;
    logic end_of_year;
    logic end_of_century;
    assign leap_year = (r_year % 4 == 0) ? 1'b1 : 1'b0;
    assign end_of_year = ((r_month == 12 && r_day == 31) & end_of_day) ? 1 : 0;
    assign end_of_century = ((r_year == 99) & end_of_year) ? 1 : 0;

    // day
    always_ff @ (posedge clk, posedge reset) begin
        if(reset) begin
            r_day <= 15;
        end
        else begin
          if(tick) begin
            if(end_of_day) begin
                case(r_month)
                    1 : begin
                        if(r_day == 31) r_day <= 1;
                        else            r_day <= r_day +1;
                    end
                    2 : begin
                        if(~leap_year && r_day == 28) begin
                            r_day <= 1;
                        end
                        else if(leap_year && r_day == 29) begin
                            r_day <= 1;
                        end
                        else begin
                            r_day <= r_day +1;
                        end
                    end
                   3 : begin
                            if(r_day == 31)
                                r_day <= 1;
                            else
                                r_day <= r_day + 1;
                        end
                    4 : begin
                            if(r_day == 30)
                                r_day <= 1;
                            else
                                r_day <= r_day + 1;
                        end
                    5 : begin
                            if(r_day == 31)
                                r_day <= 1;
                            else
                                r_day <= r_day + 1;
                        end
                    6 : begin
                            if(r_day == 30)
                                r_day <= 1;
                            else
                                r_day <= r_day + 1;
                        end
                    7 : begin
                            if(r_day == 31)
                                r_day <= 1;
                            else
                                r_day <= r_day + 1;
                        end
                    8 : begin
                            if(r_day == 31)
                                r_day <= 1;
                            else
                                r_day <= r_day + 1;
                        end
                    9 : begin
                            if(r_day == 30)
                                r_day <= 1;
                            else
                                r_day <= r_day + 1;
                        end
                    10: begin
                            if(r_day == 31)
                                r_day <= 1;
                            else
                                r_day <= r_day + 1;
                        end
                    11: begin
                            if(r_day == 30)
                                r_day <= 1;
                            else
                                r_day <= r_day + 1;
                        end
                    12: begin
                            if(r_day == 31)
                                r_day <= 1;
                            else
                                r_day <= r_day + 1;
                        end
                    default: r_day <= 1;
                endcase
            end
          end
        end
    end


    // month 
    always @(posedge clk or posedge reset) begin
        if(reset)
            r_month <= 4'd3;
        else
            if(tick) begin

            if((r_month == 1 && r_day == 31) & end_of_day)
                r_month <= 2;
            else if((r_month == 2 && r_day == 28) & end_of_day & ~leap_year)
                r_month <= 3;
            else if((r_month == 2 && r_day == 29) & end_of_day & leap_year)
                r_month <= 3;
            else if((r_month == 3 && r_day == 31) & end_of_day)
                r_month <= 4;
            else if((r_month == 4 && r_day == 30) & end_of_day)
                r_month <= 5;
            else if((r_month == 5 && r_day == 31) & end_of_day)
                r_month <= 6;
            else if((r_month == 6 && r_day == 30) & end_of_day)
                r_month <= 7;
            else if((r_month == 7 && r_day == 31) & end_of_day)
                r_month <= 8;
            else if((r_month == 8 && r_day == 31) & end_of_day)
                r_month <= 9;
            else if((r_month == 9 && r_day == 30) & end_of_day)
                r_month <= 10;
            else if((r_month == 10 && r_day == 31) & end_of_day)
                r_month <= 11;
            else if((r_month == 11 && r_day == 30) & end_of_day)
                r_month <= 12;
            else if(end_of_year & end_of_day)
                r_month <= 1;
            end
    end

    // year 
    always_ff @(posedge clk , posedge reset) begin
        if(reset) begin
            r_year <= 24;
        end
        else begin
          if(tick) begin
            if(end_of_year) begin
                if(r_year == 99)
                    r_year <= 0;
                else
                    r_year <= r_year + 1;
            end
          end
        end
    end


    // century
    always_ff @(posedge clk , posedge reset) begin
        if(reset) begin
            r_century <= 20;
        end
        else begin
          if(tick) begin
            if(end_of_century) begin
                if(r_century == 99)
                    r_century <= 0;
                else
                    r_century <= r_century + 1;
            end
          end
        end
    end


    //convert calendar values to bcd
    assign d_1d  = r_day % 10;
    assign d_10d = r_day / 10;
    assign m_1d  = r_month % 10;
    assign m_10d = r_month / 10;
    assign y_1d  = r_year % 10;
    assign y_10d = r_year / 10;
    assign c_1d  = r_century % 10;
    assign c_10d = r_century / 10;


endmodule
