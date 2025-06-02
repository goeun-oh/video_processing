`timescale 1ns / 1ps

module gaussian_filter_top (
    input  logic        clk,
    input  logic [11:0] pixel_in,        // 입력 픽셀 (스트리밍 방식)
    input  logic        display_enable,
    input  logic [ 1:0] sigma,
    output logic [11:0] pixel_out        // 가우시안 필터 적용된 출력
);

    // 5×5 윈도우 픽셀 데이터
    logic [11:0] data_00, data_01, data_02, data_03, data_04;
    logic [11:0] data_10, data_11, data_12, data_13, data_14;
    logic [11:0] data_20, data_21, data_22, data_23, data_24;
    logic [11:0] data_30, data_31, data_32, data_33, data_34;
    logic [11:0] data_40, data_41, data_42, data_43, data_44;

    // **(1) 라인 버퍼 모듈 (Shift Register 방식)**
    line_buffer line_buffer_inst (
        .clk(clk),
        .pixel_in(pixel_in),
        .display_enable(display_enable),
        .data_00(data_00),
        .data_01(data_01),
        .data_02(data_02),
        .data_03(data_03),
        .data_04(data_04),
        .data_10(data_10),
        .data_11(data_11),
        .data_12(data_12),
        .data_13(data_13),
        .data_14(data_14),
        .data_20(data_20),
        .data_21(data_21),
        .data_22(data_22),
        .data_23(data_23),
        .data_24(data_24),
        .data_30(data_30),
        .data_31(data_31),
        .data_32(data_32),
        .data_33(data_33),
        .data_34(data_34),
        .data_40(data_40),
        .data_41(data_41),
        .data_42(data_42),
        .data_43(data_43),
        .data_44(data_44)
    );

    // **(2) 가우시안 필터 모듈**
    gaussian_filter gaussian_filter_inst (
        .clk(clk),
        .data_00(data_00),
        .data_01(data_01),
        .data_02(data_02),
        .data_03(data_03),
        .data_04(data_04),
        .data_10(data_10),
        .data_11(data_11),
        .data_12(data_12),
        .data_13(data_13),
        .data_14(data_14),
        .data_20(data_20),
        .data_21(data_21),
        .data_22(data_22),
        .data_23(data_23),
        .data_24(data_24),
        .data_30(data_30),
        .data_31(data_31),
        .data_32(data_32),
        .data_33(data_33),
        .data_34(data_34),
        .data_40(data_40),
        .data_41(data_41),
        .data_42(data_42),
        .data_43(data_43),
        .data_44(data_44),
        .scale_factor(sigma),
        .pixel_out(pixel_out)
    );

endmodule

module line_buffer (
    input  logic        clk,
    input  logic        display_enable,
    input  logic [11:0] pixel_in,
    output logic [11:0] data_00,
    output logic [11:0] data_01,
    output logic [11:0] data_02,
    output logic [11:0] data_03,
    output logic [11:0] data_04,
    output logic [11:0] data_10,
    output logic [11:0] data_11,
    output logic [11:0] data_12,
    output logic [11:0] data_13,
    output logic [11:0] data_14,
    output logic [11:0] data_20,
    output logic [11:0] data_21,
    output logic [11:0] data_22,
    output logic [11:0] data_23,
    output logic [11:0] data_24,
    output logic [11:0] data_30,
    output logic [11:0] data_31,
    output logic [11:0] data_32,
    output logic [11:0] data_33,
    output logic [11:0] data_34,
    output logic [11:0] data_40,
    output logic [11:0] data_41,
    output logic [11:0] data_42,
    output logic [11:0] data_43,
    output logic [11:0] data_44
);

    // 5줄을 저장하는 Shift Register
    logic [11:0] line_buffer1[0:640-1];
    logic [11:0] line_buffer2[0:640-1];
    logic [11:0] line_buffer3[0:640-1];
    logic [11:0] line_buffer4[0:640-1];
    logic [11:0] line_buffer5[0:640-1];

    // 현재 줄의 5픽셀 이동을 위한 Shift Register
    logic [11:0] shift_reg[0:4];

    always_ff @(posedge clk) begin
        integer i;
        if (display_enable) begin
            // **라인 버퍼 시프트**
            for (i = 640 - 1; i > 0; i = i - 1) begin
                line_buffer1[i] <= line_buffer1[i-1];
                line_buffer2[i] <= line_buffer2[i-1];
                line_buffer3[i] <= line_buffer3[i-1];
                line_buffer4[i] <= line_buffer4[i-1];
                line_buffer5[i] <= line_buffer5[i-1];
            end
            line_buffer1[0] <= shift_reg[4];
            line_buffer2[0] <= line_buffer1[639];
            line_buffer3[0] <= line_buffer2[639];
            line_buffer4[0] <= line_buffer3[639];
            line_buffer5[0] <= line_buffer4[639];

            // **현재 줄 시프트 레지스터**
            shift_reg[4] <= shift_reg[3];
            shift_reg[3] <= shift_reg[2];
            shift_reg[2] <= shift_reg[1];
            shift_reg[1] <= shift_reg[0];
            shift_reg[0] <= pixel_in;
        end
    end

    // **출력 5×5 윈도우**
    assign data_00 = line_buffer5[639];
    assign data_01 = line_buffer5[638];
    assign data_02 = line_buffer5[637];
    assign data_03 = line_buffer5[636];
    assign data_04 = line_buffer5[635];

    assign data_10 = line_buffer4[639];
    assign data_11 = line_buffer4[638];
    assign data_12 = line_buffer4[637];
    assign data_13 = line_buffer4[636];
    assign data_14 = line_buffer4[635];

    assign data_20 = line_buffer3[639];
    assign data_21 = line_buffer3[638];
    assign data_22 = line_buffer3[637];
    assign data_23 = line_buffer3[636];
    assign data_24 = line_buffer3[635];

    assign data_30 = line_buffer2[639];
    assign data_31 = line_buffer2[638];
    assign data_32 = line_buffer2[637];
    assign data_33 = line_buffer2[636];
    assign data_34 = line_buffer2[635];

    assign data_40 = line_buffer1[639];
    assign data_41 = line_buffer1[638];
    assign data_42 = line_buffer1[637];
    assign data_43 = line_buffer1[636];
    assign data_44 = line_buffer1[635];

endmodule

module gaussian_filter (
    input  logic        clk,
    input  logic [11:0] data_00,
    input  logic [11:0] data_01,
    input  logic [11:0] data_02,
    input  logic [11:0] data_03,
    input  logic [11:0] data_04,
    input  logic [11:0] data_10,
    input  logic [11:0] data_11,
    input  logic [11:0] data_12,
    input  logic [11:0] data_13,
    input  logic [11:0] data_14,
    input  logic [11:0] data_20,
    input  logic [11:0] data_21,
    input  logic [11:0] data_22,
    input  logic [11:0] data_23,
    input  logic [11:0] data_24,
    input  logic [11:0] data_30,
    input  logic [11:0] data_31,
    input  logic [11:0] data_32,
    input  logic [11:0] data_33,
    input  logic [11:0] data_34,
    input  logic [11:0] data_40,
    input  logic [11:0] data_41,
    input  logic [11:0] data_42,
    input  logic [11:0] data_43,
    input  logic [11:0] data_44,
    input  logic [ 1:0] scale_factor,
    output logic [11:0] pixel_out
);

    // 가우시안 커널 기본 값
    logic [7:0] kernel[0:4][0:4];
    logic [9:0] kernel_sum;

    always_comb begin
        case (scale_factor)
            0: begin
                // 5x5 Gaussian kernel (sigma = 0)
                kernel[0][0] = 1;
                kernel[0][1] = 4;
                kernel[0][2] = 7;
                kernel[0][3] = 4;
                kernel[0][4] = 1;
                kernel[1][0] = 4;
                kernel[1][1] = 20;
                kernel[1][2] = 33;
                kernel[1][3] = 20;
                kernel[1][4] = 4;
                kernel[2][0] = 7;
                kernel[2][1] = 33;
                kernel[2][2] = 55;
                kernel[2][3] = 33;
                kernel[2][4] = 7;
                kernel[3][0] = 4;
                kernel[3][1] = 20;
                kernel[3][2] = 33;
                kernel[3][3] = 20;
                kernel[3][4] = 4;
                kernel[4][0] = 1;
                kernel[4][1] = 4;
                kernel[4][2] = 7;
                kernel[4][3] = 4;
                kernel[4][4] = 1;
                kernel_sum   = 331;
            end
            1: begin
                kernel[0][0] = 1;
                kernel[0][1] = 4;
                kernel[0][2] = 7;
                kernel[0][3] = 4;
                kernel[0][4] = 1;
                kernel[1][0] = 4;
                kernel[1][1] = 16;
                kernel[1][2] = 26;
                kernel[1][3] = 16;
                kernel[1][4] = 4;
                kernel[2][0] = 7;
                kernel[2][1] = 26;
                kernel[2][2] = 41;
                kernel[2][3] = 26;
                kernel[2][4] = 7;
                kernel[3][0] = 4;
                kernel[3][1] = 16;
                kernel[3][2] = 26;
                kernel[3][3] = 16;
                kernel[3][4] = 4;
                kernel[4][0] = 1;
                kernel[4][1] = 4;
                kernel[4][2] = 7;
                kernel[4][3] = 4;
                kernel[4][4] = 1;
                kernel_sum   = 273;
            end
            2: begin
                kernel[0][0] = 1;
                kernel[0][1] = 1;
                kernel[0][2] = 1;
                kernel[0][3] = 1;
                kernel[0][4] = 1;
                kernel[1][0] = 1;
                kernel[1][1] = 1;
                kernel[1][2] = 1;
                kernel[1][3] = 1;
                kernel[1][4] = 1;
                kernel[2][0] = 1;
                kernel[2][1] = 1;
                kernel[2][2] = 1;
                kernel[2][3] = 1;
                kernel[2][4] = 1;
                kernel[3][0] = 1;
                kernel[3][1] = 1;
                kernel[3][2] = 1;
                kernel[3][3] = 1;
                kernel[3][4] = 1;
                kernel[4][0] = 1;
                kernel[4][1] = 1;
                kernel[4][2] = 1;
                kernel[4][3] = 1;
                kernel[4][4] = 1;
                kernel_sum   = 25;
            end
            default: begin
                // 5x5 Gaussian kernel (sigma = 0)
                kernel[0][0] = 1;
                kernel[0][1] = 4;
                kernel[0][2] = 7;
                kernel[0][3] = 4;
                kernel[0][4] = 1;
                kernel[1][0] = 4;
                kernel[1][1] = 20;
                kernel[1][2] = 33;
                kernel[1][3] = 20;
                kernel[1][4] = 4;
                kernel[2][0] = 7;
                kernel[2][1] = 33;
                kernel[2][2] = 55;
                kernel[2][3] = 33;
                kernel[2][4] = 7;
                kernel[3][0] = 4;
                kernel[3][1] = 20;
                kernel[3][2] = 33;
                kernel[3][3] = 20;
                kernel[3][4] = 4;
                kernel[4][0] = 1;
                kernel[4][1] = 4;
                kernel[4][2] = 7;
                kernel[4][3] = 4;
                kernel[4][4] = 1;
                kernel_sum   = 331;
            end
        endcase
    end

    logic [31:0] sum_r, sum_g, sum_b;
    logic [3:0] r, g, b;

    always_ff @(posedge clk) begin
        sum_r <= (data_00[11:8] * kernel[0][0]) + (data_01[11:8] * kernel[0][1]) + (data_02[11:8] * kernel[0][2]) + (data_03[11:8] * kernel[0][3]) + (data_04[11:8] * kernel[0][4]) +
                 (data_10[11:8] * kernel[1][0]) + (data_11[11:8] * kernel[1][1]) + (data_12[11:8] * kernel[1][2]) + (data_13[11:8] * kernel[1][3]) + (data_14[11:8] * kernel[1][4]) +
                 (data_20[11:8] * kernel[2][0]) + (data_21[11:8] * kernel[2][1]) + (data_22[11:8] * kernel[2][2]) + (data_23[11:8] * kernel[2][3]) + (data_24[11:8] * kernel[2][4]) +
                 (data_30[11:8] * kernel[3][0]) + (data_31[11:8] * kernel[3][1]) + (data_32[11:8] * kernel[3][2]) + (data_33[11:8] * kernel[3][3]) + (data_34[11:8] * kernel[3][4]) +
                 (data_40[11:8] * kernel[4][0]) + (data_41[11:8] * kernel[4][1]) + (data_42[11:8] * kernel[4][2]) + (data_43[11:8] * kernel[4][3]) + (data_44[11:8] * kernel[4][4]);

        sum_g <= (data_00[7:4] * kernel[0][0]) + (data_01[7:4] * kernel[0][1]) + (data_02[7:4] * kernel[0][2]) + (data_03[7:4] * kernel[0][3]) + (data_04[7:4] * kernel[0][4]) +
                 (data_10[7:4] * kernel[1][0]) + (data_11[7:4] * kernel[1][1]) + (data_12[7:4] * kernel[1][2]) + (data_13[7:4] * kernel[1][3]) + (data_14[7:4] * kernel[1][4]) +
                 (data_20[7:4] * kernel[2][0]) + (data_21[7:4] * kernel[2][1]) + (data_22[7:4] * kernel[2][2]) + (data_23[7:4] * kernel[2][3]) + (data_24[7:4] * kernel[2][4]) +
                 (data_30[7:4] * kernel[3][0]) + (data_31[7:4] * kernel[3][1]) + (data_32[7:4] * kernel[3][2]) + (data_33[7:4] * kernel[3][3]) + (data_34[7:4] * kernel[3][4]) +
                 (data_40[7:4] * kernel[4][0]) + (data_41[7:4] * kernel[4][1]) + (data_42[7:4] * kernel[4][2]) + (data_43[7:4] * kernel[4][3]) + (data_44[7:4] * kernel[4][4]);

        sum_b <= (data_00[3:0] * kernel[0][0]) + (data_01[3:0] * kernel[0][1]) + (data_02[3:0] * kernel[0][2]) + (data_03[3:0] * kernel[0][3]) + (data_04[3:0] * kernel[0][4]) +
                 (data_10[3:0] * kernel[1][0]) + (data_11[3:0] * kernel[1][1]) + (data_12[3:0] * kernel[1][2]) + (data_13[3:0] * kernel[1][3]) + (data_14[3:0] * kernel[1][4]) +
                 (data_20[3:0] * kernel[2][0]) + (data_21[3:0] * kernel[2][1]) + (data_22[3:0] * kernel[2][2]) + (data_23[3:0] * kernel[2][3]) + (data_24[3:0] * kernel[2][4]) +
                 (data_30[3:0] * kernel[3][0]) + (data_31[3:0] * kernel[3][1]) + (data_32[3:0] * kernel[3][2]) + (data_33[3:0] * kernel[3][3]) + (data_34[3:0] * kernel[3][4]) +
                 (data_40[3:0] * kernel[4][0]) + (data_41[3:0] * kernel[4][1]) + (data_42[3:0] * kernel[4][2]) + (data_43[3:0] * kernel[4][3]) + (data_44[3:0] * kernel[4][4]);

        r <= sum_r / kernel_sum;  // 정규화 (커널 합으로 나누기)
        g <= sum_g / kernel_sum;  // 정규화 (커널 합으로 나누기)
        b <= sum_b / kernel_sum;  // 정규화 (커널 합으로 나누기)

        pixel_out <= {r, g, b};
    end

endmodule
