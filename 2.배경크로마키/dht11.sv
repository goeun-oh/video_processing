`timescale 1ns / 1ps

module dht_11 (
    input        clk,
    input        resetn,
    input        start,
    inout        dht_11,
    output [7:0] HR,
    output [7:0] TR,
    output       err,
    output       done,
    output       interrupt
);

    wire [39:0] dht_11_data;
    wire w_tick_us, w_tick_ms,btn_start;

    assign HR = dht_11_data[39:32];
    assign TR = dht_11_data[23:16];

    btn_detector U_BTN_DECT (
        .clk(clk),
        .reset(reset),
        .btn(start),
        .rising_edge(btn_start),
        .falling_edge(),
        .both_edge()
    );

    dht_11_data U_Dht_11_Data (
        .clk(clk),
        .resetn(resetn),
        .start(btn_start),
        .tick_us(w_tick_us),
        .tick_ms(w_tick_ms),
        .dht_11(dht_11),
        .data(dht_11_data),
        .err(err),
        .done(done),
        .interrupt(interrupt)
    );

    DHT_11_tick_us U_Tick_us_Dht_11 (
        .clk(clk),
        .resetn(resetn),
        .tick_us(w_tick_us)
    );

    DHT_11_tick_ms U_Tick_ms_Dht_11 (
        .clk(clk),
        .resetn(resetn),
        .tick_ms(w_tick_ms)
    );


endmodule

module dht_11_data (
    input         clk,
    input         resetn,
    input         start,
    input         tick_us,
    input         tick_ms,
    inout         dht_11,
    output [39:0] data,
    output        err,
    output        done,
    output        interrupt
);

    parameter IDLE = 3'b000, START = 3'b001, WAIT = 3'b010, RESPONSE = 3'b011, READY = 3'b100, DATA = 3'b101, STOP = 3'b110;

    reg [2:0] state, next;
    reg [10:0] r_ms_counter, r_ms_counter_next;
    reg [10:0] r_us_counter, r_us_counter_next;
    reg [39:0] r_data, r_data_next;
    reg [5:0] data_count, data_count_next;
    reg us_count_state, us_count_state_next;

    reg r_dht_11_dir, r_dht_11_dir_next;
    reg r_dht_11_data, r_dht_11_data_next;

    reg err_reg, err_next;
    reg done_reg, done_next;
    reg intr_reg, intr_next;
    reg [7:0] check_reg, check_next;

    wire dht_11_in;

    assign dht_11    = (r_dht_11_dir) ? r_dht_11_data : 1'bz;
    assign dht_11_in = dht_11;

    assign err       = err_reg;
    assign done      = done_reg;
    assign interrupt = intr_reg;

    wire p_edge, n_edge;

    DHT_11_edge_detector U_DHT11_Edge_Detector (
        .clk(clk),
        .resetn(resetn),
        .pulse(dht_11_in),
        .p_edge(p_edge),
        .n_edge(n_edge)
    );

    always @(posedge clk) begin
        if (resetn == 1'b0) begin
            state          <= IDLE;
            r_us_counter   <= 0;
            r_ms_counter   <= 0;
            r_data         <= 0;
            data_count     <= 0;
            us_count_state <= 0;
            r_dht_11_dir   <= 0;
            r_dht_11_data  <= 1'bz;
            err_reg        <= 0;
            done_reg       <= 0;
            intr_reg       <= 0;
            check_reg      <= 0;
        end else begin
            state          <= next;
            r_us_counter   <= r_us_counter_next;
            r_ms_counter   <= r_ms_counter_next;
            r_data         <= r_data_next;
            data_count     <= data_count_next;
            us_count_state <= us_count_state_next;
            r_dht_11_dir   <= r_dht_11_dir_next;
            r_dht_11_data  <= r_dht_11_data_next;
            err_reg        <= err_next;
            done_reg       <= done_next;
            intr_reg       <= intr_next;
            check_reg      <= check_next;
        end
    end

    always @(*) begin
        next                = state;
        r_us_counter_next   = r_us_counter;
        r_ms_counter_next   = r_ms_counter;
        r_data_next         = r_data;
        data_count_next     = data_count;
        us_count_state_next = us_count_state;
        r_dht_11_dir_next   = r_dht_11_dir;
        r_dht_11_data_next  = r_dht_11_data;
        err_next            = err_reg;
        done_next           = done_reg;
        intr_next           = intr_reg;
        check_next          = check_reg;

        case (state)
            IDLE: begin
                r_us_counter_next = 0;
                r_ms_counter_next = 0;
                r_dht_11_dir_next = 0;
                err_next          = 0;
                done_next         = 0;
                intr_next         = 0;
                check_next        = 0;
                if (start) begin
                    next               = START;
                    r_dht_11_dir_next  = 1;
                    r_dht_11_data_next = 1'b0;
                end
            end
            START: begin
                r_dht_11_dir_next  = 1;
                r_dht_11_data_next = 1'b0;
                if (tick_ms == 1'b1) begin
                    if (r_ms_counter == 22) begin
                        next = WAIT;
                        r_ms_counter_next = 0;
                        r_dht_11_dir_next = 0;
                    end else begin
                        r_ms_counter_next = r_ms_counter + 1;
                    end
                end
            end
            WAIT: begin
                if (n_edge == 1'b1) begin
                    next = RESPONSE;
                    r_us_counter_next = 0;
                end
                if (tick_us == 1'b1) begin
                    if (r_us_counter == 100) begin
                        next = IDLE;
                        err_next = 1;
                        r_us_counter_next = 0;
                    end else begin
                        r_us_counter_next = r_us_counter + 1;
                    end
                end
            end
            RESPONSE: begin
                if (r_us_counter > 60 && r_us_counter < 100 && p_edge == 1'b1) begin
                    r_us_counter_next = 0;
                    next = READY;
                end
                if (tick_us == 1'b1) begin
                    if (r_us_counter == 200) begin
                        err_next = 1;
                        r_us_counter_next = 0;
                        next = IDLE;
                    end else begin
                        r_us_counter_next = r_us_counter + 1;
                    end
                end

            end
            READY: begin
                if (r_us_counter> 60 && r_us_counter < 100 && n_edge == 1'b1) begin
                    r_us_counter_next = 0;
                    next = DATA;
                end
                if (tick_us == 1'b1) begin
                    if (r_us_counter == 200) begin
                        err_next = 1;
                        r_us_counter_next = 0;
                        next = IDLE;
                    end else begin
                        r_us_counter_next = r_us_counter + 1;
                    end
                end

            end
            DATA: begin
                if (tick_us == 1'b1 && us_count_state == 1'b1) begin
                    r_us_counter_next = r_us_counter + 1;
                end
                if (p_edge == 1'b1) begin
                    us_count_state_next = 1'b1;
                end
                if (n_edge == 1'b1) begin
                    us_count_state_next = 1'b0;
                    r_us_counter_next = 0;
                    data_count_next = data_count + 1;
                    if (r_us_counter > 20 && r_us_counter < 40) begin
                        r_data_next[39-data_count] = 1'b0;
                    end else if (r_us_counter > 60 && r_us_counter < 80) begin
                        r_data_next[39-data_count] = 1'b1;
                    end
                end
                if (data_count == 40) begin
                    data_count_next = 0;
                    r_us_counter_next = 0;
                    check_next = r_data[7:0];
                    next = STOP;
                end
            end
            STOP: begin
                done_next = 1;
                if (check_reg == (r_data[39:32] + r_data[31:24] + r_data[23:16] + r_data[15:8]))
                    err_next = 0;
                else err_next = 1;
                intr_next = 1;
                next = IDLE;
            end
            default: begin
                next                = state;
                r_us_counter_next   = r_us_counter;
                r_ms_counter_next   = r_ms_counter;
                r_data_next         = r_data;
                data_count_next     = data_count;
                us_count_state_next = us_count_state;
                r_dht_11_dir_next   = r_dht_11_dir;
                r_dht_11_data_next  = r_dht_11_data;
                err_next            = err_reg;
                done_next           = done_reg;
                check_next          = check_reg;
            end
        endcase
    end

    assign data = r_data;

endmodule

module DHT_11_tick_us (
    input  clk,
    input  resetn,
    output tick_us
);

    reg [6:0] r_us_counter;
    reg r_tick_us;

    always @(posedge clk) begin
        if (resetn == 1'b0) begin
            r_us_counter <= 0;
            r_tick_us <= 1'b0;
        end else begin
            if (r_us_counter == 100 - 1) begin
                r_us_counter <= 0;
                r_tick_us <= 1'b1;
            end else begin
                r_us_counter <= r_us_counter + 1;
                r_tick_us <= 1'b0;
            end
        end
    end

    assign tick_us = r_tick_us;
endmodule

module DHT_11_tick_ms (
    input  clk,
    input  resetn,
    output tick_ms
);

    reg [16:0] r_ms_counter;
    reg r_tick_ms;

    always @(posedge clk) begin
        if (resetn == 1'b0) begin
            r_ms_counter <= 0;
            r_tick_ms <= 1'b0;
        end else begin
            if (r_ms_counter == 100000 - 1) begin
                r_ms_counter <= 0;
                r_tick_ms <= 1'b1;
            end else begin
                r_ms_counter <= r_ms_counter + 1;
                r_tick_ms <= 1'b0;
            end
        end
    end

    assign tick_ms = r_tick_ms;
endmodule

module DHT_11_edge_detector (
    input  clk,
    input  resetn,
    input  pulse,
    output p_edge,
    output n_edge
);

    reg prev, curr;
    always @(posedge clk) begin
        if (resetn == 1'b0) begin
            prev <= 1'b0;
            curr <= 1'b0;
        end else begin
            curr <= pulse;
            prev <= curr;
        end
    end

    assign p_edge = (curr == 1'b1 && prev == 1'b0) ? 1 : 0;
    assign n_edge = (curr == 1'b0 && prev == 1'b1) ? 1 : 0;

endmodule



