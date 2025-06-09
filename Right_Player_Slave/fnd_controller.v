`timescale 1ns / 1ps

module fnd_controller (
    input clk, 
    input reset,
    input  [7:0] Digit,
    output [7:0] seg,
    output [3:0] seg_comm
);

    wire [3:0] w_digit1, w_digit10, w_digit100, w_digit1000;
    wire [3:0] w_bcd;
    wire [1:0] w_seg_sel;
    wire w_clk_100hz;

    clock_divider_fnd U_clock_divider_fnd(
        .clk(clk),
        .rst(reset),
        .o_clk(w_clk_100hz)
    );

    counter_4 U_counter_4(
        .clk(w_clk_100hz),
        .rst(rst),
        .count(w_seg_sel)
    );

    decoder_2x4 U_decoder_2x4(
        .seg_sel(w_seg_sel),
        .seg_comm(seg_comm)
    );

    digit_splitter U_digit_splitter(
        .bcd(Digit),
        .digit_1(w_digit1),
        .digit_10(w_digit10),
        .digit_100(w_digit100),
        .digit_1000(w_digit1000)
    );

    mux_4x1 U_mux_4x1(
    .sel(w_seg_sel),
    .digit_1(w_digit1),
    .digit_10(w_digit10),
    .digit_100(w_digit100),
    .digit_1000(w_digit1000),
    .bcd(w_bcd)
);

    bcdtoseg U_bcdtoseg (
        .bcd(w_bcd),
        .seg(seg)
    );

endmodule

module clock_divider_fnd (
    input clk, rst,
    output o_clk
);
    parameter COUNT = 500_000;
    reg [$clog2(COUNT)-1:0] r_counter;
    reg r_clk;
    assign o_clk = r_clk;
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            r_counter <= 0;
            r_clk <= 0;
        end else begin
            // clock divide 계산, 100MHz -> 200hz
            if (r_counter == COUNT - 1) begin 
                r_counter <= 0;
                r_clk <= 1; // r_clk : 0->1
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 0; // r_clk : 0으로 유지
            end
        end
    end
endmodule

module counter_4 (
    input clk, rst,
    output reg [1:0] count
);
    always @(posedge clk, posedge rst) begin 
        if (rst) begin
            count <= 0;
        end else begin
            count <= count + 1; 
        end 
    end

endmodule

module decoder_2x4 (
    input [1:0] seg_sel,
    output reg [3:0] seg_comm
); 
    // 2x4 decoder
    always @(seg_sel) begin
        case (seg_sel)
            2'b00: seg_comm = 4'b1110;
            2'b01: seg_comm = 4'b1101;
            2'b10: seg_comm = 4'b1011;
            2'b11: seg_comm = 4'b0111;
            default: seg_comm = 4'b1110;
        endcase

    end

endmodule

module digit_splitter (
    input [7:0] bcd,        // Data_digit
    output [3:0] digit_1, digit_10, digit_100, digit_1000
);
    
    assign digit_1 = bcd % 10; // 1의 자리
    assign digit_10 = bcd / 10 % 10; // 10의 자리
    assign digit_100 = bcd / 100 % 10; // 100의 자리
    assign digit_1000 = bcd / 1000 % 10; // 1000의 자리

endmodule

module mux_4x1 (
    input [1:0] sel,
    input [3:0] digit_1, digit_10, digit_100, digit_1000,
    output reg [3:0] bcd
);

    always @(sel, digit_1, digit_10, digit_100, digit_1000) begin
        case (sel)
            2'b00: bcd = digit_1;
            2'b01: bcd = digit_10;
            2'b10: bcd = digit_100;
            2'b11: bcd = digit_1000;
            default: bcd = 4'bx;
        endcase
    end

endmodule

module bcdtoseg (
    input [3:0] bcd,  // [7:0] SUM 값
    output reg [7:0] seg  
);

    always @(bcd) begin
        case (bcd)
            4'b0000: seg = 8'b11000000;  // 0
            4'b0001: seg = 8'b11111001;  // 1
            4'b0010: seg = 8'b10100100;  // 2
            4'b0011: seg = 8'b10110000;  // 3
            4'b0100: seg = 8'b10011001;  // 4
            4'b0101: seg = 8'b10010010;  // 5
            4'b0110: seg = 8'b10000010;  // 6
            4'b0111: seg = 8'b11111000;  // 7
            4'b1000: seg = 8'b10000000;  // 8
            4'b1001: seg = 8'b10010000;  // 9
            4'b1010: seg = 8'b10001000;  // A
            4'b1011: seg = 8'b10000011;  // b
            4'b1100: seg = 8'b11000110;  // C
            4'b1101: seg = 8'b10100001;  // d
            4'b1110: seg = 8'b10000110;  // E
            4'b1111: seg = 8'b10001110;  // F
            default: seg = 8'b11111111;
        endcase
    end
endmodule
