`timescale 1ns / 1ps

module Video_Display(
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic [15:0] camera_pixel,
    input logic [15:0] rom_pixel,
    input logic [6:0] score,

    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port,
    output logic [4:0] x_offset,
    output logic [4:0] y_offset,

    input logic [9:0] ball_x,  // 움직이는 공의 x 위치
    input logic [9:0] ball_y,  // 움직이는 공의 y 위치

    output logic is_hit_area
    );
    // 글자 위치 상수
    localparam int TEXT_X = 500;
    localparam int TEXT_Y = 20;
    // 폰트 관련 파라미터
    localparam int FONT_WIDTH = 8; // 글자 폭
    localparam int FONT_HEIGHT = 8; // 글자 높이

    parameter OVERLAY_X = 100;
    parameter OVERLAY_Y = 80;

    logic in_ball_overlay_area;
    logic [15:0] score_text;

    // overlay offset
    assign x_offset = x_pixel - ball_x;
    assign y_offset = y_pixel - ball_y;

    // overlay 영역 판단
    // h cnt 가 100 ~ 120, v cnt가 80 ~ 100 일 때, 참 
    assign in_ball_overlay_area = (x_pixel >= ball_x && x_pixel < ball_x + 20) &&
                             (y_pixel >= ball_y && y_pixel < ball_y + 20);

    assign in_score_overlay_area = (x_pixel >= TEXT_X && x_pixel < TEXT_X + 2*FONT_WIDTH) &&
            (y_pixel >= TEXT_Y && y_pixel < TEXT_Y + FONT_HEIGHT);

    // 최종 출력 픽셀 결정
    logic [15:0] display_pixel;
    always_comb begin
        if(in_ball_overlay_area && rom_pixel != 16'h0000) begin
            display_pixel = rom_pixel;
        end else if (in_score_overlay_area) begin
            display_pixel = score_text;
        end else begin
            display_pixel = camera_pixel;
        end
    end
    assign is_hit_area = (x_pixel >= ball_x) && (x_pixel < ball_x + 20) &&
                        (y_pixel >= ball_y) && (y_pixel < ball_y + 20);

    assign red_port   = display_pixel[15:12];
    assign green_port = display_pixel[10:7];
    assign blue_port  = display_pixel[4:1];

    logic [9:0] x_pos_text;
    logic [9:0] y_pos_text;
    logic [3:0] text_len;

    logic [3:0] digit1, digit2;    // 점수 자릿수 계산.
    logic [7:0] numbers [0:9]; // 0~9까지 숫자에 대한 픽셀 데이터

    logic [2:0] font_row;
    logic [2:0] font_column;
    logic [7:0] font_data;
    logic bit_on;   ///
    logic [3:0] current_digit;



    always_comb begin 
        digit1 = (score / 10) % 10; // 10의 자리
        digit2 = score % 10; // 1의 자리
        
        score_text = 16'h0000; // 검정색

        // 점수 출력 위치 내에 있을 때만 계산
        if (in_score_overlay_area) begin
            font_row = y_pixel[2:0]; // y_pixel - TEXT_Y
            font_column = x_pixel[2:0]; // x_pixel - (TEXT_X + ...)

            // 어떤 자리인지 계산
            if (x_pixel < TEXT_X + FONT_WIDTH)
                current_digit = (score >= 10) ? digit1 : 4'd0;
            else
                current_digit = digit2;

            font_data = font_rom(current_digit, font_row);
            bit_on = font_data[7 - font_column];

            if (bit_on)
                score_text = 16'hFFFF; // 흰색
        end
    end

    
    
    function automatic [7:0] font_rom(input logic [3:0] ch, input logic [2:0] row);
        case (ch)
            4'd0: case (row)
                3'd0: font_rom = 8'b00111100;
                3'd1: font_rom = 8'b01100110;
                3'd2: font_rom = 8'b01101110;
                3'd3: font_rom = 8'b01110110;
                3'd4: font_rom = 8'b01100110;
                3'd5: font_rom = 8'b01100110;
                3'd6: font_rom = 8'b00111100;
                3'd7: font_rom = 8'b00000000;
            endcase
            4'd1: case (row)
                3'd0: font_rom = 8'b00011000;
                3'd1: font_rom = 8'b00111000;
                3'd2: font_rom = 8'b00011000;
                3'd3: font_rom = 8'b00011000;
                3'd4: font_rom = 8'b00011000;
                3'd5: font_rom = 8'b00011000;
                3'd6: font_rom = 8'b01111110;
                3'd7: font_rom = 8'b00000000;
            endcase
            4'd2: case (row)
                3'd0: font_rom = 8'b00111100;
                3'd1: font_rom = 8'b01100110;
                3'd2: font_rom = 8'b00000110;
                3'd3: font_rom = 8'b00001100;
                3'd4: font_rom = 8'b00110000;
                3'd5: font_rom = 8'b01100000;
                3'd6: font_rom = 8'b01111110;
                3'd7: font_rom = 8'b00000000;
            endcase
            4'd3: case (row)
                3'd0: font_rom = 8'b00111100;
                3'd1: font_rom = 8'b01100110;
                3'd2: font_rom = 8'b00000110;
                3'd3: font_rom = 8'b00011100;
                3'd4: font_rom = 8'b00000110;
                3'd5: font_rom = 8'b01100110;
                3'd6: font_rom = 8'b00111100;
                3'd7: font_rom = 8'b00000000;
            endcase
            4'd4: case (row)
                3'd0: font_rom = 8'b00001100;
                3'd1: font_rom = 8'b00011100;
                3'd2: font_rom = 8'b00111100;
                3'd3: font_rom = 8'b01101100;
                3'd4: font_rom = 8'b01111110;
                3'd5: font_rom = 8'b00001100;
                3'd6: font_rom = 8'b00001100;
                3'd7: font_rom = 8'b00000000;
            endcase
            4'd5: case (row)
                3'd0: font_rom = 8'b01111110;
                3'd1: font_rom = 8'b01100000;
                3'd2: font_rom = 8'b01111100;
                3'd3: font_rom = 8'b00000110;
                3'd4: font_rom = 8'b00000110;
                3'd5: font_rom = 8'b01100110;
                3'd6: font_rom = 8'b00111100;
                3'd7: font_rom = 8'b00000000;
            endcase
            4'd6: case (row)
                3'd0: font_rom = 8'b00111100;
                3'd1: font_rom = 8'b01100000;
                3'd2: font_rom = 8'b01111100;
                3'd3: font_rom = 8'b01100110;
                3'd4: font_rom = 8'b01100110;
                3'd5: font_rom = 8'b01100110;
                3'd6: font_rom = 8'b00111100;
                3'd7: font_rom = 8'b00000000;
            endcase
            4'd7: case (row)
                3'd0: font_rom = 8'b01111110;
                3'd1: font_rom = 8'b00000110;
                3'd2: font_rom = 8'b00001100;
                3'd3: font_rom = 8'b00011000;
                3'd4: font_rom = 8'b00110000;
                3'd5: font_rom = 8'b00110000;
                3'd6: font_rom = 8'b00110000;
                3'd7: font_rom = 8'b00000000;
            endcase
            4'd8: case (row)
                3'd0: font_rom = 8'b00111100;
                3'd1: font_rom = 8'b01100110;
                3'd2: font_rom = 8'b01100110;
                3'd3: font_rom = 8'b00111100;
                3'd4: font_rom = 8'b01100110;
                3'd5: font_rom = 8'b01100110;
                3'd6: font_rom = 8'b00111100;
                3'd7: font_rom = 8'b00000000;
            endcase
            4'd9: case (row)
                3'd0: font_rom = 8'b00111100;
                3'd1: font_rom = 8'b01100110;
                3'd2: font_rom = 8'b01100110;
                3'd3: font_rom = 8'b00111110;
                3'd4: font_rom = 8'b00000110;
                3'd5: font_rom = 8'b00000110;
                3'd6: font_rom = 8'b00111100;
                3'd7: font_rom = 8'b00000000;
            endcase
            default: font_rom = 8'b00000000;
        endcase
    endfunction
endmodule
