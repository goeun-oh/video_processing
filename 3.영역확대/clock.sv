`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/25 09:30:45
// Design Name: 
// Module Name: clock
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


module clock(
        input logic clk,
        input logic reset,
        input logic tick,
        output logic am_pm,
        output logic end_of_day,
        output logic [3:0] sec_1d,
        output logic [3:0] sec_10d,
        output logic [3:0] min_1d,
        output logic [3:0] min_10d,
        output logic [3:0] hour_1d,
        output logic [3:0] hour_10d
);

        // initial value
        reg [5:0] r_second = 0;
        reg [5:0] r_min =0 ;
        reg [5:0] r_hour = 12;       
        reg       r_am_pm;      // am = 0, pm = 1

        wire switch_am_pm;


        assign switch_am_pm = ((r_hour == 11) && (r_min == 59) && (r_second == 59)) ? 1 : 0;      
        assign end_of_day =  ((r_hour == 11) && (r_min == 59) && (r_second == 59) && (r_am_pm == 1)) ? 1 : 0;
        assign am_pm = r_am_pm;




        // second
        always_ff @ (posedge clk, posedge reset) begin
            if(reset) begin
                r_second <= 0;
            end
            else begin
              if(tick) begin
                if(r_second == 59) r_second <= 0;
                else               r_second <= r_second +1;
              end       
            end
        end

        // min
        always_ff @ (posedge clk, posedge reset) begin
            if(reset) begin
                r_min <= 0;
            end
            else begin
              if(tick) begin
                if(r_second == 59) begin
                    if(r_min == 59) r_min <= 0;
                    else             r_min <= r_min +1;
                end
              end       
            end
        end


        // hour
        always_ff @ (posedge clk, posedge reset) begin
            if(reset) begin
                r_hour <= 0;
            end
            else begin
              if(tick) begin
                if(r_min == 59 && r_second == 59) begin
                    if(r_hour == 12)  r_hour <= 1;
                    else              r_hour <= r_hour +1;
                end
              end       
            end
        end

        // am_pm
        always_ff @ (posedge clk, posedge reset) begin
            if(reset) begin
                r_am_pm <= 0;       
            end
            else begin
                if(switch_am_pm) begin
                    r_am_pm <= ~r_am_pm;
                end
            end
        end


        // convert binary value to output bcd value
        assign sec_1d  = r_second % 10;
        assign sec_10d = r_second / 10;
        assign min_1d  = r_min    % 10;
        assign min_10d = r_min    / 10;
        assign hour_1d   = r_hour   % 10; 
        assign hour_10d  = r_hour   / 10;



endmodule
