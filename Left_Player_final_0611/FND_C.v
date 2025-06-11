`timescale 1ns / 1ps

module FND_C(
    input clk, 
    input reset,
    input [6:0] sw,
    input  [7:0] slv_reg0,
    input  [7:0] slv_reg1,
    input  [7:0] slv_reg2,
    input  [7:0] slv_reg3,
    input  [7:0] slv_reg4,
    input  [7:0] slv_reg5,

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
    .slv_reg4(slv_reg4),
    .slv_reg5(slv_reg5),
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
  input [6:0] sw,
  input [7:0] slv_reg0,
  input [7:0] slv_reg1,
  input [7:0] slv_reg2,
  input [7:0] slv_reg3,
  input [7:0] slv_reg4,
  input [7:0] slv_reg5,
  output reg [7:0] fnd_reg
);
    always @(*) begin
        case (sw)
            7'b0000001: fnd_reg = slv_reg0;
            7'b0000010: fnd_reg = slv_reg1;
            7'b0000100: fnd_reg = slv_reg2;
            7'b0001000: fnd_reg = slv_reg3;
            7'b0010000: fnd_reg = slv_reg4;
            7'b0100000: fnd_reg = slv_reg5;
            //7'b1000000: fnd_reg = slv_reg6;
            default: fnd_reg = 8'b0;
        endcase
    end
endmodule
