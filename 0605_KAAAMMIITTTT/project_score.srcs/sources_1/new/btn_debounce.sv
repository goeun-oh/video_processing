`timescale 1ns / 1ps

module btn_debounce(
    input logic clk, // f/f를 쓰면 clk 필요
    input logic reset,
    input logic i_btn,
    output logic o_btn
    );


    // state
    // reg state, next;
    logic [7:0] q_reg, q_next;
    logic  btn_debounce;
    logic  edge_detect;

    // 1khz clk, state
    logic [$clog2(100_000)-1 :0 ] counter;
    logic r_1khz;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            counter <= 0;
            r_1khz <= 0;
        end else begin   
            if (counter == 100_000 - 1) begin
                counter <= 0;
                r_1khz <= 1'b1;
            end else begin // 1khz 1tick.
                // 다음번 카운트에는 현재 카운트 값에 1을 더해라
                counter <= counter + 1;
                r_1khz <= 1'b0; 
            end         
        end
    end


    // state logic, shift register
    always @(posedge r_1khz, posedge reset) begin
        if (reset) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;
        end
    end

    // next logic 조합논리
    always @(i_btn, r_1khz) begin // event i_btn, r_1khz
        // q_reg 현재의 상위 7bit를 다음 shift register의 하위 7비트에 넣고,
        // 최상위에는 i_btn을 넣어라
        q_next = {i_btn, q_reg[7:1]}; // 끝에 하나 버림(8shift동작)
    end

    // 8-input AND gate (shift register를 8썼기 때문에 8 input)
    assign btn_debounce = &q_reg;

    // edge _ detector , 100MHz
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            edge_detect <= 1'b0;
        end       
        else begin
            edge_detect <= btn_debounce;
        end 
    end

    // 최종 출력 
    assign o_btn = btn_debounce & (~edge_detect);
endmodule