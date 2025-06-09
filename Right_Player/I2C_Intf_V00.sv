`timescale 1ns / 1ps
module I2C_Intf (
    input  logic        clk,
    input  logic        reset,
    input  logic        ball_send_trigger,
    input  logic [ 9:0] ball_y,
    input  logic [ 7:0] ball_vy,
    input  logic [ 1:0] gravity_counter,
    input  logic        is_collusion,
    output logic        o_SCL,
    inout  logic        o_SDA,
    input  logic        i_SCL,
    inout  logic        i_SDA,
    output logic        is_transfer,
    input  logic        is_ball_moving_right,



    //
    input logic [5:0] sw,
    output logic [7:0] fndFont,
    output logic [3:0] fndCom,


    // slave//
    output logic [7:0] i_y_pos0,
    output logic [7:0] i_y_pos1,
    output logic [7:0] i_y_vel,
    output logic [7:0] i_gravity,
    output logic [7:0] i_is_collusion,
    output logic [7:0] i_is_win_flag,
    output logic is_slave_done,
    input logic responsing_i2c,
    input logic is_lose,

    output logic [7:0] master_led,
    output logic [7:0] contrl_led,
    output logic is_i2c_master_done
);
    logic       ready;
    logic       start;
    logic       stop;
    logic       i2c_en;
    logic [7:0] tx_data;
    logic       tx_done;


    I2C_Controller U_I2C_CNTRL (.*);

    I2C_Master U_I2C_MASTER (
        .*,
        .SCL(o_SCL),
        .SDA(o_SDA)
    );

    I2C_Slave U_I2C_SLAVE (
        .*,
        .SCL(i_SCL),
        .SDA(i_SDA),
        .slv_reg0(i_y_pos0),
        .slv_reg1(i_y_pos1),
        .slv_reg2(i_y_vel),
        .slv_reg3(i_gravity),
        .slv_reg4(i_is_collusion),
        .slv_reg5(i_is_win_flag)
    );

    FND_C U_FND_C(
        .clk(clk), 
        .reset(reset),
        .sw(sw),
        .slv_reg0(ball_y[9:8]),
        .slv_reg1(ball_y[7:0]),
        .slv_reg2(ball_vy),
        .slv_reg3(gravity_counter),
        .slv_reg4(is_collusion),
        .slv_reg5({7'b0,is_lose}),
        .fndFont (fndFont),
        .fndCom(fndCom)
    );


endmodule
