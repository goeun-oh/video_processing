`timescale 1ns/1ps
module I2C_Intf(
    input  logic       clk,
    input  logic       reset,
    input  logic       ball_send_trigger,
    input  logic [9:0] ball_y,
    input  logic [7:0] ball_vy,
    output logic       SCL,
    inout  logic       SDA,
    output logic is_transfer,
    output logic [15:0] led,
    input logic is_ball_moving_left
);
    logic       ready;
    logic       start;
    logic       stop;
    logic       i2c_en;
    logic [7:0] tx_data;
    logic       tx_done;

    logic [7:0] intf_led;
    logic [7:0] master_led;

    assign led = {master_led, intf_led};
    I2C_Controller U_I2C_CNTRL(
        .*
    );

    I2C_Master U_I2C_MASTER(
        .*
    );
endmodule