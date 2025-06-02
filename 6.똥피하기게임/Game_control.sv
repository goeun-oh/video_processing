`timescale 1ns / 1ps

module game_controller (
    input logic clk_25MHz,
    input logic reset,
    input logic start_button,
    input logic reset_button,
    input logic collision_detected,
    //input logic [19:0] drop_speed,
   // input logic [9:0] drop_width,
    input logic [9:0] drop_height,
    input logic [9:0] drop_width,
    input logic GEN_comp, // X좌표 랜덤생성 완료신호
    input logic [9:0] random_x,

    output logic game_over,
    // output logic [9:0] drop_y,
    output logic [9:0] drop_x_0,
    output logic [9:0] drop_x_1,
    output logic [9:0] drop_y_0,
    output logic [9:0] drop_y_1,

    output logic [1:0] current_state,
    output logic GEN_X // X좌표 랜덤생성 신호
);
    // 게임 상태 정의
    typedef enum logic [1:0] {
        IDLE = 2'b00,       // 대기 상태
        PLAYING = 2'b01,    // 게임 진행 중
        WAIT_FOR_GEN_X = 2'b10, // X좌표 랜덤생성 대기 상태
        GAME_OVER = 2'b11   // 게임 종료
    } game_state_t;

    logic [19:0] drop_counter;

    logic poop_1_start_flag;
    
    logic [19:0]drop_speed = 20'd500000;  // 떨어지는 속도를 더 빠르게 조정 (떨어지는 지연시간을 주는거라 작을수록 빨라짐)
                                          // 따지자면, N 시간 이후 1픽셀 떨어지세요 정하는거임

    game_state_t state;
    assign current_state = state;



    // 게임 상태 제어 로직
    always_ff @(posedge clk_25MHz) begin
        if (reset || reset_button) begin
            current_state <= IDLE;
            drop_x_0 <= 100;
            drop_x_1 <= 200;
            drop_y_0 <= 500; // 첫번째 떨어지는 물체의 Y좌표 (처음에는 화면 밖에 있음)
            drop_y_1 <= 500; // 두번째 떨어지는 물체의 Y좌표 (처음에는 화면 밖에 있음)
            poop_1_start_flag <= 0;
            drop_counter <= 0;
            game_over <= 0;
        end else begin
            case (current_state)
                IDLE: begin
                    if (start_button) begin
                            drop_y_0 <= 0;
                            drop_y_1 <= 500;
                            poop_1_start_flag <= 0;
                            drop_counter <= 0;
                            current_state <= PLAYING;
                    end
                    else begin
                        current_state <= IDLE;
                    end
                end
                
                PLAYING: begin                                      //****게임 시작***
                    if (collision_detected) begin
                        current_state <= GAME_OVER;
                        game_over <= 1;
                    end else if (drop_counter >= drop_speed) begin  // 떨어지는 타이밍 확인
                            drop_counter <= 0;                          //drop_counter: 이동 타이밍을 결정하는 타이머 역할
                                                                        //0에서 50000까지 세면서 "이제 움직여도 될 시간인지" 체크
                                                                        //일종의 딜레이/지연 생성기
                            if (drop_y_0 < 480 - drop_height) begin  // 바닥에 도달하지 않았으면 계속 떨어지는 중
                                drop_y_0 <= drop_y_0 + 1;  //계속 떨어지는 중                        
                                if (drop_y_0 >= 240 - drop_height) begin   // 1번 똥이 반쯤 갈때(?) 새로운 객체 등장.
                                    poop_1_start_flag <= 1;
                                end if(drop_y_0 >= 480 - drop_height -1) begin // 1번 똥이 바닥에 도달하면
                                    // drop_y_pos <= 500;  // 바닥에 도달하면 사라짐(화면 밖으로)
                                    drop_y_0 <= 0;  // 바닥에 도달하면 다시 올라감
                                    GEN_X <= 1; //바닥에 도달하면 랜덤 x 좌표 생성.
                                    drop_x_0 <= 0 + random_x;
                                    current_state <= WAIT_FOR_GEN_X;
                                end
                            end

                        if (poop_1_start_flag) begin  // 시작 플래그가 설정된 경우에만
                            drop_y_1 <= 0;  // 떨어지기 시작

                            if (drop_y_1 < 480 - drop_height) begin  // 바닥에 도달하지 않았으면
                            drop_y_1 <= drop_y_1 + 1;  // 계속 떨어짐
                            end
                            else if (drop_y_1 == 480 - drop_height) begin  // 바닥에 도달하면
                            drop_y_1 <= 0;  // 다시 위로
                                GEN_X <= 1;
                                drop_x_1 <= 0 + random_x;
                                current_state <= WAIT_FOR_GEN_X;
                            end
                        end
                    end
                    else begin
                        drop_counter <= drop_counter + 1;
                    end
                end
                //drop_y: 실제 물체의 Y축 위치를 나타내는 변수
                //0부터 시작해서 화면 끝까지 1씩 증가
                //실제 물체가 어디에 그려질지 결정

                WAIT_FOR_GEN_X: begin //x 랜덤생성을 위한 딜레이 스테이트
                    if (GEN_comp) begin //생성했으면 랜덤생성함수 종료 후 복귀
                        GEN_X <= 0;      
                        current_state <= PLAYING;
                    end else begin
                        current_state <= WAIT_FOR_GEN_X;
                    end
                end
                
                GAME_OVER: begin
                    if (reset_button) begin  // 재시작버튼 눌룸
                        current_state <= IDLE;
                        drop_y_0 <= 500;        //모든 drop 변수 초기화
                        drop_y_1 <= 500;
                        game_over <= 0;
                    end
                end
            endcase
        end
    end
endmodule


module Collision_Detector (
    input logic clk_25MHz,
    input logic reset,
    input logic [9:0] x_pixel,             // 픽셀 좌표
    input logic [9:0] y_pixel,             // 픽셀 좌표

    input logic [9:0] area_pixel,
    input logic is_drop_area_0,
    input logic is_drop_area_1,

    input logic [1:0] current_state,

    input logic target_color,

    output logic collision_detected        // 충돌 발생 신호

);
    logic [9:0] collision_pixel_count;

    logic [9:0] collision_threshold = 10'd100;  // 매우 낮은 값으로 테스트
    
    logic [9:0] prev_y; //이전 y 좌표 저장
    logic [9:0] current_x, current_y; //현재 x,y 좌표 저장

    
    // 네모 영역 체크
    // assign is_drop_area = (x_pixel >= drop_x) && (x_pixel < drop_x + drop_width) &&
    //                      (y_pixel >= drop_y) && (y_pixel < drop_y + drop_height);

    always_ff @(posedge clk_25MHz) begin
        if (reset) begin
            collision_pixel_count <= 0;
            collision_detected <= 0;
            current_x <= 0;
            current_y <= 0;

        end else if(current_state == 2'b00) begin
            collision_pixel_count <= 0;
            collision_detected <= 0;
            current_x <= 0;
            current_y <= 0;
            
        end else if(current_state == 2'b01) begin   //idle or start
            if (y_pixel < prev_y) begin
                collision_pixel_count <= 0;
                current_x <= 0;
                current_y <= 0;
            end
            
            // 단순화된 충돌 검사
            if ((is_drop_area_0 || is_drop_area_1) && !target_color) begin
                collision_pixel_count <= collision_pixel_count + 1'd1;
            end
            
            // 충돌 판정 (임계값 매우 낮게 설정)
            collision_detected <= (collision_pixel_count >= collision_threshold);

            current_x <= x_pixel; //현재 픽셀 좌표 저장(보험용)
            current_y <= y_pixel; //현재 픽셀 좌표 저장(보험용)
            prev_y <= y_pixel; //이전 y 좌표 저장
        end
    end


endmodule

module Area_gen(

input logic [9:0] x_pixel,
input logic [9:0] y_pixel,

input logic [9:0] drop_x_0,
input logic [9:0] drop_x_1,
input logic [9:0] drop_y_0,
input logic [9:0] drop_y_1,

output logic [9:0] area_pixel,
output logic [9:0] drop_width,
output logic [9:0] drop_height,

output logic is_drop_area_0,
output logic is_drop_area_1

);

    assign drop_width = 10'd32;   // 떨어지는 이미지 너비
    assign drop_height = 10'd32;  // 떨어지는 이미지 높이
    // assign drop_width = 10'd16;   // 떨어지는 이미지 너비
    // assign drop_height = 10'd16;  // 떨어지는 이미지 높이

    assign area_pixel = drop_width * drop_height;

    assign is_drop_area_0 = (x_pixel >= drop_x_0) && (x_pixel < drop_x_0 + drop_width) &&
                         (y_pixel >= drop_y_0) && (y_pixel < drop_y_0 + drop_height);

    assign is_drop_area_1 = (x_pixel >= drop_x_1) && (x_pixel < drop_x_1 + drop_width) &&
                         (y_pixel >= drop_y_1) && (y_pixel < drop_y_1 + drop_height);

endmodule


// 떨어지는 이미지를 위한 ROM 모듈
module Drop_Image_ROM (
    input logic [9:0] x_offset,
    input logic [9:0] y_offset,
    output logic [11:0] pixel_data
);
    //logic [11:0] rom_data [0:255];  // 16x16 = 256 픽셀 필요
    logic [11:0] rom_data [0:1023];  // 32x32 = 1024 픽셀 필요

    // ROM 초기화 - 꽉 찬 네모 모양
     //initial begin
     //    for (int i = 0; i < 64; i++) begin // 16x16 = 256 픽셀을 위해 64개 공간만 필요
     //      rom_data[i] = 12'hF00;  // 빨간색으로 꽉 찬 네모 (12'hF00 = 빨강, 12'h0F0 = 초록, 12'h00F = 파랑)
     //    end
     //end

    initial begin
        $readmemh("poop.mem", rom_data);  // 16진수 형식의 메모리 파일 읽기
    end

    // 32x32 이미지를 위해 하위 5비트만 사용
    assign pixel_data = rom_data[{y_offset[4:0], x_offset[4:0]}];  // 5비트씩 사용하여 32x32 주소 지정
endmodule


// 랜덤 x 좌표 생성 모듈
module random_x_generator (
    input  logic        clk,
    input  logic        reset,
    input  logic [9:0]  drop_width,
    input  logic        GEN_X,        // 랜덤 생성 신호
    output logic        GEN_comp,        // 랜덤 생성 완료 신호
    output logic [9:0]  random_x
);
    // LFSR(Linear Feedback Shift Register)를 사용한 의사 난수 생성
    logic [15:0] lfsr;
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            lfsr <= 16'hACE1;  // 초기값 설정
            random_x <= 0;
            GEN_comp <= 0;

        end else begin
            if (GEN_X) begin
                // LFSR 업데이트
                lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[14] ^ lfsr[12] ^ lfsr[3]};
                
                // 640-drop_width 범위 내의 값으로 매핑
                random_x <= (lfsr[9:0] % (600 - drop_width));
                GEN_comp <= 1;
            end
        end
    end
endmodule