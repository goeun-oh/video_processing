`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/27 10:36:34
// Design Name: 
// Module Name: gaussian
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


module gaussian (
    input  logic        clk,
    input  logic        reset,
    input  logic [11:0] pixel_in,  // 입력 픽셀
    input  logic [16:0] addr,      // 현재 주소
    output logic [11:0] edge_out   // 에지 검출 결과
);
    logic [11:0] line_buffer[2:0][159:0]; // [2]: 이전 행, [1]: 현재 행, [0]: 다음 행(최신)

    logic [11:0] p[0:8];

    logic [7:0] row, col;
    assign row = addr / 160;  // 행: addr를 160으로 나눈 몫
    assign col = addr % 160;  // 열: addr를 160으로 나눈 나머지

    // valid 신호 한 클럭 지연

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 3; i++) begin
                for (int j = 0; j < 160; j++) begin
                    line_buffer[i][j] <= 0;
                end
            end
        end else begin
            line_buffer[2][col] <= line_buffer[1][col]; // 이전 행으로 이동
            line_buffer[1][col] <= line_buffer[0][col]; // 현재 행으로 이동
            line_buffer[0][col] <= pixel_in;      // 입력 픽셀의 상위 4비트를 저장
        end
    end

    // 3x3 윈도우 로드 (한 클럭 지연하여 p_next에 저장)
    always_ff @(posedge clk) begin
        // 윈도우의 위쪽 행 (line_buffer[2])
        p[0] <= (row == 0 || col == 0) ? 0 : line_buffer[2][col-1];
        p[1] <= (row == 0) ? 0 : line_buffer[2][col];
        p[2] <= (row == 0 || col == 159) ? 0 : line_buffer[2][col+1];

        // 윈도우의 중간 행 (line_buffer[1])
        p[3] <= (col == 0) ? 0 : line_buffer[1][col-1];
        p[4] <= line_buffer[1][col];
        p[5] <= (col == 159) ? 0 : line_buffer[1][col+1];

        // 윈도우의 아래쪽 행 (line_buffer[0])
        p[6] <= (col == 0) ? 0 : line_buffer[0][col-1];
        p[7] <= line_buffer[0][col];
        p[8] <= (col == 159) ? 0 : line_buffer[0][col+1];
    end

    logic [3:0] gx_red, gx_green, gx_blue;

    always_comb begin
        gx_red = ( (p[0][11:8] + p[2][11:8] + p[6][11:8] + p[8][11:8]) +
                         ((p[1][11:8] + p[3][11:8] + p[5][11:8] + p[7][11:8]) *2) +
                         ((p[4][11:8]) * 4) ) >>4;

        gx_green = ((p[0][7:4] + p[2][7:4] + p[6][7:4] + p[8][7:4]) +
                           ((p[1][7:4] + p[3][7:4] + p[5][7:4] + p[7][7:4]) * 2) +
                           ((p[4][7:4]) *4)) >>4;

        gx_blue = ((p[0][3:0] + p[2][3:0] + p[6][3:0] + p[8][3:0]) +
                          ((p[1][3:0] + p[3][3:0] + p[5][3:0] + p[7][3:0]) * 2) +
                          ((p[4][3:0]) * 4)) >>4;

        edge_out = {gx_red, gx_green, gx_blue};
    end



endmodule
