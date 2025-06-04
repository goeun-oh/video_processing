`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/20 09:35:57
// Design Name: 
// Module Name: ov7670_top
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


module ov7670_top (
    input  logic       clk,
    input  logic       reset,
    input  logic       focusing_btn,
    input  logic       rotate2idle_btn,
    input  logic       ov_btn,
    input  logic [7:0] ov7670_data,
    input  logic       pclk,
    output logic       xclk,
    input  logic       href,
    input  logic       vref,
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port,
    output logic [7:0] whole_frame_mean,
    output logic [3:0] led,
    output logic       pwm,
    output logic       pwm_buzzer,
    output logic       scl,
    output logic       sda
);

    logic [                    9:0] x_pixel;
    logic [                    9:0] y_pixel;
    logic [                    9:0] w_x_pixel;
    logic                           display_enable;
    logic                           we;
    logic [                   16:0] wAddr;
    logic [                   11:0] wData;
    logic [                   11:0] rData;
    logic [                    7:0] gray;
    logic [                    3:0] sobel_filtered_data;
    logic                           sobel_en;
    logic                           focus_start;
    logic                           mean_done;
    logic                           focus_done;
    logic [                   10:0] integrated_data;
    logic                           mean_start;
    logic                           scan_done;
    logic [$clog2(250000000)-1 : 0] counter_rotate_time;
    logic [                    8:0] r_x_pixel;
    logic                           clk_out12_5;
    logic [                   24:0] wtransdata_sum;
    logic [                   14:0] wtransdata_cnt;
    logic                           divide_cmplt;
    logic                           rotate2idle;
    logic                           counter_rotation_done;
    logic                           clk_100MHz;

    assign r_x_pixel = (x_pixel < 320) ? x_pixel : (x_pixel - 320);

    clk_wiz_0 U_clk_wiz (
        // Clock out ports
        .clk_out25(xclk),
        .clk_out12_5(clk_out12_5),
        .clk_out3(clk_100MHz),
        // Status and control signals
        .reset(reset),
        // Clock in ports
        .clk_in1(clk)
    );  // input clk_in1

    top_sccb U_SCCB (
        .clk  (clk_100MHz),
        .reset(reset),
        .btn  (ov_btn),
        .scl  (scl),
        .sda  (sda)
    );

    vga_controller U_VGA_CTRL (
        .clk            (xclk),
        .reset          (reset),
        .h_sync         (h_sync),
        .v_sync         (v_sync),
        .x_pixel        (x_pixel),
        .y_pixel        (y_pixel),
        .w_x_pixel      (w_x_pixel),
        .display_enable (display_enable),
        .sobel_en       (sobel_en),
        .focusing_btn   (focusing_btn),
        .mean_start     (focus_start),
        .rotate2idle_btn(rotate2idle_btn),
        .rotate2idle    (rotate2idle)
    );

    ov7670_controller U_OV_CTRL (
        .pclk       (pclk),
        .reset      (reset),
        .href       (href),
        .v_sync     (vref),
        .ov7670_data(ov7670_data),
        .we         (we),
        .wAddr      (wAddr),
        .wData      (wData)
    );

    frameBuffer U_Frame_BUFFER (
        // write side
        .wclk (pclk),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData),
        // read side
        .rclk (xclk),
        .oe   (display_enable),
        .rAddr((y_pixel * 320) + r_x_pixel),
        .rData(rData)
    );

    rgb2gray U_GRAY (
        .color_rgb(rData),
        .gray     (gray)
    );

    sobel_filter U_sobellom (
        .clk_25MHz          (xclk),
        .reset              (reset),
        .sobel_en           (sobel_en),
        .w_x_pixel            (w_x_pixel),
        .x_pixel(x_pixel),
        .y_pixel            (y_pixel),
        .gray               (gray),
        .sobel_filtered_data(sobel_filtered_data),
        .integrated_data    (integrated_data)
    );

    servo_controller U_LENS_SERVO (
        .clk                (xclk),
        .reset              (reset),
        .focus_start        (focus_start),
        .focus_done         (focus_done),
        .counter_rotate_time(counter_rotate_time),
        .mean_start         (mean_start),
        .scan_done          (scan_done),
        .pwm                (pwm),
        .led                (),
        .rotate2idle        (rotate2idle),
        .counter_rotate_done(counter_rotation_done)
    );

    Filtered_data_Collector U_Collector (
        .clk           (xclk),
        .reset         (reset),
        .mean_start    (mean_start),
        .focus_done    (focus_done),            //buzzer_trig
        .x_pixel       (w_x_pixel),
        .y_pixel       (y_pixel),
        .filtered_data (integrated_data[8:1]),
        .mean_done     (mean_done),
        .wtransdata_sum(wtransdata_sum),
        .wtransdata_cnt(wtransdata_cnt),
        .divide_cmplt  (divide_cmplt)
        //.led(led)
    );

    average_calculator_cdc U_Average_cdc (
        .clk_25MHz     (xclk),
        .clk_12_5MHz   (clk_out12_5),      // 12.5MHz 
        .reset         (reset),
        .addcount_done (mean_done),
        .wtransdata_sum(wtransdata_sum),
        .wtransdata_cnt(wtransdata_cnt),
        .avg_data      (whole_frame_mean)
    );

    max_avg_capture U_focus_capture (
        .clk_25MHz(xclk),
        .reset(reset),
        .start(divide_cmplt),
        .scan_done(scan_done),
        .average(whole_frame_mean),  // [11:0] gray_Data, gray_Data[3:0]
        .buzzer_trig(focus_done),
        .counter_rotate_time(counter_rotate_time),
        .led(led)
    );

    buzzer_PWM U_Buzzer (
        .clk(xclk),
        .reset(reset),
        .counter_rotation_done(counter_rotation_done),
        .PWM_signal(pwm_buzzer)
    );

    always_comb begin
        if ((x_pixel < 320) && (y_pixel < 240)) begin
            {red_port, green_port, blue_port} = {
                sobel_filtered_data, sobel_filtered_data, sobel_filtered_data
            };  //sobel_filtered_data
        end
        else if((x_pixel >= 320) && (x_pixel < 640) && (y_pixel < 240))begin
            {red_port, green_port, blue_port} = rData;
        end else begin
            {red_port, green_port, blue_port} = 12'b0;
        end
    end
endmodule

module rgb2gray (
    input  logic [11:0] color_rgb,
    output logic [ 7:0] gray
);
    localparam RW = 8'h47;  // weight for red
    localparam GW = 8'h96;  // weight for green
    localparam BW = 8'h1D;  // weight for blue

    logic [3:0] r, g, b;
    logic [11:0] gray12;

    assign r = color_rgb[11:8];
    assign g = color_rgb[7:4];
    assign b = color_rgb[3:0];
    assign gray12 = r * RW + g * GW + b * BW;
    assign gray = gray12[11:4];

endmodule

module servo_controller (
    input  logic                           clk,
    input  logic                           reset,
    input  logic                           focus_start,
    input  logic                           rotate2idle,
    input  logic                           focus_done,
    input  logic [$clog2(250000000)-1 : 0] counter_rotate_time,
    output logic                           mean_start,
    output logic                           scan_done,
    output logic                           pwm,
    output logic [                    4:0] led,
    output logic                           counter_rotate_done
);
    localparam PWM_FREQUENCY = 500000;
    localparam MAX_ROTATING_TIME = 250000000;
    localparam CCW = 38000;
    localparam CW = 25000;

    typedef enum {
        IDLE,
        START,
        SCAN,
        DONE,
        COUNTER_ROTATE,
        ROTATE2IDLE
    } states;

    states cstate;

    logic pwm_en;
    logic [$clog2(PWM_FREQUENCY)-1 : 0] cnt_50Hz;
    logic [$clog2(CCW)-1 : 0] direction;
    logic [$clog2(MAX_ROTATING_TIME) -1 : 0] rotating_time_cnt;
    logic [$clog2(MAX_ROTATING_TIME) -1 : 0] counter_rotate_time_buffer;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            pwm <= 1'b0;
            cnt_50Hz <= 0;
        end else begin
            if (pwm_en) begin
                if (cnt_50Hz <= (PWM_FREQUENCY - direction)) begin
                    pwm <= 1'b0;
                    cnt_50Hz <= cnt_50Hz + 1;
                end else if (cnt_50Hz == (PWM_FREQUENCY - 1)) begin
                    pwm <= 1'b0;
                    cnt_50Hz <= 0;
                end else begin
                    pwm <= 1'b1;
                    cnt_50Hz <= cnt_50Hz + 1;
                end
            end else begin
                pwm <= 1'b0;
                cnt_50Hz <= 0;
            end
        end
    end


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            cstate <= IDLE;
            pwm_en <= 1'b0;
            direction <= 0;
            rotating_time_cnt <= 0;
            mean_start <= 1'b0;
            scan_done <= 1'b0;
            counter_rotate_time_buffer <= 0;
            counter_rotate_done <= 1'b0;
        end else begin
            case (cstate)
                IDLE: begin
                    led <= 5'b00001;
                    pwm_en <= 1'b0;
                    mean_start <= 1'b0;
                    direction <= 0;
                    counter_rotate_done <= 1'b0;
                    if (focus_start == 1'b1) begin
                        cstate <= START;
                    end else if (rotate2idle) begin
                        cstate <= ROTATE2IDLE;
                    end else begin
                        cstate <= IDLE;
                    end
                end

                START: begin
                    led <= 5'b00010;
                    scan_done <= 1'b0;
                    if (rotating_time_cnt == 0) begin
                        cstate <= SCAN;
                        mean_start <= 1'b1;
                    end else begin
                        if (rotating_time_cnt == 0) begin
                            cstate <= SCAN;
                            mean_start <= 1'b1;
                        end else begin
                            pwm_en <= 1'b1;
                            mean_start <= 1'b0;
                            direction <= CCW;
                            rotating_time_cnt <= rotating_time_cnt - 1;
                        end
                    end
                end

                SCAN: begin
                    led <= 5'b00100;
                    mean_start <= 1'b0;
                    if (rotating_time_cnt == MAX_ROTATING_TIME - 1) begin
                        cstate <= DONE;
                        pwm_en <= 1'b0;
                        direction <= 0;
                        scan_done <= 1'b1;
                    end else begin
                        pwm_en <= 1'b1;
                        direction <= CW;
                        rotating_time_cnt <= rotating_time_cnt + 1;
                    end
                end

                DONE: begin
                    led <= 5'b01000;
                    scan_done <= 1'b0;
                    if (focus_done == 1'b1) begin
                        counter_rotate_time_buffer <= counter_rotate_time;
                        rotating_time_cnt <= rotating_time_cnt - counter_rotate_time;
                        cstate <= COUNTER_ROTATE;
                    end else begin
                        cstate <= DONE;
                    end
                end

                COUNTER_ROTATE: begin
                    led <= 5'b1000;
                    if (counter_rotate_time_buffer == 0) begin
                        cstate <= IDLE;
                        pwm_en <= 1'b0;
                        direction <= 0;
                        counter_rotate_done <= 1'b1;
                    end else begin
                        counter_rotate_time_buffer <= counter_rotate_time_buffer - 1;
                        cstate <= COUNTER_ROTATE;
                        pwm_en <= 1'b1;
                        direction <= CCW;
                    end
                end

                ROTATE2IDLE: begin
                    if (rotating_time_cnt == 0) begin
                        cstate <= IDLE;
                        counter_rotate_done <= 1'b1;
                    end else begin
                        if (rotating_time_cnt == 0) begin
                            cstate <= IDLE;
                            pwm_en <= 1'B0;
                        end else begin
                            pwm_en <= 1'b1;
                            direction <= CCW;
                            rotating_time_cnt <= rotating_time_cnt - 1;
                        end
                    end
                end

            endcase
        end
    end
endmodule

module buzzer_PWM (
    input  logic clk,
    input  logic reset,
    input  logic counter_rotation_done,
    output logic PWM_signal
);

    typedef enum {
        IDLE,
        FS,
        STAY,
        SS
    } states;

    localparam DURATION = 3125000;
    localparam MI = 50600;
    localparam DO = 47700;

    states cstate;

    logic PWM;
    logic [$clog2(96025)-1 : 0] cnt;
    logic [$clog2(96025)-1 : 0] half_cnt;
    logic [$clog2(6250000)-1 : 0] duration_cnt;
    logic [$clog2(96025)-1 : 0] frequency_cnt;

    assign half_cnt = frequency_cnt >> 1;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            cnt <= 0;
            PWM_signal <= 1'b0;
        end else begin
            if (PWM == 1'b1) begin
                if (frequency_cnt == 0) begin
                    cnt <= 0;
                    PWM_signal <= 1'b0;
                end else begin
                    if (cnt <= half_cnt) begin
                        PWM_signal <= 1'b1;
                        cnt <= cnt + 1;
                    end
					else if((cnt > half_cnt) && (cnt < frequency_cnt))begin
                        PWM_signal <= 1'b0;
                        cnt <= cnt + 1;
                    end else if (cnt >= frequency_cnt) begin
                        PWM_signal <= 1'b0;
                        cnt <= 0;
                    end
                end
            end else begin
                cnt <= 0;
                PWM_signal <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            cstate <= IDLE;
            duration_cnt <= 0;
            PWM <= 1'b0;
        end else begin
            case (cstate)
                IDLE: begin
                    PWM <= 1'b0;
                    duration_cnt <= 0;
                    frequency_cnt <= 0;
                    if (counter_rotation_done) begin
                        cstate <= FS;
                    end else begin
                        cstate <= IDLE;
                    end
                end

                FS: begin
                    if (duration_cnt == DURATION - 1) begin
                        duration_cnt <= 0;
                        cstate <= STAY;
                        PWM <= 1'b0;
                    end else begin
                        duration_cnt <= duration_cnt + 1;
                        cstate <= FS;
                        PWM <= 1'b1;
                        frequency_cnt <= MI;
                    end
                end

                STAY: begin
                    cstate <= SS;
                    PWM <= 1'b0;
                end

                SS: begin
                    if (duration_cnt == DURATION - 1) begin
                        duration_cnt <= 0;
                        cstate <= IDLE;
                        PWM <= 1'b0;
                    end else begin
                        duration_cnt <= duration_cnt + 1;
                        cstate <= SS;
                        PWM <= 1'b1;
                        frequency_cnt <= DO;
                    end
                end
            endcase
        end
    end
endmodule

