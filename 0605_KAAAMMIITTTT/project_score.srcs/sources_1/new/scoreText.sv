`timescale 1ns / 1ps

module scoreText(
    input logic [7:0] score,  // 0~99 점수
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    output logic [11:0] score_text // 12bit RGB 출력 (흰색/검정색)
);

    // 텍스트 표시 위치 및 크기
    localparam int TEXT_X = 500;
    localparam int TEXT_Y = 40;
    localparam int FONT_WIDTH = 8;   // 원래 폰트 폭
    localparam int FONT_HEIGHT = 8;  // 원래 폰트 높이
    localparam int SCALE = 2;        // 확대 배율 (8x8 -> 16x16)

    // 점수 자리수 분리
    logic [3:0] digit_tens;
    logic [3:0] digit_ones;

    // ASCII 코드 (문자 '0' = 8'h30)
    logic [7:0] ascii_tens;
    logic [7:0] ascii_ones;

    // 폰트 관련 변수
    logic [2:0] font_row;      // 0~7 (폰트 세로 좌표)
    logic [2:0] font_col;      // 0~7 (폰트 가로 좌표)
    logic [7:0] font_data;
    logic bit_on;

    // 현재 출력할 자리(0=왼쪽,1=오른쪽)
    logic current_digit;

    always_comb begin
        score_text = 12'h000; // 기본 검정색

        digit_tens = score / 10;
        digit_ones = score % 10;

        ascii_tens = 8'h30 + digit_tens; // '0' + digit_tens
        ascii_ones = 8'h30 + digit_ones; // '0' + digit_ones

        // y축은 텍스트 높이 안에 있어야 함
        if (y_pixel >= TEXT_Y && y_pixel < TEXT_Y + FONT_HEIGHT * SCALE) begin
            // y_pixel 기준 폰트 원래 row (확대 비율 적용)
            font_row = (y_pixel - TEXT_Y) / SCALE;

            // x축은 텍스트 2글자 폭 안에 있어야 함
            if (x_pixel >= TEXT_X && x_pixel < TEXT_X + 2 * FONT_WIDTH * SCALE) begin
                // 현재 글자 구분 (0: 왼쪽 글자, 1: 오른쪽 글자)
                if (x_pixel < TEXT_X + FONT_WIDTH * SCALE)
                    current_digit = 0;
                else
                    current_digit = 1;

                // x_pixel 기준 폰트 원래 column (확대 비율 적용)
                font_col = ((x_pixel - TEXT_X) % (FONT_WIDTH * SCALE)) / SCALE;

                // 현재 자리 ASCII 코드 선택
                if (current_digit == 0)
                    font_data = font_rom(ascii_tens, font_row);
                else
                    font_data = font_rom(ascii_ones, font_row);

                // 폰트 데이터의 해당 bit가 켜져 있으면 흰색 출력
                bit_on = font_data[7 - font_col];
                if (bit_on)
                    score_text = 12'hFFF;
            end
        end
    end

    // ASCII 문자 8x8 폰트 (숫자 '0' ~ '9'만 정의)
    function automatic [7:0] font_rom(input logic [7:0] ch, input logic [2:0] row);
        begin
            case (ch)
                8'h30: // '0'
                    case(row)
                        3'd0: font_rom = 8'b00111100;
                        3'd1: font_rom = 8'b01100110;
                        3'd2: font_rom = 8'b01101110;
                        3'd3: font_rom = 8'b01110110;
                        3'd4: font_rom = 8'b01100110;
                        3'd5: font_rom = 8'b01100110;
                        3'd6: font_rom = 8'b00111100;
                        3'd7: font_rom = 8'b00000000;
                    endcase
                8'h31: // '1'
                    case(row)
                        3'd0: font_rom = 8'b00011000;
                        3'd1: font_rom = 8'b00111000;
                        3'd2: font_rom = 8'b00011000;
                        3'd3: font_rom = 8'b00011000;
                        3'd4: font_rom = 8'b00011000;
                        3'd5: font_rom = 8'b00011000;
                        3'd6: font_rom = 8'b01111110;
                        3'd7: font_rom = 8'b00000000;
                    endcase
                8'h32: // '2'
                    case(row)
                        3'd0: font_rom = 8'b00111100;
                        3'd1: font_rom = 8'b01100110;
                        3'd2: font_rom = 8'b00000110;
                        3'd3: font_rom = 8'b00001100;
                        3'd4: font_rom = 8'b00110000;
                        3'd5: font_rom = 8'b01100000;
                        3'd6: font_rom = 8'b01111110;
                        3'd7: font_rom = 8'b00000000;
                    endcase
                8'h33: // '3'
                    case(row)
                        3'd0: font_rom = 8'b00111100;
                        3'd1: font_rom = 8'b01100110;
                        3'd2: font_rom = 8'b00000110;
                        3'd3: font_rom = 8'b00011100;
                        3'd4: font_rom = 8'b00000110;
                        3'd5: font_rom = 8'b01100110;
                        3'd6: font_rom = 8'b00111100;
                        3'd7: font_rom = 8'b00000000;
                    endcase
                8'h34: // '4'
                    case(row)
                        3'd0: font_rom = 8'b00001100;
                        3'd1: font_rom = 8'b00011100;
                        3'd2: font_rom = 8'b00111100;
                        3'd3: font_rom = 8'b01101100;
                        3'd4: font_rom = 8'b01111110;
                        3'd5: font_rom = 8'b00001100;
                        3'd6: font_rom = 8'b00001100;
                        3'd7: font_rom = 8'b00000000;
                    endcase
                8'h35: // '5'
                    case(row)
                        3'd0: font_rom = 8'b01111110;
                        3'd1: font_rom = 8'b01100000;
                        3'd2: font_rom = 8'b01111100;
                        3'd3: font_rom = 8'b00000110;
                        3'd4: font_rom = 8'b00000110;
                        3'd5: font_rom = 8'b01100110;
                        3'd6: font_rom = 8'b00111100;
                        3'd7: font_rom = 8'b00000000;
                    endcase
                8'h36: // '6'
                    case(row)
                        3'd0: font_rom = 8'b00111100;
                        3'd1: font_rom = 8'b01100000;
                        3'd2: font_rom = 8'b01111100;
                        3'd3: font_rom = 8'b01100110;
                        3'd4: font_rom = 8'b01100110;
                        3'd5: font_rom = 8'b01100110;
                        3'd6: font_rom = 8'b00111100;
                        3'd7: font_rom = 8'b00000000;
                    endcase
                8'h37: // '7'
                    case(row)
                        3'd0: font_rom = 8'b01111110;
                        3'd1: font_rom = 8'b00000110;
                        3'd2: font_rom = 8'b00001100;
                        3'd3: font_rom = 8'b00011000;
                        3'd4: font_rom = 8'b00110000;
                        3'd5: font_rom = 8'b00110000;
                        3'd6: font_rom = 8'b00110000;
                        3'd7: font_rom = 8'b00000000;
                    endcase
                8'h38: // '8'
                    case(row)
                        3'd0: font_rom = 8'b00111100;
                        3'd1: font_rom = 8'b01100110;
                        3'd2: font_rom = 8'b01100110;
                        3'd3: font_rom = 8'b00111100;
                        3'd4: font_rom = 8'b01100110;
                        3'd5: font_rom = 8'b01100110;
                        3'd6: font_rom = 8'b00111100;
                        3'd7: font_rom = 8'b00000000;
                    endcase
                8'h39: // '9'
                    case(row)
                        3'd0: font_rom = 8'b00111100;
                        3'd1: font_rom = 8'b01100110;
                        3'd2: font_rom = 8'b01100110;
                        3'd3: font_rom = 8'b00111110;
                        3'd4: font_rom = 8'b00000110;
                        3'd5: font_rom = 8'b00000110;
                        3'd6: font_rom = 8'b00111100;
                        3'd7: font_rom = 8'b00000000;
                    endcase
                default:
                    font_rom = 8'b00000000;
            endcase
        end
    endfunction

endmodule
