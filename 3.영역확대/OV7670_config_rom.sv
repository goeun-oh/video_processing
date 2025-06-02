`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2015 02:41:55 PM
// Design Name: 
// Module Name: OV7670_config_rom
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


module OV7670_config_rom (
    input wire clk,
    input wire [4:0] addr,
    output reg [15:0] dout
);
    //FFFF is end of rom, FFF0 is delay
    always_ff @(posedge clk) begin
        case (addr)
            0: dout <= 16'h12_80;
            1: dout <= 16'hff_f0;
            2: dout <= 16'h3a_04;
            3: dout <= 16'h13_e7;
            4: dout <= 16'h6f_9f;
            5: dout <= 16'hb0_84;
            6: dout <= 16'hff_f0;
            7: dout <= 16'h12_11;
            8: dout <= 16'h0c_04;
            9: dout <= 16'h3e_19;
            10: dout <= 16'h70_3a;
            11: dout <= 16'h71_35;
            12: dout <= 16'h72_11;
            13: dout <= 16'h73_f1;
            14: dout <= 16'ha2_02;
            15: dout <= 16'h17_15;  //HSTART     start high 8 bits
            16: dout <= 16'h18_03; //HSTOP      stop high 8 bits 
            17: dout <= 16'h32_80;  //HREF       edge offset
            18: dout <= 16'h19_03;  //VSTART     start high 8 bits
            19: dout <= 16'h1A_7B;  //VSTOP      stop high 8 bits
            20: dout <= 16'h03_00;  //VREF       vsync edge offset
            // 21: dout <= 16'h12_10;
            // 22: dout <= 16'h40_10;
            21: dout <= 16'h12_14;
            22: dout <= 16'h40_d0;
            default: dout <= 16'hFF_FF;  //mark end of ROM
        endcase

    end
endmodule
