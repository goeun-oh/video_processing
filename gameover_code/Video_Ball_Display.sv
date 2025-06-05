module Video_Ball_Display(
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic [15:0] camera_pixel,
    input logic [15:0] rom_pixel,

    input logic [9:0] ball_x,
    input logic [9:0] ball_y,

    input logic [9:0] h_cnt,
    input logic [9:0] v_cnt,
    input logic [1:0] state,

    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port,
    output logic [4:0] x_offset,
    output logic [4:0] y_offset,

    output logic is_hit_area
);

    // GAME OVER 텍스트 출력 여부
    logic text_pixel_on;

    // TEXT OVERLAY 인스턴스
    text_overlay txt_overlay (
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .show_text(state == 2'd0),  // IDLE 상태 (FSM enum 값에 따라 수정 가능)
        .pixel_on(text_pixel_on)
    );

    // 공 기준 offset 계산
    assign x_offset = x_pixel - ball_x;
    assign y_offset = y_pixel - ball_y;

    // 공의 20x20 영역 내에 있는지 판별
    logic in_overlay_area;
    assign in_overlay_area = (x_pixel >= ball_x && x_pixel < ball_x + 20) &&
                             (y_pixel >= ball_y && y_pixel < ball_y + 20);

    assign is_hit_area = in_overlay_area;

    // 최종 출력 픽셀 계산
    logic [15:0] display_pixel;

    always_comb begin
        if (text_pixel_on) begin
            // GAME OVER 텍스트가 해당 좌표에 출력 중이면 → 빨간 글자
            red_port   = 4'hF;
            green_port = 4'h0;
            blue_port  = 4'h0;
        end else begin
            // 공에 해당하면 rom_pixel, 나머지는 camera_pixel
            display_pixel = (in_overlay_area && rom_pixel != 16'h0000) ? rom_pixel : camera_pixel;

            red_port   = display_pixel[15:12];
            green_port = display_pixel[10:7];
            blue_port  = display_pixel[4:1];
        end
    end

endmodule
