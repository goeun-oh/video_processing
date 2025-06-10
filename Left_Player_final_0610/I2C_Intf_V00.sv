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
    output logic [7:0] slave_led,
    input  logic        is_ball_moving_left,


    // slave//
    output logic [7:0] i_y_pos0,
    output logic [7:0] i_y_pos1,
    output logic [7:0] i_y_vel,
    output logic [7:0] i_gravity,
    output logic [7:0] i_is_collusion,
    output logic go_left,
    input logic responsing_i2c,
    output
     logic is_i2c_master_done

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
        .slv_reg4(i_is_collusion)
    );




endmodule
