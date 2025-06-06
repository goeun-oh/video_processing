`timescale 1ns / 1ps

module tb_I2C_Intf;

    logic clk;
    logic reset;
    logic ball_send_trigger;
    logic [9:0] ball_y;
    logic [7:0] ball_vy;
    logic SCL;
    tri1 SDA;
    logic is_transfer;
    logic [15:0] led;

    // DUT instantiation
    I2C_Intf dut (
        .clk(clk),
        .reset(reset),
        .ball_send_trigger(ball_send_trigger),
        .ball_y(ball_y),
        .ball_vy(ball_vy),
        .SCL(SCL),
        .SDA(SDA),
        .is_transfer(is_transfer),
        .led(led)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    initial begin
        // Initial values
        reset = 1;
        ball_send_trigger = 0;
        ball_y = 10'd256;
        ball_vy = 8'd50;

        // Apply reset
        #20;
        reset = 0;

        // Trigger ball send
        #100;
        ball_send_trigger = 1;
        #10;
        ball_send_trigger = 0;

        // Let it run
        #5000;

    end

endmodule