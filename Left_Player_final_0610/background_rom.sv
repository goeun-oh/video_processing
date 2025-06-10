`timescale 1ns/1ps
module background_rom(
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic [1:0] rand_ball,
    output logic [15:0] pixel_data
);

// 640x480 = 307,200 픽셀
    logic [15:0] bg_pingpong   [0:307199];
    logic [15:0] bg_soccer     [0:307199];
    logic [15:0] bg_basketball [0:307199];

    logic [18:0] addr;  // 640*480 = 19bit 주소면 충분

    assign addr = y_pixel * 320 + x_pixel;

    // 배경 이미지 불러오기
    initial begin
        $readmemh("bg_pingpong.mem",   bg_pingpong);
        $readmemh("bg_soccer.mem",     bg_soccer);
        $readmemh("bg_basketball.mem", bg_basketball);
    end

    // 공 종류에 따라 해당 배경에서 픽셀 읽기
    always_comb begin
        case (rand_ball)
            2'd0: pixel_data = bg_pingpong[addr];
            2'd1: pixel_data = bg_soccer[addr];
            2'd2: pixel_data = bg_basketball[addr];
            default: pixel_data = 16'h0000; // 기본: 검정
        endcase
    end
endmodule


