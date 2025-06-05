
module text_overlay (
    input  logic [9:0] h_cnt, v_cnt,    // VGA 카운터
    input  logic       show_text,       // 출력 활성화 조건 (예: state == IDLE)
    output logic       pixel_on         // 현재 픽셀이 글자에 해당하면 1
);
    // GAME OVER는 총 9자
    // 글자 하나는 8x8, 전체 72픽셀 너비
    localparam TEXT_X_START = 160;
    localparam TEXT_Y_START = 120;

    logic [6:0] text_ascii [0:8];
    initial begin
        text_ascii[0] = "G";
        text_ascii[1] = "A";
        text_ascii[2] = "M";
        text_ascii[3] = "E";
        text_ascii[4] = " ";
        text_ascii[5] = "O";
        text_ascii[6] = "V";
        text_ascii[7] = "E";
        text_ascii[8] = "R";
    end

    logic [3:0] char_col, char_row;
    logic [2:0] font_row;
    logic [2:0] font_col;

    logic [7:0] glyph_line;
    logic [6:0] char_code;

    font_rom font_inst (
        .char_code(char_code),
        .row_index(font_row),
        .row_data(glyph_line)
    );

    always_comb begin
        pixel_on = 0;

        if (show_text &&
            v_cnt >= TEXT_Y_START && v_cnt < TEXT_Y_START + 16 &&
            h_cnt >= TEXT_X_START && h_cnt < TEXT_X_START + 144) begin

            // 2배 확대된 텍스트 처리
            char_col = (h_cnt - TEXT_X_START) / 16;
            font_col = ((h_cnt - TEXT_X_START) % 16) / 2;

            char_row = (v_cnt - TEXT_Y_START) / 16;
            font_row = ((v_cnt - TEXT_Y_START) % 16) / 2;

            char_code = text_ascii[char_col];
            pixel_on = glyph_line[7 - font_col];
        end
    end
endmodule

