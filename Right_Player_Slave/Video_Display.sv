`timescale 1ns / 1ps

module Video_Display(
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic [15:0] camera_pixel,
    input logic [15:0] rom_pixel,
    input logic [7:0] score,

    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port,
    output logic [4:0] x_offset,
    output logic [4:0] y_offset,

    input logic [9:0] ball_x,  // 움직이는 공의 x 위치
    input logic [9:0] ball_y,  // 움직이는 공의 y 위치

    output logic is_hit_area,

    input logic game_over,
    input logic is_idle
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

    parameter OVERLAY_X = 100;
    parameter OVERLAY_Y = 80;


    // GAME OVER 텍스트 렌더링용 변수
    logic [15:0] game_over_pixel;
    logic [7:0] gameover_chars [0:8] = {8'h47, 8'h41, 8'h4D, 8'h45, 8'h20, 8'h4F, 8'h56, 8'h45, 8'h52}; // "G A M E   O V E R"
    logic [3:0] go_char_index;
    logic [2:0] go_font_row, go_font_col;
    logic [7:0] go_font_data;
    logic go_bit_on;

    localparam int GO_X = 250;
    localparam int GO_Y = 200;
    localparam int OVER_WIDTH = 8;
    localparam int OVER_HEIGHT = 8;
    localparam int OVER_SCALE = 2;

    // LOSE 텍스트
    logic [7:0] lose_chars [0:3] = {8'h4C, 8'h4F, 8'h53, 8'h45}; // "L", "O", "S", "E"
    logic [3:0] lose_char_index;
    logic [2:0] lose_font_row, lose_font_col;
    logic [7:0] lose_font_data;
    logic lose_bit_on;

    localparam int LOSE_X = 280;
    localparam int LOSE_Y = 200;

    logic in_ball_overlay_area;
    logic in_score_overlay_area;
    logic [15:0] score_text;

    // overlay offset
    assign x_offset = x_pixel - ball_x;
    assign y_offset = y_pixel - ball_y;

    // overlay 영역 판단
    // h cnt 가 100 ~ 120, v cnt가 80 ~ 100 일 때, 참 
    assign in_ball_overlay_area = (x_pixel >= ball_x && x_pixel < ball_x + 20) &&
                             (y_pixel >= ball_y && y_pixel < ball_y + 20);

    assign in_score_overlay_area = (y_pixel >= TEXT_Y && y_pixel < TEXT_Y + FONT_HEIGHT * SCALE) &&
            (x_pixel >= TEXT_X && x_pixel < TEXT_X + 2 * FONT_WIDTH * SCALE);

    // 최종 출력 픽셀 결정
    logic [15:0] display_pixel;

    always_comb begin
        if (game_over && game_over_pixel != 16'h0000) begin
            display_pixel = game_over_pixel;
        end else if (in_ball_overlay_area && rom_pixel != 16'h0000) begin
            if (is_idle) display_pixel = camera_pixel;
            else display_pixel = rom_pixel;
        end else if (in_score_overlay_area && in_score_overlay_area != 16'h0000) begin
            display_pixel = score_text;
        end else begin
            display_pixel = camera_pixel;
        end
    end


    // always_comb begin
    //     if(in_ball_overlay_area && rom_pixel != 16'h0000) begin
    //         display_pixel = rom_pixel;
    //     end else if (in_score_overlay_area) begin
    //         display_pixel = score_text;
    //     end else begin
    //         display_pixel = camera_pixel;
    //     end
    // end
    assign is_hit_area = (x_pixel >= ball_x) && (x_pixel < ball_x + 20) &&
                        (y_pixel >= ball_y) && (y_pixel < ball_y + 20);

    assign red_port   = display_pixel[15:12];
    assign green_port = display_pixel[10:7];
    assign blue_port  = display_pixel[4:1];


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


    function automatic [7:0] font_rom_lose(input logic [7:0] ch, input logic [2:0] row);
        begin
            case (ch)
                // L (ASCII 0x4C)
                8'h4C: case (row)
                    3'd0: font_rom_lose = 8'b01100000;
                    3'd1: font_rom_lose = 8'b01100000;
                    3'd2: font_rom_lose = 8'b01100000;
                    3'd3: font_rom_lose = 8'b01100000;
                    3'd4: font_rom_lose = 8'b01100000;
                    3'd5: font_rom_lose = 8'b01100000;
                    3'd6: font_rom_lose = 8'b01111110;
                    3'd7: font_rom_lose = 8'b00000000;
                endcase

                // O (ASCII 0x4F)
                8'h4F: case (row)
                    3'd0: font_rom_lose = 8'b00111100;
                    3'd1: font_rom_lose = 8'b01100110;
                    3'd2: font_rom_lose = 8'b01100110;
                    3'd3: font_rom_lose = 8'b01100110;
                    3'd4: font_rom_lose = 8'b01100110;
                    3'd5: font_rom_lose = 8'b01100110;
                    3'd6: font_rom_lose = 8'b00111100;
                    3'd7: font_rom_lose = 8'b00000000;
                endcase

                // S (ASCII 0x53)
                8'h53: case (row)
                    3'd0: font_rom_lose = 8'b00111110;
                    3'd1: font_rom_lose = 8'b01100000;
                    3'd2: font_rom_lose = 8'b01100000;
                    3'd3: font_rom_lose = 8'b00111100;
                    3'd4: font_rom_lose = 8'b00000110;
                    3'd5: font_rom_lose = 8'b00000110;
                    3'd6: font_rom_lose = 8'b01111100;
                    3'd7: font_rom_lose = 8'b00000000;
                endcase

                // E (ASCII 0x45)
                8'h45: case (row)
                    3'd0: font_rom_lose = 8'b01111110;
                    3'd1: font_rom_lose = 8'b01100000;
                    3'd2: font_rom_lose = 8'b01100000;
                    3'd3: font_rom_lose = 8'b01111100;
                    3'd4: font_rom_lose = 8'b01100000;
                    3'd5: font_rom_lose = 8'b01100000;
                    3'd6: font_rom_lose = 8'b01111110;
                    3'd7: font_rom_lose = 8'b00000000;
                endcase

                default: font_rom_lose = 8'b00000000;
            endcase
        end
    endfunction




   always_comb begin
        score_text = 16'h0000; // 기본 검정색

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
                    score_text = 16'hFFFF;
            end
        end
    end


    always_comb begin
        game_over_pixel = 16'h0000;

        if (game_over)begin // player 2p
                // --- LOSE 표시 로직 ---
            if ((y_pixel >= LOSE_Y && y_pixel < LOSE_Y + OVER_HEIGHT * OVER_SCALE) &&
                (x_pixel >= LOSE_X && x_pixel < LOSE_X + 4 * OVER_WIDTH * OVER_SCALE)) begin

                lose_font_row = (y_pixel - LOSE_Y) / SCALE;
                lose_font_col = ((x_pixel - LOSE_X) % (OVER_WIDTH * OVER_SCALE)) / OVER_SCALE;
                lose_char_index = (x_pixel - LOSE_X) / (OVER_WIDTH * OVER_SCALE);

                lose_font_data = font_rom_lose(lose_chars[lose_char_index], lose_font_row);
                lose_bit_on = lose_font_data[7 - lose_font_col];

                if (lose_bit_on)
                    game_over_pixel = 16'hF001;
            end
        end
    end




endmodule