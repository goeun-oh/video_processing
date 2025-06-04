`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/27 13:29:49
// Design Name: 
// Module Name: rgb_out
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


module rgb_out (
    input  logic [ 2:0] quadframe,
    input  logic [11:0] final_output1,
    input  logic [11:0] final_output2,
    input  logic [11:0] final_output3,
    input  logic [11:0] final_output4,
    input  logic [11:0] txt_vga_in,
    output logic [ 3:0] red_port,
    output logic [ 3:0] green_port,
    output logic [ 3:0] blue_port
);
    logic [3:0] base_r, base_g, base_b;

    always_comb begin
        case (quadframe)
            3'b000:
            {base_r, base_g, base_b} = {
                final_output1[11:8], final_output1[7:4], final_output1[3:0]
            };
            3'b001:
            {base_r, base_g, base_b} = {
                final_output2[11:8], final_output2[7:4], final_output2[3:0]
            };
            3'b010:
            {base_r, base_g, base_b} = {
                final_output3[11:8], final_output3[7:4], final_output3[3:0]
            };
            3'b011:
            {base_r, base_g, base_b} = {
                final_output4[11:8], final_output4[7:4], final_output4[3:0]
            };
            default: {base_r, base_g, base_b} = {4'h0, 4'h0, 4'h0};
        endcase

        if ((txt_vga_in[11:8] != 4'h0) || (txt_vga_in[7:4] != 4'h0) || (txt_vga_in[3:0] != 4'h0)) begin
            {red_port, green_port, blue_port} = {
                txt_vga_in[11:8], txt_vga_in[7:4], txt_vga_in[3:0]
            };
        end else begin
            {red_port, green_port, blue_port} = {base_r, base_g, base_b};
        end
    end

endmodule
