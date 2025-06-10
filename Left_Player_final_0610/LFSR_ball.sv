`timescale 1ns / 1ps

module LFSR_ball(
    input logic clk,
    input logic reset,
    input logic rand_en,
    output logic [1:0] rand_ball,  // 2비트지만 값은 0,1,2 중 하나

    input logic player_1or2
);
    logic [7:0] lfsr;
    logic feedback;

    assign feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            lfsr <= 8'b10101010;  // 초기 시드값 (임의 지정)
            rand_ball <= 2'd0;
        end
        else begin
            if (player_1or2) begin // 2인 player
                rand_ball <= 2'b0;
            end
            else begin // 1인 player
                if (rand_en) begin
                    lfsr <= {lfsr[6:0], feedback};
                    rand_ball <= lfsr[2:0] % 3; 
                end
            end
        end
    end
endmodule

