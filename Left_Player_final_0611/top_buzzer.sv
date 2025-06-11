`timescale 1ns / 1ps

module top_buzzer (
    input  logic clk,           // 100MHz
    input  logic buzzer_on,          // collusion detect
    output logic buzzer_out            // 부저 출력
);

    logic enable;
    logic [31:0] half_cycle;

    always_comb begin
        if (buzzer_on) begin
            enable = 1;
            half_cycle = 25000;     // 1kHz: 100MHz / (1kHz * 2)
        end
        else begin
            enable = 0;
            half_cycle = 0;
        end
    end

    buzzer buzzer_inst (
        .clk(clk),
        .enable(enable),
        .half_cycle(half_cycle),
        .buzzer_out(buzzer_out)
    );
endmodule



module buzzer (
    input  logic clk,                // 25 Mhz
    input  logic enable,             // 부저 ON/OFF 제어 신호
    input  logic [31:0] half_cycle,  // 주파수 제어용 반주기 값
    output logic buzzer_out          // 부저 출력
);

    logic [31:0] counter = 0;
    logic tone = 0;

    always_ff @(posedge clk) begin
        if (enable) begin
            if (counter == half_cycle - 1) begin
                counter <= 0;
                tone <= ~tone;
            end
            else begin
                counter <= counter + 1;
            end
        end
        else begin
            counter <= 0;
            tone <= 0;
        end
    end

    always_ff @(posedge clk) begin
        buzzer_out <= tone;
    end
endmodule

module buzzer_trigger (
    input logic clk,
    input logic reset,
    input logic trigger,       // collision_detected 같은 단발 펄스
    output logic buzzer_on     // 일정 시간 하이 유지
);
    localparam DURATION = 625_000; // 100MHz 기준 약 50ms (원하는 시간 설정)
    logic [22:0] counter;
    logic active;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
            active <= 0;
        end
        else begin
            if (trigger) begin
                counter <= DURATION;
                active <= 1;
            end
            else if (counter != 0) begin
                counter <= counter - 1;
                active <= 1;
            end
            else begin
                active <= 0;
            end
        end
    end

    assign buzzer_on = active;

endmodule
