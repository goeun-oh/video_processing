`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/25 09:23:05
// Design Name: 
// Module Name: character_digit_display
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

`define MAIN;

module clock_calendar(
    input logic         clk,
    input logic         reset,
    // clock
    output logic       am_pm,
    output logic [3:0] sec_1d,
    output logic [3:0] sec_10d,
    output logic [3:0] min_1d,
    output logic [3:0] min_10d,
    output logic [3:0] hour_1d,
    output logic [3:0] hour_10d,
    // calendar
    output logic [3:0] d_1d,
    output logic [3:0] d_10d,
    output logic [3:0] m_1d,
    output logic [3:0] m_10d,
    output logic [3:0] y_1d,
    output logic [3:0] y_10d,
    output logic [3:0] c_1d,
    output logic [3:0] c_10d
);

    `ifdef MAIN
    parameter TICK_HZ = 100_000_000;
    `else   // SIM
    parameter TICK_HZ = 1;
    `endif


    logic tick_1hz;
    //logic am_pm;
    logic end_of_day;
    //logic [3:0] sec_1d;
    //logic [3:0] sec_10d;
    //logic [3:0] min_1d;
    //logic [3:0] min_10d;
    //logic [3:0] hour_1d;
    //logic [3:0] hour_10d;



    // ------ 1hz tick generation ------- //
        tick_gen #(
            .TICK_HZ(TICK_HZ)
        ) u_tick_gen(
            .clk(clk),
            .reset(reset),
            .tick(tick_1hz)
        );

    // ---------- clock ----------------- //
    clock u_clock(
        .clk(clk),
        .reset(reset),
        .tick(tick_1hz),
        .am_pm(am_pm),
        .end_of_day(end_of_day),
        .sec_1d(sec_1d),
        .sec_10d(sec_10d),
        .min_1d(min_1d),
        .min_10d(min_10d),
        .hour_1d(hour_1d),
        .hour_10d(hour_10d)
    );

    // --------- calendar ----------------//
    calendar u_calendar(
        .clk(clk),
        .reset(reset),
        .tick(tick_1hz),               
        .end_of_day(end_of_day),
        .d_1d(d_1d),        
        .d_10d(d_10d),
        .m_1d(m_1d),        
        .m_10d(m_10d),
        .y_1d(y_1d),        
        .y_10d(y_10d),
        .c_1d(c_1d),        
        .c_10d(c_10d)
    );


endmodule
