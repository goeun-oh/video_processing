`timescale 1ns / 1ps

module vga_controller (
    input  logic       clk,
    input  logic       reset,
    input  logic       focusing_btn,
    input  logic       rotate2idle_btn,
    output logic       h_sync,
    output logic       v_sync,
    output logic [9:0] x_pixel,
    output logic [9:0] y_pixel,
    output logic [9:0] w_x_pixel,
    output logic       display_enable,
    output logic       sobel_en,
    output logic       mean_start,
    output logic       rotate2idle
);

    logic [9:0] h_counter, v_counter;
    logic rising_edge_detect_focusing_btn;
    logic rising_edge_detect_r2i;

    pixel_counter U_Pxl_Counter (
        .pclk        (clk),
        .reset       (reset),
        .h_counter   (h_counter),
        .v_counter   (v_counter),
        .w_x_pixel (w_x_pixel)
    );

    vga_decoder U_VGA_Decoder (
        .h_counter     (h_counter),
        .v_counter     (v_counter),
        .h_sync        (h_sync),
        .v_sync        (v_sync),
        .x_pixel       (x_pixel),
        .y_pixel       (y_pixel),
        .display_enable(display_enable)
    );

    btn_detector U_Focusing_btn (
        .clk(clk),
        .rst(reset),
        .btn(focusing_btn),
        .rising_edge_detect(rising_edge_detect_focusing_btn),
        .falling_edge_detect(),
        .both_edge_detect()
    );

    btn_detector U_rotate2idle_btn (
        .clk(clk),
        .rst(reset),
        .btn(rotate2idle_btn),
        .rising_edge_detect(rising_edge_detect_r2i),
        .falling_edge_detect(),
        .both_edge_detect()
    );

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            mean_start <= 1'b0;
        end else begin
            if (rising_edge_detect_focusing_btn) begin
                mean_start <= 1'b1;
            end else begin
                mean_start <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            rotate2idle <= 1'b0;
        end else begin
            if (rising_edge_detect_r2i) begin
                rotate2idle <= 1'b1;
            end else begin
                rotate2idle <= 1'b0;
            end
        end
    end

    always_comb begin
        if((w_x_pixel < 320) && (y_pixel < 240 ))begin
            sobel_en = 1'b1;
        end
        else begin
            sobel_en = 1'b0;
        end
    end
    // assign sobel_en = (x_pixel < 320) && (y_pixel < 240) ? 1'b1 : 1'b0;
endmodule

module pixel_counter (
    input  logic       pclk,
    input  logic       reset,
    output logic [9:0] h_counter,
    output logic [9:0] v_counter,
    output logic [9:0] w_x_pixel
);
    localparam H_MAX = 800, V_MAX = 525;

    always_ff @(posedge pclk, posedge reset) begin : Horizontal_counter
        if (reset) begin
            h_counter <= 0;
        end else begin
            if (h_counter == H_MAX - 1) begin
                h_counter <= 0;
            end else begin
                h_counter <= h_counter + 1;
            end
        end
    end

    always_ff @(posedge pclk, posedge reset) begin : Vertical_counter
        if (reset) begin
            v_counter <= 0;
        end else begin
            if (h_counter == H_MAX - 1) begin
                if (v_counter == V_MAX - 1) begin
                    v_counter <= 0;
                end else begin
                    v_counter <= v_counter + 1;
                end
            end
        end
    end

    always_ff @( posedge pclk, posedge reset ) begin
        if(reset)begin
            w_x_pixel <= 0;
        end
        else begin
            w_x_pixel <= h_counter;
        end
    end

endmodule

module vga_decoder (
    input  logic [9:0] h_counter,
    input  logic [9:0] v_counter,
    output logic       h_sync,
    output logic       v_sync,
    output logic [9:0] x_pixel,
    output logic [9:0] y_pixel,
    output logic       display_enable
);

    localparam H_Visible_area = 640;
    localparam H_Front_porch = 16;
    localparam H_Sync_pulse = 96;
    localparam H_Back_porch = 48;
    localparam H_Whole_line = 800;
    localparam V_Visible_area = 480;
    localparam V_Front_porch = 10;
    localparam V_Sync_pulse = 2;
    localparam V_Back_porch = 33;
    localparam V_Whole_frame = 525;

    assign h_sync = !((h_counter >= (H_Visible_area + H_Front_porch)) && (h_counter < (H_Visible_area + H_Front_porch + H_Sync_pulse)));
    assign v_sync = !((v_counter >= (V_Visible_area + V_Front_porch)) && (v_counter < (V_Visible_area + V_Front_porch + V_Sync_pulse)));
    assign display_enable = (h_counter < H_Visible_area) && (v_counter < V_Visible_area);
    assign x_pixel = h_counter;
    assign y_pixel = v_counter;
endmodule

module btn_detector (
    input  logic clk,
    input  logic rst,
    input  logic btn,
    output logic rising_edge_detect,
    output logic falling_edge_detect,
    output logic both_edge_detect
);

    logic [$clog2(100_000)-1:0] cnt;
    logic tick;
    logic [3:0] shift_reg;
    logic q_reg;
    logic debounce;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            cnt  <= 0;
            tick <= 1'b0;
        end else begin
            if (cnt == 100_000 - 1) begin
                cnt  <= 0;
                tick <= 1'b1;
            end else begin
                cnt  <= cnt + 1;
                tick <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            shift_reg <= 4'b0;
        end else begin
            if (tick) begin
                shift_reg <= {btn, shift_reg[3:1]};
            end else begin
                shift_reg <= shift_reg;
            end
        end
    end

    assign debounce = &shift_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            q_reg <= 0;
        end else begin
            q_reg <= debounce;
        end
    end

    assign rising_edge_detect = ~q_reg & debounce;
    assign falling_edge_detect = q_reg & ~debounce;
    assign both_edge_detect = rising_edge_detect | falling_edge_detect;
endmodule
