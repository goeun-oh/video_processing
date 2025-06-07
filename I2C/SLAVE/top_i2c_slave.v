`timescale 1ns / 1ps

module top_i2c_slave(
    input clk,
    input reset,
    input [3:0] sw,
    input SCL,
    inout SDA,
    output [7:0] fndFont,
    output [3:0] fndCom,

    output [7:0] slv_reg0_y0,
    output [7:0] slv_reg1_y1,
    output [7:0] slv_reg2_Yspeed,
    output [7:0] slv_reg3_gravity,
    output [7:0] slv_reg4_ballspeed,

    output go_right,
    input responsing_i2c
    );

    wire [7:0] slv_reg0;
    wire [7:0] slv_reg1;
    wire [7:0] slv_reg2;
    wire [7:0] slv_reg3;

    assign slv_reg0_y0 = slv_reg0;
    assign slv_reg1_y1 = slv_reg1;
    assign slv_reg2_Yspeed = slv_reg2;
    assign slv_reg3_gravity = slv_reg3;
    assign slv_reg4_ballspeed = slv_reg4;

    I2C_Slave U_I2C_Slave(
    .clk(clk),
    .reset(reset),
    .SCL(SCL),
    .SDA(SDA),
    .slv_reg0(slv_reg0),
    .slv_reg1(slv_reg1),
    .slv_reg2(slv_reg2),
    .slv_reg3(slv_reg3),
    .slv_reg4(slv_reg4),
    .go_right(go_right),
    .responsing_i2c(responsing_i2c)
    );

    FND_C U_FND_C(
    .clk(clk), 
    .reset(reset),
    .sw(sw),
    .slv_reg0(slv_reg0),
    .slv_reg1(slv_reg1),
    .slv_reg2(slv_reg2),
    .slv_reg3(slv_reg3),
    .slv_reg4(slv_reg4),
    .fndFont(fndFont),
    .fndCom(fndCom)
    );

endmodule
