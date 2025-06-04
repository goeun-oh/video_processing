`timescale 1ns / 1ps

module LineBuffer (
    input  logic        clk,        //25M clk
    input  logic        reset,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [11:0] upscale_data,   // upscale후의 데이터(640x480)
    output logic [11:0] out_linebuff       // 보간 후 최종출력
);

    logic [11:0] line1[0:639];
    logic [11:0] buffer_prev;
    logic [4:0] red_sum, green_sum, blue_sum;
    logic [4:0] red, green, blue;

    always_ff @(posedge clk, posedge reset) begin : blockName
        if (reset) begin
            buffer_prev <= 0;
        end else begin
            buffer_prev <= upscale_data;
            if (x_pixel < 640) begin
                if (x_pixel > 0) begin
                    line1[x_pixel] <= out_linebuff;
                end else begin  // x_pixel = 0
                    line1[x_pixel] <= upscale_data;
                end
            end
        end
    end

    always_comb begin
        if (x_pixel < 640 & y_pixel < 480) begin
            if ((x_pixel > 0) | (y_pixel > 0)) begin
                if (y_pixel[0] == 0) begin  // 가로줄(행)이 짝수
                    red_sum   = ({line1[x_pixel][11:8]} + {upscale_data[11:8]});
                    green_sum = ({line1[x_pixel][7:4]} + {upscale_data[7:4]});
                    blue_sum  = ({line1[x_pixel][3:0]} + {upscale_data[3:0]});
                    red       = red_sum >> 1;
                    green     = green_sum >> 1;
                    blue      = blue_sum >> 1;
                    out_linebuff = {red[3:0], green[3:0], blue[3:0]};
                end else begin  //가로(행)줄이 홀수
                    if (x_pixel[0] == 0) begin  //가로(행) 홀수, 세로(열)줄이 짝수
                        red_sum = ({buffer_prev[11:8]} + {upscale_data[11:8]});
                        green_sum = ({buffer_prev[7:4]} + {upscale_data[7:4]});
                        blue_sum = ({buffer_prev[3:0]} + {upscale_data[3:0]});
                        red = red_sum >> 1;
                        green = green_sum >> 1;
                        blue = blue_sum >> 1;
                        out_linebuff = {red[3:0], green[3:0], blue[3:0]};
                    end else begin  // 가로(행) 홀수, 세로(열)줄이 홀수
                        out_linebuff = upscale_data;
                    end
                end
            end else out_linebuff = upscale_data;  //x_pixel == 0 || y_pixel == 0일때
        end else out_linebuff = 12'b0;  //640 480 범위 넘어간 경우
    end
endmodule

module upScaler_ReadData (      //해상도 변경(qvga->vga)
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    output logic        qvga_en,
    output logic [16:0] qvga_addr
);

always_comb begin
    if(x_pixel < 640 && y_pixel < 480) begin
        qvga_addr = ((y_pixel >> 1) * 320) + (x_pixel >> 1);
        qvga_en   = 1'b1;
    end else begin
        qvga_addr = 0;
        qvga_en   = 1'b0;
    end
end

endmodule


//input  logic        h_sync,

/*module LineBuffer (
    input  logic        clk,             //100MHz
    input  logic        reset,
    input  logic        display_enable,
    input  logic [11:0] qvga_data,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    // read side
    //output logic        update_en,
    //output logic [16:0] qvga_addr,
    output logic [11:0] vga_image
);

    logic [11:0] line1[0:639];

    always_comb begin
        if (display_enable) begin
            if (x_pixel == 0) begin
                line1[0] <= qvga_data;
                line1[1] <= qvga_data;
                //vga_image <= line1[x_pixel];
            end else if (x_pixel > 1) begin
                if (x_pixel[0] == 1) begin
                    line1[x_pixel] <= qvga_data;
                    //vga_image <= line1[x_pixel];
                end else begin
                    line1[x_pixel] <= (line1[x_pixel-1] + qvga_data) >> 1;
                    //vga_image <= line1[x_pixel];
                end
            end
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < 640; i = i + 1) line1[i] <= 12'b0;
        end else if (display_enable) begin
            if (x_pixel == 0 || x_pixel == 1) begin
                line1[0] <= qvga_data;
                line1[1] <= qvga_data;
            end else if (x_pixel > 1) begin
                if (x_pixel[0] == 1) begin
                    line1[x_pixel] <= qvga_data;
                end else if (qvga_data != 12'b0) begin
                    line1[x_pixel] <= (line1[x_pixel-1] + qvga_data) >> 1;
                end else begin
                    line1[x_pixel] <= line1[x_pixel-1];
                end
            end
        end
    end

        assign vga_image = line1[x_pixel];

endmodule */


// logic        cnt;
// logic [ 7:0] xcnt;
// logic [ 7:0] ycnt;
// logic [ 7:0] rxcnt;
// logic        tick;




// write side
/*always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            xcnt <= 0;
        end else begin
            if (update_en) begin
                if (xcnt < 320) begin
                    if (xcnt == 0) begin
                        line1[xcnt] <= qvga_data;
                        line1[xcnt+1] <= qvga_data;
                        xcnt <= xcnt + 1;
                        //rAddr <= display_enable ?((x_pixel / 2) + (y_pixel / 2) * 320):17'b0;
                    end else begin
                        line1[2*xcnt+1] <= qvga_data;
                        line1[2*xcnt] <= (line1[2*xcnt-1] + qvga_data) >> 1;
                        xcnt <= xcnt + 1;
                        //rAddr <= display_enable ?((x_pixel / 2) + (y_pixel / 2) * 320):17'b0;
                    end
                end else begin
                    xcnt <= 0;
                    update_en <= 0;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (display_enable) begin
            qvga_addr <= (y_pixel / 2) * 320 + (x_pixel / 2);
        end else begin
            qvga_addr <= 17'b0;
        end
    end

    // read side
    always_ff @(posedge clk, posedge reset) begin  //25MHz로 2번읽음(y scale은 평균이 아니고 걍 2배)
        if (reset) begin
            rxcnt     <= 0;
            tick      <= 0;
            update_en <= 1;
        end else if (tick == 0) begin  //첫번째 읽을 차레(tick==0)
            //update_en <= 0;  // 읽을때 line1 업데이트 안되게
            if (rxcnt == 639) begin
                rxcnt <= 0;
                vga_image <= line1[rxcnt];
                tick <= tick + 1;
            end else begin
                rxcnt <= rxcnt + 1;
                vga_image <= line1[rxcnt];
            end
        end else begin  //2번째 읽을 차례(tick==1)
            if (rxcnt == 639) begin
                rxcnt <= 0;
                vga_image <= line1[rxcnt];
                tick <= 0;
                update_en <= 1;     //2번 다 읽었으니, update_en을 1로 만들어 line1 update시작.
            end else begin
                rxcnt <= rxcnt + 1;
                vga_image <= line1[rxcnt];
            end
        end
    end*/

/*always_ff @(negedge h_sync, posedge reset) begin
        if (reset) begin
            cnt <= 0;
            ycnt <= 0;
            update_en <= 0;
        end else begin
            if (cnt == 1) begin
                cnt <= 0;
                update_en <= 1;
                if (ycnt == 240) begin
                    ycnt <= 0;
                end else ycnt <= ycnt + 1;
            end else begin
                cnt       <= cnt + 1;
                update_en <= 0;
            end
        end
    end*/
// assign line2 = line1;
//assign rAddr = display_enable ?((x_pixel_100MHz / 2) + (y_pixel_100MHz / 2) * 320):17'bz;
//assign qvga_addr = display_enable ? ((y_pixel / 2) * 320 + (x_pixel / 2)):17'bz;
