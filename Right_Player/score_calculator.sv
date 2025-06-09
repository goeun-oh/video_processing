`timescale 1ns / 1ps

module score_calculator (
    input  logic       clk_25MHz,
    input  logic       reset,
    input  logic       collision_detected,
    input logic        is_ball_moving_right,
    input  logic [9:0] x_pixel,
    input  logic       game_start,
    output logic [7:0] score,
    input logic is_you_win

);

    typedef enum logic [1:0] { IDLE, START, STAY} state_e;

    state_e state, state_next;
    logic [7:0] score_reg, score_next;
    
    assign score = score_reg;

    always_ff @(posedge clk_25MHz or posedge reset ) begin
        if(reset || game_start) begin
            state <= IDLE;
            score_reg <= 0;
        end else begin
            state <= state_next;
            score_reg <= score_next;
        end
    end


    always_comb begin
        state_next = state;
        score_next = score_reg;
        case(state)
            IDLE: begin
               if(is_ball_moving_right) begin
                    state_next = START;  
               end 
            end
            START: begin
                if(is_you_win) begin
                    score_next = score_reg +1;
                    state_next = STAY;
                end
            end
            STAY: begin
                if(!is_ball_moving_right) begin
                    state_next = IDLE;
                end
            end
        endcase
    end

endmodule
