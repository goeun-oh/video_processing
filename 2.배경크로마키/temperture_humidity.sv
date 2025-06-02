`timescale 1ns / 1ps

module humidity_filter (
    input  logic        clk,
    input  logic        reset,
    input logic display_enable,
    input  logic [ 7:0] humi_data,
    input  logic [11:0] raw_pixel,
    output logic [11:0] filtered_pixel
);
    logic [11:0] gaussian_pixel;
    logic gaussian_sel;

     humidity_detect U_HUMIDITY_DETECT (
        .clk(clk),
        .reset(reset),
        .humi_data(humi_data),
        .gaussian_sel(gaussian_sel)
    );
    gaussian_filter_top U_Gaussian (
        .clk(clk),
        .pixel_in(raw_pixel),
        .display_enable(display_enable),
        .sigma(2'b10),
        .pixel_out(gaussian_pixel)        
    );

    mux U_MUX (
        .sel(gaussian_sel),
        .x0 (raw_pixel),
        .x1 (gaussian_pixel),
        .y  (filtered_pixel)    
    );
endmodule

module humidity_detect (
    input  logic        clk,
    input  logic        reset,
    input  logic [ 7:0] humi_data,
    output logic        gaussian_sel
);
    logic [1:0] state;
    localparam LOW_HUMI = 2'b00, MID_HUMI = 2'b01, HIGH_HUMI = 2'b10;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= MID_HUMI;
        end else begin
            if (humi_data <= 60) state = MID_HUMI;
            else if (humi_data > 60) state = HIGH_HUMI;
        end
    end

    always_comb begin
        case (state)
            MID_HUMI: begin
               gaussian_sel = 1'b0; 
            end
            HIGH_HUMI: begin
                gaussian_sel = 1'b1;
            end
            default: gaussian_sel = 1'b0; 
        endcase
    end

endmodule

module test_humi (
    input  logic       clk,
    input  logic       reset,
    input  logic       start,
    output logic [7:0] data
);
    logic btn_start;

    // 버튼 감지기
    btn_detector U_BTN_DECT (
        .clk(clk),
        .reset(reset),
        .btn(start),
        .rising_edge(btn_start),
        .falling_edge(),
        .both_edge()
    );

    // 온도 출력 모듈
    humi_out U_HUMI_OUT (
        .clk  (clk),
        .reset(reset),
        .start(btn_start),
        .data (data)
    );

endmodule

module humi_out (
    input logic clk,
    input logic reset,
    input logic start,
    output logic [7:0] data
);
    logic state;  // 1비트로 변경

    always_ff @(posedge clk or posedge reset) begin
        if (reset) 
            state <= 1'b0;
        else if (start) 
            state <= ~state;  // 토글 방식으로 변경
    end

    always_comb begin
        case (state)
            1'b0: data = 8'd40;
            1'b1: data = 8'd70;
            default: data = 8'd0;  // 안정적인 동작을 위해 default 값 추가
        endcase
    end

endmodule


module temperture_filter (
    input  logic        clk,
    input  logic        reset,
    input  logic [ 7:0] temp_data,
    input  logic [11:0] raw_pixel,
    output logic [11:0] filtered_pixel
);
    logic [1:0] state;
    logic [3:0] red_raw, green_raw, blue_raw;
    logic [3:0] red_filtered, green_filtered, blue_filtered;

    localparam LOW_TEMP = 2'b00, MID_TEMP = 2'b01, HIGH_TEMP = 2'b10;

    assign red_raw   = raw_pixel[11:8];
    assign green_raw = raw_pixel[7:4];
    assign blue_raw  = raw_pixel[3:0];

    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= MID_TEMP;
        else begin
            if (temp_data <= 25) state = LOW_TEMP;
            else if (temp_data > 25 && temp_data <= 29) state = MID_TEMP;
            else if (temp_data > 30) state = HIGH_TEMP;
        end
    end

    always_comb begin
        case (state)
            LOW_TEMP: begin
                red_filtered   = (red_raw < 4) ? 0 : red_raw - 4;
                green_filtered = (green_raw < 4) ? 0 : green_raw - 4;
                blue_filtered  = (blue_raw < 4) ? 0 : blue_raw - 4;
            end
            MID_TEMP: begin
                red_filtered   = red_raw;
                green_filtered = green_raw;
                blue_filtered  = blue_raw;
            end
            HIGH_TEMP: begin
                red_filtered   = (red_raw > 11) ? 15 : red_raw + 4;
                green_filtered = (green_raw > 11) ? 15 : green_raw + 4;
                blue_filtered  = (blue_raw > 11) ? 15 : blue_raw + 4;
            end
            default: begin
                red_filtered   = red_raw;
                green_filtered = green_raw;
                blue_filtered  = blue_raw;
            end
        endcase
    end


    assign filtered_pixel = {red_filtered, green_filtered, blue_filtered};
endmodule

module test_temp (
    input  logic       clk,
    input  logic       reset,
    input  logic       start,
    output logic [7:0] data
);
    logic btn_start;

    // 버튼 감지기
    btn_detector U_BTN_DECT (
        .clk(clk),
        .reset(reset),
        .btn(start),
        .rising_edge(btn_start),
        .falling_edge(),
        .both_edge()
    );

    // 온도 출력 모듈
    temp_out U_TEMP_OUT (
        .clk  (clk),
        .reset(reset),
        .start(btn_start),
        .data (data)
    );

endmodule

module temp_out (
    input logic clk,
    input logic reset,
    input logic start,
    output logic [7:0] data
);
    logic [1:0] state;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= 2'b00;
        else if (start) begin
            if (state == 2'b10) state <= 2'b00;
            else state <= state + 1;
        end
    end

    always_comb begin
        case (state)
            2'b00:   data = 8'd24;
            2'b01:   data = 8'd26;
            2'b10:   data = 8'd31;
            default: data = 8'd26;
        endcase
    end

endmodule