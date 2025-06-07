`timescale 1ns / 1ps

module FND_C(
    input clk, 
    input reset,
    input [3:0] sw,
    input  [7:0] slv_reg0,
    input  [7:0] slv_reg1,
    input  [7:0] slv_reg2,
    input  [7:0] slv_reg3,
    output [7:0] fndFont,
    output [3:0] fndCom
    );

    wire [7:0] fnd_reg;

    mux_4x1_spi U_MUX(
    .sw(sw),
    .slv_reg0(slv_reg0),
    .slv_reg1(slv_reg1),
    .slv_reg2(slv_reg2),
    .slv_reg3(slv_reg3),
    .fnd_reg(fnd_reg)
    );


    fnd_controller U_FND(
    .clk(clk), 
    .reset(reset),
    .Digit(fnd_reg),
    .seg(fndFont),
    .seg_comm(fndCom)
);
endmodule

module mux_4x1_spi (
  input [3:0] sw,
  input [7:0] slv_reg0,
  input [7:0] slv_reg1,
  input [7:0] slv_reg2,
  input [7:0] slv_reg3,
  output reg [7:0] fnd_reg
);
    always @(*) begin
        case (sw)
            4'b0001: fnd_reg = slv_reg0; // y좌표
            4'b0010: fnd_reg = slv_reg1; // y좌표
            4'b0100: fnd_reg = slv_reg2; // y 속도
            4'b1000: fnd_reg = slv_reg3; // trig
            default: fnd_reg = 8'b0;
        endcase
    end
endmodule
