`timescale 1ns / 1ps

module txt_vga (
    input logic capture_start,  // 버튼 눌림 여부(캡처 시작)
    input  logic [3:0]  txt_num,      
    input  logic [9:0]  h_pos_in,      // vga_controller 수평 위치
    input  logic [9:0]  v_pos_in,      // vga_controller 수직 위치
    output logic [11:0] txt_vga_out
);
    localparam int READY_LEN = 6;
    localparam int DIGIT_LEN = 1;
    localparam int END_LEN = 3;

    logic [9:0] text_start_x;
    logic [9:0] text_start_y;
    logic [3:0] text_len; 

    always_comb begin
        case (txt_num)
            4'd0, 4'd1, 4'd2: begin
                text_len    = READY_LEN;
                text_start_x = 296;
                text_start_y = 236;
            end
            4'd3, 4'd4, 4'd5,
             4'd6, 4'd7, 4'd8, 
             4'd9, 4'd10, 4'd11, 
             4'd12, 4'd13, 4'd14 : begin
                text_len    = DIGIT_LEN;
                text_start_x = 316;
                text_start_y = 236;
            end
            4'd15: begin
                text_len    = END_LEN;
                text_start_x = 308;
                text_start_y = 236;
            end
            default: begin
                text_len    = 0;
                text_start_x = 0;
                text_start_y = 0;
            end
        endcase
    end

    logic [7:0] state_text[0:7]; 

    always_comb begin
        state_text[0] = 0;
        state_text[1] = 0;
        state_text[2] = 0;
        state_text[3] = 0;
        state_text[4] = 0;
        state_text[5] = 0;
        state_text[6] = 0;
        state_text[7] = 0;
        case (txt_num)
            4'd0, 4'd1, 4'd2: begin 
                state_text[0] = "R";
                state_text[1] = "E";
                state_text[2] = "A";
                state_text[3] = "D";
                state_text[4] = "Y";
                state_text[5] = "?";
            end
            4'd3: state_text[0] = "2";
            4'd4: state_text[0] = "1";
            4'd5: state_text[0] = "0";

            4'd6: state_text[0] = "2";
            4'd7: state_text[0] = "1";
            4'd8: state_text[0] = "0";

            4'd9:  state_text[0] = "2";
            4'd10: state_text[0] = "1";
            4'd11: state_text[0] = "0";

            4'd12: state_text[0] = "2";
            4'd13: state_text[0] = "1";
            4'd14: state_text[0] = "0";
            4'd15: begin 
                state_text[0] = "E";
                state_text[1] = "N";
                state_text[2] = "D";
            end
        endcase
    end

    function automatic [7:0] font_rom(input byte ch, input logic [2:0] row);
        case (ch)
            "R":
            case (row)
                3'd0: font_rom = 8'b11111000;
                3'd1: font_rom = 8'b10000100;
                3'd2: font_rom = 8'b10000100;
                3'd3: font_rom = 8'b11111000;
                3'd4: font_rom = 8'b10100000;
                3'd5: font_rom = 8'b10010000;
                3'd6: font_rom = 8'b10001000;
                3'd7: font_rom = 8'b10000100;
            endcase
            "E":
            case (row)
                3'd0: font_rom = 8'b11111100;
                3'd1: font_rom = 8'b10000000;
                3'd2: font_rom = 8'b10000000;
                3'd3: font_rom = 8'b11111000;
                3'd4: font_rom = 8'b10000000;
                3'd5: font_rom = 8'b10000000;
                3'd6: font_rom = 8'b10000000;
                3'd7: font_rom = 8'b11111100;
            endcase
            "A":
            case (row)
                3'd0: font_rom = 8'b01111000;
                3'd1: font_rom = 8'b10000100;
                3'd2: font_rom = 8'b10000100;
                3'd3: font_rom = 8'b11111100;
                3'd4: font_rom = 8'b10000100;
                3'd5: font_rom = 8'b10000100;
                3'd6: font_rom = 8'b10000100;
                3'd7: font_rom = 8'b10000100;
            endcase
            "D":
            case (row)
                3'd0: font_rom = 8'b11111000;
                3'd1: font_rom = 8'b10000100;
                3'd2: font_rom = 8'b10000100;
                3'd3: font_rom = 8'b10000100;
                3'd4: font_rom = 8'b10000100;
                3'd5: font_rom = 8'b10000100;
                3'd6: font_rom = 8'b10000100;
                3'd7: font_rom = 8'b11111000;
            endcase
            "Y":
            case (row)
                3'd0: font_rom = 8'b10000100;
                3'd1: font_rom = 8'b10000100;
                3'd2: font_rom = 8'b01001000;
                3'd3: font_rom = 8'b00110000;
                3'd4: font_rom = 8'b00110000;
                3'd5: font_rom = 8'b00110000;
                3'd6: font_rom = 8'b00110000;
                3'd7: font_rom = 8'b00110000;
            endcase
            "?":
            case (row)
                3'd0: font_rom = 8'b01111000;
                3'd1: font_rom = 8'b10000100;
                3'd2: font_rom = 8'b00001000;
                3'd3: font_rom = 8'b00010000;
                3'd4: font_rom = 8'b00100000;
                3'd5: font_rom = 8'b00000000;
                3'd6: font_rom = 8'b00100000;
                3'd7: font_rom = 8'b00100000;
            endcase
            "3":
            case (row)
                3'd0: font_rom = 8'b11111000;
                3'd1: font_rom = 8'b00000100;
                3'd2: font_rom = 8'b00000100;
                3'd3: font_rom = 8'b01111000;
                3'd4: font_rom = 8'b00000100;
                3'd5: font_rom = 8'b00000100;
                3'd6: font_rom = 8'b00000100;
                3'd7: font_rom = 8'b11111000;
            endcase
            "2":
            case (row)
                3'd0: font_rom = 8'b11111000;
                3'd1: font_rom = 8'b00000100;
                3'd2: font_rom = 8'b00000100;
                3'd3: font_rom = 8'b11111000;
                3'd4: font_rom = 8'b10000000;
                3'd5: font_rom = 8'b10000000;
                3'd6: font_rom = 8'b10000000;
                3'd7: font_rom = 8'b11111100;
            endcase
            "1":
            case (row)
                3'd0: font_rom = 8'b00110000;
                3'd1: font_rom = 8'b01110000;
                3'd2: font_rom = 8'b00110000;
                3'd3: font_rom = 8'b00110000;
                3'd4: font_rom = 8'b00110000;
                3'd5: font_rom = 8'b00110000;
                3'd6: font_rom = 8'b00110000;
                3'd7: font_rom = 8'b01111000;
            endcase
            "0":
            case (row)
                3'd0: font_rom = 8'b01111000;
                3'd1: font_rom = 8'b10000100;
                3'd2: font_rom = 8'b10001100;
                3'd3: font_rom = 8'b10010100;
                3'd4: font_rom = 8'b10100100;
                3'd5: font_rom = 8'b11000100;
                3'd6: font_rom = 8'b10000100;
                3'd7: font_rom = 8'b01111000;
            endcase
            "N":
            case (row)
                3'd0: font_rom = 8'b10000100;
                3'd1: font_rom = 8'b11000100;
                3'd2: font_rom = 8'b10100100;
                3'd3: font_rom = 8'b10010100;
                3'd4: font_rom = 8'b10001100;
                3'd5: font_rom = 8'b10000100;
                3'd6: font_rom = 8'b10000100;
                3'd7: font_rom = 8'b10000100;
            endcase
            default: font_rom = 8'b00000000;
        endcase
    endfunction

    assign h_pos = h_pos_in;
    assign v_pos = v_pos_in;
  
    logic [9:0] local_x, local_y;
    logic [2:0] row_idx;  
    logic [3:0] char_idx; 
    logic [7:0] font_line;

    always_comb begin
        txt_vga_out = 12'h000;
        if ((h_pos_in >= text_start_x) && (h_pos_in < text_start_x + text_len*8) &&
            (v_pos_in >= text_start_y) && (v_pos_in < text_start_y + 8)) begin
            local_x  = h_pos_in - text_start_x;
            local_y  = v_pos_in - text_start_y;
            char_idx = local_x[9:3];  
            row_idx  = local_y[2:0];  
            if (char_idx < text_len) begin
                font_line = font_rom(state_text[char_idx], row_idx);
                if (font_line[7-local_x[2:0]]) begin
                    txt_vga_out = 12'hfff;
                end else begin
                    txt_vga_out = 12'h111;
                end
            end
        end else begin
            txt_vga_out = 12'h000;
        end
    end

endmodule
