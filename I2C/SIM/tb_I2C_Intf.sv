`timescale 1ns / 1ps

module tb_I2C_Intf;

    logic clk;
    logic reset;
    logic ball_send_trigger;
    logic [9:0] ball_y;
    logic [7:0] ball_vy;
    wire SCL;
    tri SDA;
    wire is_transfer;
    wire [15:0] led;

    logic sda_drv_en;
    logic sda_drv_val;

    assign SDA = sda_drv_en ? sda_drv_val : 1'bz;

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

    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz clock
    end

    initial begin
        reset = 1;
        ball_send_trigger = 0;
        ball_y = 10'd300;
        ball_vy = 8'd20;
        sda_drv_en = 0;
        sda_drv_val = 1;

        #50;
        reset = 0;
        #50;
        ball_send_trigger = 1;
        #10;
        ball_send_trigger = 0;

        // wait until WRITE_ACK phase
        wait (led== 16'h2001); // WRITE_ACK

        #2;
        sda_drv_en = 1;
        sda_drv_val = 0;

        // release SDA after ACK sampled
        #10000;
        sda_drv_en = 0;

        #1000;
        // wait until WRITE_ACK phase
        wait (led== 16'h2001); // WRITE_ACK

        #2;
        sda_drv_en = 1;
        sda_drv_val = 0;

        // release SDA after ACK sampled
        #10000;
        sda_drv_en = 0;

        #1000;

        wait (led== 16'h2001); // WRITE_ACK

        #2;
        sda_drv_en = 1;
        sda_drv_val = 0;

        // release SDA after ACK sampled
        #10000;
        sda_drv_en = 0;

        #1000;

        wait (led== 16'h2001); // WRITE_ACK

        #2;
        sda_drv_en = 1;
        sda_drv_val = 0;

        // release SDA after ACK sampled
        #10000;
        sda_drv_en = 0;

        #1000;
                // release SDA after ACK sampled
        #10000;
        sda_drv_en = 0;

        #1000;

        wait (led== 16'h2001); // WRITE_ACK

        #2;
        sda_drv_en = 1;
        sda_drv_val = 0;

        // release SDA after ACK sampled
        #10000;
        sda_drv_en = 0;

        #1000;
    end

endmodule
