`timescale 1ns / 1ps

module ball_rom(
    input logic [9:0] x_offset,
    input logic [9:0] y_offset,
    output logic [15:0] pixel_data
);
    logic [15:0] rom_data [0:1023];  // 32x32 = 1024 픽셀 필요

    initial begin
        $readmemh("ball.mem", rom_data); 
    end

    // 32x32 이미지를 위해 하위 5비트만 사용
    //assign pixel_data = rom_data[{y_offset[4:0], x_offset[4:0]}];  // 5비트씩 사용하여 32x32 주소 지정
    assign pixel_data = rom_data[{y_offset[4:0]*20 + x_offset}];  //20x20
endmodule