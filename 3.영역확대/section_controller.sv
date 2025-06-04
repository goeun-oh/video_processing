`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/25 13:02:36
// Design Name: 
// Module Name: section_controller
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


module section_controller(
    input logic       clk,
    input logic       reset,
    input logic       display_en,
    input logic [9:0] x,
    input logic [9:0] y,
    input logic [3:0] sec_1d, sec_10d,
    input logic [3:0] min_1d, min_10d,
    input logic [3:0] hour_1d, hour_10d,
    input             am_pm,
    input logic [3:0] m_10d, m_1d,
    input logic [3:0] d_10d, d_1d,
    input logic [3:0] y_10d, y_1d,
    input logic [3:0] c_10d, c_1d,
    output logic OV7670_CAM1_on,
    output logic OV7670_CAM2_on,
    output logic [3:0] red,
    output logic [3:0] green,
    output logic [3:0] blue
);

    logic [11:0] rgb;

    assign red = rgb[11:8];
    assign green = rgb[7:4];
    assign blue = rgb[3:0];


// ----------------- CLOCK & CALENDAR----------------------------- //
    // Hour 10s Digit section = 8 x 16         
    localparam H10_X_L = 559 - 24;                    
    localparam H10_X_R = 566 - 24;                    
    localparam H10_Y_T = 431;                    
    localparam H10_Y_B = 446;              

    // Hour 1s Digit section = 8 x 16          
    localparam H1_X_L = 567 - 24;                    
    localparam H1_X_R = 574 - 24;                    
    localparam H1_Y_T = 431;                    
    localparam H1_Y_B = 446;                    

    // Colon 1 section = 8 x 16                
    localparam C1_X_L = 575 - 24;                    
    localparam C1_X_R = 582 - 24;                    
    localparam C1_Y_T = 431;                    
    localparam C1_Y_B = 446;                    

    // Minute 10s Digit section = 8 x 16       
    localparam M10_X_L = 583 - 24;                   
    localparam M10_X_R = 590 - 24;                   
    localparam M10_Y_T = 431;                   
    localparam M10_Y_B = 446;                   

    // Minute 1s Digit section = 8 x 16    34    
    localparam M1_X_L = 591 - 24;                    
    localparam M1_X_R = 598 - 24;                    
    localparam M1_Y_T = 431;                    
    localparam M1_Y_B = 446;                    

    // Colon 2 section = 8 x 16                
    localparam C2_X_L = 599 - 24;                    
    localparam C2_X_R = 606 - 24;                    
    localparam C2_Y_T = 431;                    
    localparam C2_Y_B = 446;                    

    // Second 10s Digit section = 8 x 16       
    localparam S10_X_L = 607 - 24;                   
    localparam S10_X_R = 614 - 24;                   
    localparam S10_Y_T = 431;                   
    localparam S10_Y_B = 446;                   

    // Second 1s Digit section = 8 x 16        
    localparam S1_X_L = 615 - 24;                    
    localparam S1_X_R = 622 - 24;                   
    localparam S1_Y_T = 431;                    
    localparam S1_Y_B = 446;                    

    // A or P Digit section = 8 x 16           
    localparam AP_X_L = 623 - 24;                    
    localparam AP_X_R = 630 - 24;                    
    localparam AP_Y_T = 431;                    
    localparam AP_Y_B = 446;                    

    // M Digit section = 8 x 16                
    localparam APM_X_L = 631 - 24;                   
    localparam APM_X_R = 638 - 24;                   
    localparam APM_Y_T = 431;                   
    localparam APM_Y_B = 446;                    


    // Month 10s Digit section = 8 x 16
    localparam Mo10_X_L = 559 - 24;
    localparam Mo10_X_R = 566 - 24;
    localparam Mo10_Y_T = 447;
    localparam Mo10_Y_B = 462;

    // Month 1s Digit section = 8 x 16
    localparam Mo1_X_L = 567 - 24;
    localparam Mo1_X_R = 574 - 24;
    localparam Mo1_Y_T = 447;
    localparam Mo1_Y_B = 462;

    // Period 1 section = 8 x 16
    localparam P1_X_L = 575 - 24;
    localparam P1_X_R = 582 - 24;
    localparam P1_Y_T = 447;
    localparam P1_Y_B = 462;

    // Day 10s Digit section = 8 x 16
    localparam D10_X_L = 583 - 24;
    localparam D10_X_R = 590 - 24;
    localparam D10_Y_T = 447;
    localparam D10_Y_B = 462;

    // Day 1s Digit section = 8 x 16
    localparam D1_X_L = 591 - 24;
    localparam D1_X_R = 598 - 24;
    localparam D1_Y_T = 447;
    localparam D1_Y_B = 462;

    // Period 2 section = 8 x 16
    localparam P2_X_L = 599 - 24;
    localparam P2_X_R = 606 - 24;
    localparam P2_Y_T = 447;
    localparam P2_Y_B = 462;

    // Century 10s Digit section = 8 x 16
    localparam Ce10_X_L = 607 - 24;
    localparam Ce10_X_R = 614 - 24;
    localparam Ce10_Y_T = 447;
    localparam Ce10_Y_B = 462;

    // Century 1s Digit section = 8 x 16
    localparam Ce1_X_L = 615 - 24;
    localparam Ce1_X_R = 622 - 24;
    localparam Ce1_Y_T = 447;
    localparam Ce1_Y_B = 462;

    // Year 10s Digit section = 8 x 16
    localparam Y10_X_L = 623 - 24;
    localparam Y10_X_R = 630 - 24;
    localparam Y10_Y_T = 447;
    localparam Y10_Y_B = 462;

    // Year 1s Digit section = 8 x 16
    localparam Y1_X_L = 631 - 24;
    localparam Y1_X_R = 638 - 24;
    localparam Y1_Y_T = 447;
    localparam Y1_Y_B = 462;


    // ----------------- CHARATER ----------------------------- //
    // CAM1 'C' section = 32 x 64
    localparam CAM1_C_X_L = 96;
    localparam CAM1_C_X_R = 127;
    localparam CAM1_C_Y_T = 0;
    localparam CAM1_C_Y_B = 63;

    // CAM1 'A' section = 32 x 64
    localparam CAM1_A_X_L = 128;
    localparam CAM1_A_X_R = 159;
    localparam CAM1_A_Y_T = 0;
    localparam CAM1_A_Y_B = 63;

    // CAM1 'M' section = 32 x 64
    localparam CAM1_M_X_L = 160;
    localparam CAM1_M_X_R = 191;
    localparam CAM1_M_Y_T = 0;
    localparam CAM1_M_Y_B = 63;


    // CAM1 '1' section = 32 x 64
    localparam CAM1_1_X_L = 192;
    localparam CAM1_1_X_R = 223;
    localparam CAM1_1_Y_T = 0;
    localparam CAM1_1_Y_B = 63;

    // CAM2 'C' section = 32 x 64
    localparam CAM2_C_X_L = 416;
    localparam CAM2_C_X_R = 447;
    localparam CAM2_C_Y_T = 0;
    localparam CAM2_C_Y_B = 63;

    // CAM2 'A' section = 32 x 64
    localparam CAM2_A_X_L = 448;
    localparam CAM2_A_X_R = 479;
    localparam CAM2_A_Y_T = 0;
    localparam CAM2_A_Y_B = 63;

    // CAM2 'M' section = 32 x 64
    localparam CAM2_M_X_L = 480;
    localparam CAM2_M_X_R = 511;
    localparam CAM2_M_Y_T = 0;
    localparam CAM2_M_Y_B = 63;

    // CAM2 'M' section = 32 x 64
    localparam CAM2_2_X_L = 512;
    localparam CAM2_2_X_R = 543;
    localparam CAM2_2_Y_T = 0;
    localparam CAM2_2_Y_B = 63;



    // ----------------- OCV7670 ----------------------------- //
    localparam OCV7670_CAM1_L = 0;
    localparam OCV7670_CAM1_R = 319;
    localparam OCV7670_CAM1_T = 120;
    localparam OCV7670_CAM1_B = 359;

    localparam OCV7670_CAM2_L = 320;
    localparam OCV7670_CAM2_R = 639;
    localparam OCV7670_CAM2_T = 120;
    localparam OCV7670_CAM2_B = 359;



    // Clock Status
    logic H10_on, H1_on, C1_on, M10_on, M1_on, C2_on, S10_on, S1_on, AP_on, APM_on;
    // Calendar Status
    logic Mo10_on, Mo1_on, P1_on, D10_on, D1_on, P2_on, Ce10_on, Ce1_on, Y10_on, Y1_on;
    // Charater Status
    logic CAM1_C_on;
    logic CAM1_A_on;
    logic CAM1_M_on;
    logic CAM1_1_on;
    logic CAM2_C_on;                     
    logic CAM2_A_on;                          
    logic CAM2_M_on;                  
    logic CAM2_1_on;
    // OV7670 CAM Status;
    //logic OV7670_CAM1_on;
    //logic OV7670_CAM2_on;
    
    // ROM Interface Signals
    logic [10:0] rom_addr;
    logic [6:0] char_addr;   // 3'b011 + BCD value of time component
    logic [6:0] char_addr_h10, char_addr_h1, char_addr_m10, char_addr_m1, char_addr_s10, char_addr_s1, char_addr_c1, char_addr_c2;
    logic [6:0] char_addr_mo10, char_addr_mo1, char_addr_d10, char_addr_d1, char_addr_ce10, char_addr_ce1, char_addr_y10, char_addr_y1;
    logic [6:0] char_addr_p1, char_addr_p2, char_addr_ap, char_addr_apm;
    logic [3:0] row_addr;    // row address of digit
    logic [3:0] row_addr_h10, row_addr_h1, row_addr_m10, row_addr_m1, row_addr_s10, row_addr_s1, row_addr_c1, row_addr_c2;
    logic [3:0] row_addr_mo10, row_addr_mo1, row_addr_d10, row_addr_d1, row_addr_ce10, row_addr_ce1, row_addr_y10, row_addr_y1;
    logic [3:0] row_addr_p1, row_addr_p2, row_addr_ap, row_addr_apm; 
    logic [2:0] bit_addr;    // column address of rom data
    logic [2:0] bit_addr_h10, bit_addr_h1, bit_addr_m10, bit_addr_m1, bit_addr_s10, bit_addr_s1, bit_addr_c1, bit_addr_c2;
    logic [2:0] bit_addr_mo10, bit_addr_mo1, bit_addr_d10, bit_addr_d1, bit_addr_ce10, bit_addr_ce1, bit_addr_y10, bit_addr_y1;
    logic [2:0] bit_addr_p1, bit_addr_p2, bit_addr_ap, bit_addr_apm;
    logic [7:0] digit_word;  // data from rom
    logic digit_bit;

    // charater
    // CAM1
    logic [6:0] char_addr_cam1_c;
    logic [3:0] row_addr_cam1_c;
    logic [2:0] bit_addr_cam1_c;     
    logic [6:0] char_addr_cam1_a;
    logic [3:0] row_addr_cam1_a;
    logic [2:0] bit_addr_cam1_a;       
    logic [6:0] char_addr_cam1_m;
    logic [3:0] row_addr_cam1_m;
    logic [2:0] bit_addr_cam1_m;   
    logic [6:0] char_addr_cam1_1;
    logic [3:0] row_addr_cam1_1;
    logic [2:0] bit_addr_cam1_1;   
    // CAM2
    logic [6:0] char_addr_cam2_c;
    logic [3:0] row_addr_cam2_c;
    logic [2:0] bit_addr_cam2_c;   
    logic [6:0] char_addr_cam2_a;
    logic [3:0] row_addr_cam2_a;
    logic [2:0] bit_addr_cam2_a;     
    logic [6:0] char_addr_cam2_m;
    logic [3:0] row_addr_cam2_m;
    logic [2:0] bit_addr_cam2_m;   
    logic [6:0] char_addr_cam2_2;
    logic [3:0] row_addr_cam2_2;
    logic [2:0] bit_addr_cam2_2;      


    // font Instance
    // --------------------------------------------------------------------------
    font_rom u_8x16_font_rom(.clk(clk), .addr(rom_addr), .data(digit_word));
    // --------------------------------------------------------------------------
                     

    assign char_addr_h10 = {3'b011, hour_10d};
    assign row_addr_h10 = y[3:0];   // scaling to 8x16
    assign bit_addr_h10 = x[2:0];   // scaling to 8x16
    
    assign char_addr_h1 = {3'b011, hour_1d};
    assign row_addr_h1 = y[3:0];   // scaling to 8x16
    assign bit_addr_h1 = x[2:0];   // scaling to 8x16
    
    assign char_addr_c1 = 7'h3a;
    assign row_addr_c1 = y[3:0];    // scaling to 8x16
    assign bit_addr_c1 = x[2:0];    // scaling to 8x16
    
    assign char_addr_m10 = {3'b011, min_10d};
    assign row_addr_m10 = y[3:0];   // scaling to 8x16
    assign bit_addr_m10 = x[2:0];   // scaling to 8x16
    
    assign char_addr_m1 = {3'b011, min_1d};
    assign row_addr_m1 = y[3:0];   // scaling to 8x16
    assign bit_addr_m1 = x[2:0];   // scaling to 8x16
    
    assign char_addr_c2 = 7'h3a;
    assign row_addr_c2 = y[3:0];    // scaling to 8x16
    assign bit_addr_c2 = x[2:0];    // scaling to 8x16
    
    assign char_addr_s10 = {3'b011, sec_10d};
    assign row_addr_s10 = y[3:0];   // scaling to 8x16
    assign bit_addr_s10 = x[2:0];   // scaling to 8x16
    
    assign char_addr_s1 = {3'b011, sec_1d};
    assign row_addr_s1 = y[3:0];   // scaling to 8x16
    assign bit_addr_s1 = x[2:0];   // scaling to 8x16
    
    assign char_addr_ap = {3'b100, 3'b000, am_pm};
    //assign char_addr_ap = {3'b100, 3'b000, am_pm};
    assign row_addr_ap = y[3:0];    // scaling to 8x16
    assign bit_addr_ap = x[2:0];    // scaling to 8x16
    
    assign char_addr_apm = 7'h4d;   // M
    assign row_addr_apm = y[3:0];   // scaling to 8x16
    assign bit_addr_apm = x[2:0];   // scaling to 8x16
    
    
    // Calendar
    assign char_addr_mo10 = {3'b011, m_10d};
    assign row_addr_mo10 = y[3:0];   // scaling to 8x16
    assign bit_addr_mo10 = x[2:0];   // scaling to 8x16
    
    assign char_addr_mo1 = {3'b011, m_1d};
    assign row_addr_mo1 = y[3:0];   // scaling to 8x16.
    assign bit_addr_mo1 = x[2:0];   // scaling to 8x16.
    
    assign char_addr_p1 = 7'h2e;
    assign row_addr_p1 = y[3:0];    // scaling to 8x16.
    assign bit_addr_p1 = x[2:0];    // scaling to 8x16.
    
    assign char_addr_d10 = {3'b011, d_10d};
    assign row_addr_d10 = y[3:0];   // scaling to 8x16.
    assign bit_addr_d10 = x[2:0];   // scaling to 8x16.
    
    assign char_addr_d1 = {3'b011, d_1d};
    assign row_addr_d1 = y[3:0];   // scaling to 8x16.
    assign bit_addr_d1 = x[2:0];   // scaling to 8x16.
    
    assign char_addr_p2 = 7'h2e;
    assign row_addr_p2 = y[3:0];    // scaling to 8x16.
    assign bit_addr_p2 = x[2:0];    // scaling to 8x16.
    
    assign char_addr_ce10 = {3'b011, c_10d};
    assign row_addr_ce10 = y[3:0];   // scaling to 8x16.
    assign bit_addr_ce10 = x[2:0];   // scaling to 8x16.
    
    assign char_addr_ce1 = {3'b011, c_1d};
    assign row_addr_ce1 = y[3:0];   // scaling to 8x16.
    assign bit_addr_ce1 = x[2:0];   // scaling to 8x16.
    
    assign char_addr_y10 = {3'b011, y_10d};
    assign row_addr_y10 = y[3:0];   // scaling to 8x16. 
    assign bit_addr_y10 = x[2:0];   // scaling to 8x16.
    
    assign char_addr_y1 = {3'b011, y_1d};
    assign row_addr_y1 = y[3:0];    // scaling to 8x16.
    assign bit_addr_y1 = x[2:0];    // scaling to 8x16.


    // CAM1                        
    assign row_addr_cam1_c = y[5:2];   // scaling to 32x64
    assign bit_addr_cam1_c = x[4:2];   // scaling to 32x64
    assign char_addr_cam1_c = 7'h42;

    assign row_addr_cam1_a = y[5:2];   // scaling to 32x64
    assign bit_addr_cam1_a = x[4:2];   // scaling to 32x64
    assign char_addr_cam1_a = 7'h40;

    assign bit_addr_cam1_m = x[4:2];   // scaling to 32x64
    assign row_addr_cam1_m = y[5:2];   // scaling to 32x64
    assign char_addr_cam1_m = 7'h4d;

    assign bit_addr_cam1_1 = x[4:2];   // scaling to 32x64
    assign row_addr_cam1_1 = y[5:2];   // scaling to 32x64
    assign char_addr_cam1_1 = 7'h31;
    

    // CAM2   
    assign row_addr_cam2_c = y[5:2];   // scaling to 32x64
    assign bit_addr_cam2_c = x[4:2];   // scaling to 32x64
    assign char_addr_cam2_c = 7'h42;

    assign bit_addr_cam2_a = x[4:2];   // scaling to 32x64
    assign row_addr_cam2_a = y[5:2];   // scaling to 32x64
    assign char_addr_cam2_a = 7'h40;

    assign bit_addr_cam2_m = x[4:2];   // scaling to 32x64
    assign row_addr_cam2_m = y[5:2];   // scaling to 32x64
    assign char_addr_cam2_m = 7'h4d;

    assign bit_addr_cam2_2 = x[4:2];   // scaling to 32x64
    assign row_addr_cam2_2 = y[5:2];   // scaling to 32x64
    assign char_addr_cam2_2 = 7'h32;


    // Hour 
    assign H10_on = (H10_X_L <= x) && (x <= H10_X_R) &&
                    (H10_Y_T <= y) && (y <= H10_Y_B) && (hour_10d != 0); 
    assign H1_on =  (H1_X_L <= x) && (x <= H1_X_R) &&
                    (H1_Y_T <= y) && (y <= H1_Y_B);
    // Colon 1 
    assign C1_on = (C1_X_L <= x) && (x <= C1_X_R) &&
                   (C1_Y_T <= y) && (y <= C1_Y_B);               
    // Minute sections
    assign M10_on = (M10_X_L <= x) && (x <= M10_X_R) &&
                    (M10_Y_T <= y) && (y <= M10_Y_B);
    assign M1_on =  (M1_X_L <= x) && (x <= M1_X_R) &&
                    (M1_Y_T <= y) && (y <= M1_Y_B);                             
    // Colon 2 
    assign C2_on = (C2_X_L <= x) && (x <= C2_X_R) &&
                   (C2_Y_T <= y) && (y <= C2_Y_B);    
    // Second 
    assign S10_on = (S10_X_L <= x) && (x <= S10_X_R) &&
                    (S10_Y_T <= y) && (y <= S10_Y_B);
    assign S1_on =  (S1_X_L <= x) && (x <= S1_X_R) &&
                    (S1_Y_T <= y) && (y <= S1_Y_B);          
    // AM / PM sections 
    assign AP_on = (AP_X_L <= x) && (x <= AP_X_R) &&
                   (AP_Y_T <= y) && (y <= AP_Y_B);
    assign APM_on = (APM_X_L <= x) && (x <= APM_X_R) &&
                    (APM_Y_T <= y) && (y <= APM_Y_B);
    // Month 
    assign Mo10_on = (Mo10_X_L <= x) && (x <= Mo10_X_R) &&
                     (Mo10_Y_T <= y) && (y <= Mo10_Y_B) && (m_10d != 0); 
    assign Mo1_on =  (Mo1_X_L <= x) &&  (x <= Mo1_X_R) &&
                     (Mo1_Y_T <= y) &&  (y <= Mo1_Y_B);
    // Period 
    assign P1_on = (P1_X_L <= x) && (x <= P1_X_R) &&
                   (P1_Y_T <= y) && (y <= P1_Y_B);            
    // Day 
    assign D10_on = (D10_X_L <= x) && (x <= D10_X_R) &&
                    (D10_Y_T <= y) && (y <= D10_Y_B);
    assign D1_on =  (D1_X_L <= x) &&  (x <= D1_X_R) &&
                    (D1_Y_T <= y) &&  (y <= D1_Y_B);                             
    // Period 2 
    assign P2_on = (P2_X_L <= x) && (x <= P2_X_R) &&
                   (P2_Y_T <= y) && (y <= P2_Y_B);
    // Century 
    assign Ce10_on = (Ce10_X_L <= x) && (x <= Ce10_X_R) &&
                     (Ce10_Y_T <= y) && (y <= Ce10_Y_B);
    assign Ce1_on =  (Ce1_X_L <= x) &&  (x <= Ce1_X_R) &&
                     (Ce1_Y_T <= y) &&  (y <= Ce1_Y_B);
    // Year 
    assign Y10_on = (Y10_X_L <= x) && (x <= Y10_X_R) &&
                    (Y10_Y_T <= y) && (y <= Y10_Y_B);
    assign Y1_on =  (Y1_X_L <= x) && (x <= Y1_X_R) &&
                    (Y1_Y_T <= y) && (y <= Y1_Y_B);    

    // CAM1
    assign CAM1_C_on = (CAM1_C_X_L <= x) && (x <= CAM1_C_X_R) &&
                        (CAM1_C_Y_T <= y) && (y <= CAM1_C_Y_B);
    assign CAM1_A_on = (CAM1_A_X_L <= x) && (x <= CAM1_A_X_R) &&
                        (CAM1_A_Y_T <= y) && (y <= CAM1_A_Y_B);
    assign CAM1_M_on = (CAM1_M_X_L <= x) && (x <= CAM1_M_X_R) &&
                        (CAM1_M_Y_T <= y) && (y <= CAM1_M_Y_B);
    assign CAM1_1_on = (CAM1_1_X_L <= x) && (x <= CAM1_1_X_R) &&
                        (CAM1_1_Y_T <= y) && (y <= CAM1_1_Y_B);
    // CAM2               
    assign CAM2_C_on = (CAM2_C_X_L <= x) && (x <= CAM2_C_X_R) &&
                        (CAM2_C_Y_T <= y) && (y <= CAM2_C_Y_B);
    assign CAM2_A_on = (CAM2_A_X_L <= x) && (x <= CAM2_A_X_R) &&
                        (CAM2_A_Y_T <= y) && (y <= CAM2_A_Y_B);
    assign CAM2_M_on = (CAM2_M_X_L <= x) && (x <= CAM2_M_X_R) &&
                        (CAM2_M_Y_T <= y) && (y <= CAM2_M_Y_B);
    assign CAM2_1_on = (CAM2_2_X_L <= x) && (x <= CAM2_2_X_R) &&
                        (CAM2_2_Y_T <= y) && (y <= CAM2_2_Y_B);


    //OV7670 CAM1
    assign OV7670_CAM1_on = (OCV7670_CAM1_L <= x) && (x <= OCV7670_CAM1_R) &&
                            (OCV7670_CAM1_T <= y) && (y <= OCV7670_CAM1_B);
    //OV7670 CAM2
    assign OV7670_CAM2_on = (OCV7670_CAM2_L <= x) && (x <= OCV7670_CAM2_R) &&
                            (OCV7670_CAM2_T <= y) && (y <= OCV7670_CAM2_B);



   // Mux for ROM Addresses and RGB    
    always_comb begin
        bit_addr = 3'h0;
        row_addr = 4'h0;
        char_addr = 7'h0;
        if(~display_en) rgb = 12'h0;    //display_en =0        
        else begin                      //display_en = 1
            rgb = 12'h000;              //background  
            // add
            if(CAM1_C_on) begin
                char_addr = char_addr_cam1_c;
                row_addr = row_addr_cam1_c;
                bit_addr = bit_addr_cam1_c;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(CAM1_A_on) begin
                char_addr = char_addr_cam1_a;
                row_addr = row_addr_cam1_a;
                bit_addr = bit_addr_cam1_a;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(CAM1_M_on) begin
                char_addr = char_addr_cam1_m;
                row_addr = row_addr_cam1_m;
                bit_addr = bit_addr_cam1_m;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(CAM1_1_on) begin
                char_addr = char_addr_cam1_1;
                row_addr = row_addr_cam1_1;
                bit_addr = bit_addr_cam1_1;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(CAM2_C_on) begin
                char_addr = char_addr_cam2_c;
                row_addr = row_addr_cam2_c;
                bit_addr = bit_addr_cam2_c;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(CAM2_A_on) begin
                char_addr = char_addr_cam2_a;
                row_addr = row_addr_cam2_a;
                bit_addr = bit_addr_cam2_a;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(CAM2_M_on) begin
                char_addr = char_addr_cam2_m;
                row_addr = row_addr_cam2_m;
                bit_addr = bit_addr_cam2_m;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(CAM2_1_on) begin
                char_addr = char_addr_cam2_2;
                row_addr = row_addr_cam2_2;
                bit_addr = bit_addr_cam2_2;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            //else if(OV7670_CAM1_on) begin
            //    rgb = {rData[11:8], rData[7:4], rData[3:0]};
            //end
            //else if(OV7670_CAM2_on) begin
            //    //rgb = {rData[11:8], rData[7:4], rData[3:0]};
            //end
            else if(H10_on) begin
                char_addr = char_addr_h10;
                row_addr = row_addr_h10;
                bit_addr = bit_addr_h10;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(H1_on) begin
                char_addr = char_addr_h1;
                row_addr = row_addr_h1;
                bit_addr = bit_addr_h1;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(C1_on) begin
                char_addr = char_addr_c1;
                row_addr = row_addr_c1;
                bit_addr = bit_addr_c1;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(M10_on) begin
                char_addr = char_addr_m10;
                row_addr = row_addr_m10;
                bit_addr = bit_addr_m10;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(M1_on) begin
                char_addr = char_addr_m1;
                row_addr = row_addr_m1;
                bit_addr = bit_addr_m1;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(C2_on) begin
                char_addr = char_addr_c2;
                row_addr = row_addr_c2;
                bit_addr = bit_addr_c2;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(S10_on) begin
                char_addr = char_addr_s10;
                row_addr = row_addr_s10;
                bit_addr = bit_addr_s10;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(S1_on) begin
                char_addr = char_addr_s1;
                row_addr = row_addr_s1;
                bit_addr = bit_addr_s1;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end  
            else if(AP_on) begin
                char_addr = char_addr_ap;
                row_addr = row_addr_ap;
                bit_addr = bit_addr_ap;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            else if(APM_on) begin
                char_addr = char_addr_apm;
                row_addr = row_addr_apm;
                bit_addr = bit_addr_apm;
                if(digit_bit)
                    rgb = 12'hF00;     // red
            end
            
            else if(Mo10_on) begin
                char_addr = char_addr_mo10;
                row_addr = row_addr_mo10;
                bit_addr = bit_addr_mo10;
                if(digit_bit)
                    rgb = 12'h0FF;     // aqua
            end
            else if(Mo1_on) begin
                char_addr = char_addr_mo1;
                row_addr = row_addr_mo1;
                bit_addr = bit_addr_mo1;
                if(digit_bit)
                    rgb = 12'h0FF;     // aqua
            end
            else if(P1_on) begin
                char_addr = char_addr_p1;
                row_addr = row_addr_p1;
                bit_addr = bit_addr_p1;
                if(digit_bit)
                    rgb = 12'h0FF;     // aqua
            end
            else if(D10_on) begin
                char_addr = char_addr_d10;
                row_addr = row_addr_d10;
                bit_addr = bit_addr_d10;
                if(digit_bit)
                    rgb = 12'h0FF;     // aqua
            end
            else if(D1_on) begin
                char_addr = char_addr_d1;
                row_addr = row_addr_d1;
                bit_addr = bit_addr_d1;
                if(digit_bit)
                    rgb = 12'h0FF;     // aqua
            end
            else if(P2_on) begin
                char_addr = char_addr_p2;
                row_addr = row_addr_p2;
                bit_addr = bit_addr_p2;
                if(digit_bit)
                    rgb = 12'h0FF;     // aqua
            end
            else if(Ce10_on) begin
                char_addr = char_addr_ce10;
                row_addr = row_addr_ce10;
                bit_addr = bit_addr_ce10;
                if(digit_bit)
                    rgb = 12'h0FF;     // aqua
            end
            else if(Ce1_on) begin
                char_addr = char_addr_ce1;
                row_addr = row_addr_ce1;
                bit_addr = bit_addr_ce1;
                if(digit_bit)
                    rgb = 12'h0FF;     // aqua
            end  
            else if(Y10_on) begin
                char_addr = char_addr_y10;
                row_addr = row_addr_y10;
                bit_addr = bit_addr_y10;
                if(digit_bit)
                    rgb = 12'h0FF;     // aqua
            end
            else if(Y1_on) begin
                char_addr = char_addr_y1;
                row_addr = row_addr_y1;
                bit_addr = bit_addr_y1;
                if(digit_bit)
                    rgb = 12'h0FF;     // aqua
            end 
            else begin
                char_addr = 0;
                row_addr = 0;
                bit_addr = 0;
                rgb  = 12'hz;
            end
        end
    end    

    // ROM Interface    
    assign rom_addr = {char_addr, row_addr};
    assign digit_bit = digit_word[~bit_addr];    

endmodule
