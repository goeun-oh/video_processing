`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/20 10:01:22
// Design Name: 
// Module Name: OV7670_Camera_CCTV
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module OV7670_Camera_CCTV (
    input  logic       clk,
    input  logic       reset,
    input  logic       start_button,     // 시작 버튼 추가
    input  logic       reset_button,     // 리셋 버튼 추가
    //OV7670 side
    output logic       xclk,
    input  logic       pclk,
    input  logic [7:0] ov7670_data,
    input  logic       href,
    input  logic       ov7670_v_sync,
    //RGB output 
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port,
    //sync out
    output logic       h_sync,
    output logic       v_sync,
    output logic       collision_detected,  // 충돌 감지 신호 추가
    output logic       game_over ,       // 게임 오버 상태 출력
    //sda.scl
    input logic i_btn,
    output logic SDA,
    output logic SCL

);

    logic clk_25MHz, clk_100MHz;
    assign xclk = clk_25MHz;
    logic we;
    logic [16:0] wAddr;
    logic [11:0] wData;
    logic [16:0] rAddr;
    logic [11:0] rData;
    logic display_enable;
    logic [9:0] x_pixel;
    logic [9:0] y_pixel;

    logic de;
    logic w_rising_edge;

    clk_wiz_0 U_VGA_Clk_25MHz (
        .clk_in1   (clk),
        .reset     (reset),      // input reset
        .clk_25MHz (clk_25MHz),  // output clk_25MHz
        .clk_100MHz(clk_100MHz)  // output clk_100MHz

    );

    vga_controller U_VGA_Controller (
        .clk           (clk_25MHz),
        .reset         (reset),
        .h_sync        (h_sync),
        .v_sync        (v_sync),
        .x_pixel       (x_pixel),
        .y_pixel       (y_pixel),
        .display_enable(display_enable)
    );

    // logic [9:0] debug_count;
    // logic [9:0] debug_CT;
    //  //ILA acting as osiloscpoe
    //  ila_0 U_ILA (
    //      .clk   (clk_100MHz),    // input wire clk
    //      .probe0(debug_count),          // input wire [0:0]  probe0  
    //      .probe1(debug_CT),          // input wire [0:0]  probe1 
    //      .probe2(clk_25MHz)   // input wire [7:0]  probe2 
    //  );

    ov7670_controller U_OV7670_Controller (
        .pclk       (pclk),
        .reset      (reset),
        .href       (href),
        .v_sync     (ov7670_v_sync),
        .ov7670_data(ov7670_data),
        .we         (we),
        .wAddr      (wAddr),
        .wData      (wData)
    );

    assign rAddr = ((y_pixel >> 1) * 320) + (x_pixel >> 1);  // 픽셀 주소 계산
    assign de = (x_pixel < 640) && (y_pixel < 480);          // 픽셀 유효 영역 검사

    frameBuffer U_FrameBuffer (
        .wclk (pclk),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk (clk_25MHz),
        .oe   (display_enable),
        .rAddr(rAddr),
        .rData(rData)
    );

    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // ++++++++++++++++++++++++++++++++++                 +++++++++++++++++++++++++++++++++++++++++++++
    // ++++++++++++++++++++++++++++++++++  게임 제어 구문  +++++++++++++++++++++++++++++++++++++++++++++
    // ++++++++++++++++++++++++++++++++++                 +++++++++++++++++++++++++++++++++++++++++++++
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    // 떨어지는 이미지 위치 제어를 위한 카운터
    logic target_color;
    logic [1:0] current_state;
    logic GEN_X;
    logic GEN_comp;
    logic [9:0] random_x;
    logic [9:0] drop_x_0;
    logic [9:0] drop_x_1;
    logic [9:0] drop_y_0;
    logic [9:0] drop_y_1;

    logic [9:0] drop_width;
    logic [9:0] drop_height;
    logic [9:0] area_pixel;
    logic is_drop_area_0;
    logic is_drop_area_1;


    //게임 제어 모듈 인스턴스
    game_controller U_game_controller (
        .clk_25MHz(clk_25MHz),
        .reset(reset),
        .start_button(start_button),
        .reset_button(reset_button),
        .collision_detected(collision_detected),
        //.drop_speed(DROP_SPEED),
        .drop_width(drop_width),
        .drop_height(drop_height),
        .game_over(game_over),
        .GEN_comp(GEN_comp),
        .random_x(random_x),

        // .drop_y(drop_y),
        .drop_x_0(drop_x_0),
        .drop_x_1(drop_x_1),
        .drop_y_0(drop_y_0),
        .drop_y_1(drop_y_1),
        .current_state(current_state),
        .GEN_X(GEN_X)


);

    // 충돌 감지 모듈 인스턴스
    Collision_Detector U_Collision_Detector (
        .clk_25MHz   (clk_25MHz),
        .reset       (reset),
        .x_pixel     (x_pixel),
        .y_pixel     (y_pixel),
        .target_color(target_color),
        .area_pixel(area_pixel),        //이미지 총 픽셀 수
        .is_drop_area_0(is_drop_area_0), //이미지 0 영역
        .is_drop_area_1(is_drop_area_1), //이미지 1 영역
        .current_state(current_state),
        .collision_detected   (collision_detected)
        
    );

    // 랜덤 숫자 발생기
    random_x_generator U_random_x_generator (
        .clk(clk_25MHz),
        .reset(reset),
        .drop_width(drop_width),
        .GEN_X(GEN_X),          //작동 신호
        .GEN_comp(GEN_comp),    // 완료 신호
        .random_x(random_x)
    );


    // 떨어지는 이미지 영역 생성 모듈 인스턴스
    Area_gen U_Area_gen(

    .x_pixel(x_pixel),
    .y_pixel(y_pixel),
    .drop_width(drop_width),
    .drop_height(drop_height),
    
    .drop_x_0(drop_x_0),
    .drop_x_1(drop_x_1),
    .drop_y_0(drop_y_0),
    .drop_y_1(drop_y_1),
    
    .area_pixel(area_pixel),   //이미지 총 픽셀 수
    .is_drop_area_0(is_drop_area_0),    //이미지 0 영역
    .is_drop_area_1(is_drop_area_1)     //이미지 1 영역


    );



    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    //RGB 생성 모듈 인스턴스
    RGB_gen U_RGB_gen (
        .rData        (rData),
        .de           (de),
        .reset        (reset),
        .clk_25MHz    (clk_25MHz),
        .x_pixel      (x_pixel),
        .y_pixel      (y_pixel),
        .drop_x_0     (drop_x_0),
        .drop_y_0     (drop_y_0),
        .drop_x_1     (drop_x_1),
        .drop_y_1     (drop_y_1),
        .is_drop_area_0(is_drop_area_0),
        .is_drop_area_1(is_drop_area_1),
        .target_color (target_color),

        .red_port     (red_port),
        .green_port   (green_port),
        .blue_port    (blue_port)
    );

    // SCCB 인터페이스 모듈 인스턴스
    SCCB_intf U_SCCB_intf (
       .clk(clk_100MHz),
       .reset(reset),
       .startSig(w_rising_edge),
       .SCL(SCL),
       .SDA(SDA)
    );

    //버튼 디버깅용 모듈 인스턴스
    btn_debounce U_btn_debounce (
        .clk(clk_100MHz),
        .reset(reset),
        .i_btn(i_btn),
        .o_rising_edge(w_rising_edge),
        .o_falling_edge(),
        .o_both_edge()
    );

endmodule

module RGB_gen (
    input logic [11:0] rData,
    input logic de,
    input logic reset,
    input logic clk_25MHz,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic [9:0] drop_x_0,
    input logic [9:0] drop_y_0,
    input logic [9:0] drop_x_1,
    input logic [9:0] drop_y_1,

    input logic is_drop_area_0,
    input logic is_drop_area_1,

    output logic target_color,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
);
    logic [3:0] red = rData[11:8];
    logic [3:0] green = rData[7:4];
    logic [3:0] blue = rData[3:0];
    
    // 크로마키 색상 검출 - OV7670_Controller 방식 적용
    //logic target_color;
    assign target_color = ((green > red) && (green > blue))  ;
                        
    logic [9:0] x_offset_0, y_offset_0, x_offset_1, y_offset_1;  
    assign x_offset_0 = (x_pixel >= drop_x_0 && x_pixel < drop_x_0 + 32) ? 
                        (x_pixel - drop_x_0) : 10'd0;
    assign y_offset_0 = (y_pixel >= drop_y_0 && y_pixel < drop_y_0 + 32) ? 
                        (y_pixel - drop_y_0) : 10'd0;
    
    assign x_offset_1 = x_pixel - drop_x_1;
    assign y_offset_1 = y_pixel - drop_y_1;


    // 떨어지는 이미지 픽셀 데이터
    logic [11:0] drop_image_pixel_0;
    logic [11:0] drop_image_pixel_1;

    // 이미지 ROM 인스턴스
    Drop_Image_ROM U_Drop_Image_ROM_0 (
        .x_offset(x_offset_0),
        .y_offset(y_offset_0),
        .pixel_data(drop_image_pixel_0)
    );

    Drop_Image_ROM U_Drop_Image_ROM_1 (
        .x_offset(x_offset_1),
        .y_offset(y_offset_1),
        .pixel_data(drop_image_pixel_1)
    );

    // 출력 할당 수정 
    assign red_port = de ? 
        (target_color ?                                                      // 크로마키 영역 확인인
            (is_drop_area_0 ? drop_image_pixel_0[7:4] : is_drop_area_1 ? drop_image_pixel_1[7:4] : 4'hF) : //네모 영역: 떨어지는 이미지 또는 흰색
            rData[11:8]) : 4'b0;                                             // 크로마키 아닌 영역: 카메라 이미지
    
    assign green_port = de ? 
        (target_color ?         
            (is_drop_area_0 ? drop_image_pixel_0[3:0] : is_drop_area_1 ? drop_image_pixel_1[3:0] : 4'hF) :   // 크로마키 영역: 떨어지는 이미지 또는 흰색
            rData[7:4]) : 4'b0;                                             // 크로마키 아닌 영역: 카메라 이미지
    
    assign blue_port = de ? 
        (target_color ? 
            (is_drop_area_0 ? drop_image_pixel_0[11:8] : is_drop_area_1 ? drop_image_pixel_1[11:8] : 4'hF) :   // 크로마키 영역: 떨어지는 이미지 또는 흰색
            rData[3:0]) : 4'b0;

endmodule


