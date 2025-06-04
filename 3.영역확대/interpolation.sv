`timescale 1ns / 1ps


module lineBuffer_origin (
    input  logic        clk,
    input  logic        reset,
    // write side
    output logic [16:0] rAddr_frame,
    input  logic [11:0] rData_frame,
    output logic        re_frame,
    input  logic        h_sync,
    input  logic        v_sync,
    input  logic [ 9:0] y_pixel,
    input  logic [ 9:0] x_pixel,
    // read side
    input  logic        rclk,
    input  logic        oe,
    input  logic [ 9:0] rAddr,
    output logic [11:0] rData
);

    logic [11:0] linebuffer[0 : (320- 1)];
    logic [9:0] temp_x, temp_y;
    logic full;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            temp_x <= 0;
            temp_y <= 0;
            re_frame <= 1'b0;
            rAddr_frame <= 0;
            full <= 0;
        end else begin
            if (v_sync == 1'b0) begin
                temp_x <= 0;
                temp_y <= 0;
                re_frame <= 1'b0;
                full <= 0;
            end else if (x_pixel >= 320) begin
                re_frame <= 1'b0;
                if (temp_x < 320 && temp_y < 240 && full == 1'b0) begin
                    re_frame <= 1'b1;
                    rAddr_frame <= temp_y * 320 + temp_x;
                    linebuffer[temp_x] <= rData_frame;
                    temp_x <= temp_x + 1;
                    temp_y <= temp_y;
                end else if (temp_x == 320 && full == 1'b0) begin
                    full   <= 1'b1;
                    temp_x <= 0;
                end else begin
                    temp_x <= temp_x;
                    temp_y <= temp_y;
                end
            end else begin
                full <= 1'b0;
                temp_x <= 0;
                re_frame <= 1'b0;
                if (temp_y == (y_pixel - 120)) begin  // temp_y update
                    temp_y <= temp_y + 1;
                end else begin
                    temp_y <= temp_y;
                end
            end
        end
    end

    // read side
    always_ff @(posedge rclk) begin
        if (oe) begin
            rData <= linebuffer[rAddr];
        end
    end

endmodule


module lineBuffer_linear (
    input  logic        clk,
    input  logic        reset,
    // region data
    input  logic [ 9:0] x_offset,
    input  logic [ 9:0] y_offset,
    // write side
    output logic [16:0] rAddr_frame,
    input  logic [11:0] rData_frame,
    output logic        re_frame,
    input  logic        h_sync,
    input  logic        v_sync,
    input  logic [ 9:0] y_pixel,
    // read side
    input  logic        rclk,
    input  logic        oe,
    input  logic [ 9:0] rAddr,
    output logic [11:0] rData
);

    logic [11:0] linebuffer[0 : (320- 1)];
    logic [9:0] temp_x, temp_y;
    logic [9:0] temp_x_offset, temp_y_offset;
    logic [10:0] waddr, prev_waddr;
    logic [4:0] temp_red, temp_green, temp_blue;
    logic full;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            temp_x <= 0;
            temp_y <= 0;
            waddr <= 0;
            prev_waddr <= 0;
            re_frame <= 1'b0;
            rAddr_frame <= 0;
            temp_red <= 0;
            temp_green <= 0;
            temp_blue <= 0;
            full <= 1'b0;
            temp_x_offset <= 0;
            temp_y_offset <= 0;
        end else begin
            if (v_sync == 1'b0) begin
                temp_x <= 0;
                temp_y <= 0;
                re_frame <= 1'b0;
                full <= 1'b0;
                temp_x_offset <= temp_x_offset;
                temp_y_offset <= temp_y_offset;
            end else if (h_sync == 1'b0) begin
                temp_x_offset <= temp_x_offset;
                temp_y_offset <= temp_y_offset;
                re_frame <= 1'b0;
                if (temp_x == 0 && temp_y < 60 && full == 1'b0) begin
                    full <= 1'b0;
                    re_frame <= 1'b1;
                    rAddr_frame <= (temp_y + temp_y_offset) * 320 + temp_x_offset;  // first bit store.
                    linebuffer[0] <= rData_frame;
                    temp_x <= temp_x + 1;
                    temp_y <= temp_y;
                end else if (temp_x < 80 && temp_y < 60 && full == 1'b0) begin
                    re_frame <= 1'b1;
                    rAddr_frame <= (temp_y + temp_y_offset) * 320 + (temp_x + temp_x_offset); // frame address
                    waddr <= temp_x << 2;
                    prev_waddr <= waddr - 4;
                    linebuffer[waddr] <= rData_frame;
                    temp_red <= ({1'b0, rData_frame[11:8]} + {1'b0, linebuffer[prev_waddr][11:8]});
                    temp_green <= ({1'b0, rData_frame[7:4]} + {1'b0, linebuffer[prev_waddr][7:4]});
                    temp_blue <= ({1'b0,rData_frame[3:0]} + {1'b0, linebuffer[prev_waddr][3:0]});
                    linebuffer[prev_waddr+2] <= {
                        temp_red[4:1], temp_green[4:1], temp_blue[4:1]
                    };
                    temp_x <= temp_x + 1;
                    temp_y <= temp_y;
                end else if (temp_x == 80 && temp_y < 60 && full == 1'b0) begin
                    full <= 1'b1;
                    re_frame <= 1'b1;
                    rAddr_frame <= (temp_y + temp_y_offset) * 320 + 79 + temp_x_offset;  // last bit store.
                    linebuffer[317] <= rData_frame;
                    linebuffer[318] <= rData_frame;
                    linebuffer[319] <= rData_frame;
                    temp_x <= 0;
                    temp_y <= temp_y;
                end else if (temp_x < 80 && temp_y < 60 && full == 1'b1) begin
                    temp_x <= temp_x + 1;
                    temp_y <= temp_y;
                    waddr <= temp_x << 2;
                    prev_waddr <= waddr - 4;
                    linebuffer[prev_waddr+1][11:8] <= ({1'b0,linebuffer[prev_waddr][11:8]} + {1'b0,linebuffer[prev_waddr + 2][11:8]}) >>1;
                    linebuffer[prev_waddr+1][7:4] <= ({1'b0, linebuffer[prev_waddr][7:4]} + {1'b0, linebuffer[prev_waddr + 2][7:4]})  >> 1;
                    linebuffer[prev_waddr+1][3:0] <= ({1'b0, linebuffer[prev_waddr][3:0]} + {1'b0, linebuffer[prev_waddr + 2][3:0]})  >> 1;
                    linebuffer[prev_waddr+3][11:8] <= ({1'b0,linebuffer[prev_waddr + 2][11:8]} + {1'b0,linebuffer[waddr][11:8]}) >>1;
                    linebuffer[prev_waddr+3][7:4] <= ({1'b0, linebuffer[prev_waddr + 2][7:4]} + {1'b0, linebuffer[waddr][7:4]})  >> 1;
                    linebuffer[prev_waddr+3][3:0] <= ({1'b0, linebuffer[prev_waddr + 2][3:0]} + {1'b0, linebuffer[waddr][3:0]})  >> 1;
                end else if (temp_x == 80 && temp_y < 60 && full == 1'b1) begin
                    full   <= 1'b0;
                    temp_x <= temp_x + 1;
                    temp_y <= temp_y;
                end else begin
                    temp_x <= temp_x;
                    temp_y <= temp_y;
                end
            end else begin // when h_sync == 1'b1
                temp_x_offset <= x_offset; // input x_offset latching
                temp_y_offset <= y_offset; // input y_offset latching
                temp_x <= 0;
                re_frame <= 1'b0;
                full <= 1'b0;
                if (temp_y == (y_pixel - 120) >> 2) begin  // temp_y update 
                    temp_y <= temp_y + 1;
                end else begin
                    temp_y <= temp_y;
                end
            end
        end
    end

    // read side
    always_ff @(posedge rclk) begin
        if (oe) begin
            rData <= linebuffer[rAddr];
        end
    end

endmodule

// module interpolation (
//     input  logic        clk,
//     input  logic        reset,
//     input  logic [ 1:0] mode,
//     input  logic [ 9:0] x_pixel,
//     input  logic [ 9:0] y_pixel,
//     // from frame buffer
//     output logic [16:0] rAddr,
//     input  logic [11:0] rData,
//     // out
//     output logic [11:0] rgb_port
// );
//     //x max 80, y max 60

//     // logic [11:0] temp, temp_next;

//     always_ff @(posedge clk, posedge reset) begin
//         if (reset) begin
//             rAddr <= 0;
//             rgb_port <= 0;
//             // temp <= 0;
//         end else begin
//             // temp <= temp_next;
//             if (x_pixel < 320 && y_pixel < 240) begin
//                 if (x_pixel[1:0] == 2'b00) begin
//                     rAddr <= x_pixel;
//                     rgb_port <= rData;
//                 end else begin
//                     case (mode)  // interpolation
//                         2'b00: begin
//                             rgb_port <= 12'h444;  // none
//                         end
//                         2'b01: begin  // copy
//                             rAddr <= {x_pixel[9:2], 2'b00};
//                             rgb_port <= rData;
//                         end
//                         2'b11: begin
//                             rAddr <= x_pixel;
//                             rgb_port <= rData;
//                         end
//                         default: rgb_port <= 12'h444;
//                     endcase
//                 end
//             end else begin  // else display area
//                 rgb_port <= 0;
//             end
//         end
//     end

// endmodule
