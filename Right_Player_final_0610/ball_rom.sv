`timescale 1ns / 1ps

module ball_rom(
    input logic [9:0] x_offset,
    input logic [9:0] y_offset,
    input logic [1:0] rand_ball,
    output logic [15:0] pixel_data
);
    logic [15:0] rom_pingpong [0:1023];  // 32x32 = 1024 픽셀 필요
    logic [15:0] rom_soccer [0:1600];  // 32x32 = 1024 픽셀 필요
    logic [15:0] rom_basketball [0:4096];  // 32x32 = 1024 픽셀 필요

    initial begin
        $readmemh("ball.mem", rom_pingpong); 
        $readmemh("soccerBall.mem", rom_soccer); 
        $readmemh("BasketBall.mem", rom_basketball); 
    end

    // 32x32 이미지를 위해 하위 5비트만 사용
    //assign pixel_data = rom_data[{y_offset[4:0], x_offset[4:0]}];  // 5비트씩 사용하여 32x32 주소 지정
    always_comb begin
        if (rand_ball == 0) begin
            pixel_data = rom_pingpong[{y_offset[4:0]*20 + x_offset}]; 
        end
        else if (rand_ball == 1) begin
            pixel_data = rom_soccer[{y_offset[5:0]*40 + x_offset}]; 
        end
        else begin
            pixel_data = rom_basketball[{y_offset[5:0]*64 + x_offset}]; 
        end
    end
endmodule