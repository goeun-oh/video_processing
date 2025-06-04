module capture_top (
    input logic clk,
    input logic reset,
    input logic btn,
    input logic btn_reset,
    input logic v_sync,
    output logic [3:0] txt_num,
    output logic [2:0] num,
    output logic buzz
);

    logic w_btn, w_btn_reset;

    logic capture_start;
    logic finish_flag;

    btn_debounce U_btn_debounce (
        .i_btn(btn),
        .clk  (clk),
        .reset(reset),
        .o_btn(w_btn)
    );

    btn_debounce U_btn_debounce_reset (
        .i_btn(btn_reset),
        .clk  (clk),
        .reset(reset),
        .o_btn(w_btn_reset)
    );

    capture_start U_capture_start (
        .clk(clk),
        .reset(reset),
        .btn(w_btn),
        .btn_reset(w_btn_reset),
        .finish_flag(finish_flag),
        .capture_start(capture_start)
    );


    finish_flag U_finish (
        .clk(clk),
        .reset(reset),
        .btn_reset(w_btn_reset),
        .capture_start(capture_start),
        .finish_flag(finish_flag)
    );

    capture U_capture (
        .clk(clk),
        .reset(reset),
        .capture_start(capture_start),
        .v_sync(v_sync),
        .num(num),
        .txt_num(txt_num)
    );

    logic [2:0] halfsec;
    logic [3:0] qsec;

    tick_1sec U_tick_1sec (
        .clk(clk),
        .capture_start(capture_start),
        .reset(reset),
        .qsec(qsec),
        .halfsec(halfsec)
    );

    piezo_tone U0_piezo_tone (
        .clk(clk),
        .qsec(qsec),
        .halfsec(halfsec),
        .reset(reset),
        .capture_start(capture_start),
        .buzzer(buzz)
    );

endmodule



module capture_start (
    input  logic clk,
    input  logic reset,
    input  logic btn,
    input  logic btn_reset,
    input  logic finish_flag,
    output logic capture_start
);

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            capture_start <= 1'b0;
        end else if (btn_reset) begin
            capture_start <= 1'b0;
        end else if (finish_flag) begin
            capture_start <= 1'b0;
        end else if (btn) begin
            capture_start <= 1'b1;
        end else begin
            capture_start <= capture_start;
        end

    end
endmodule

module finish_flag (
    input  logic clk,
    input  logic reset,
    input  logic btn_reset,
    input  logic capture_start,
    output logic finish_flag
);

    logic [$clog2(100_000_000 -1):0] counter;
    logic tick;
    logic [3:0] counter12;
    logic tick12;

    assign finish_flag = tick12;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            tick <= 1'b0;
        end else begin
            if (capture_start) begin
                if (counter >= 100_000_000 - 1) begin
                    counter <= 0;
                    tick <= 1'b1;
                end else begin
                    counter <= counter + 1;
                    tick <= 1'b0;
                end
            end else begin
                counter <= 0;
                tick <= 0;
            end
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter12 <= 0;
            tick12 <= 1'b0;
        end else begin
            if (tick) begin
                if (counter12 == 15) begin
                    counter12 <= 0;
                    tick12 <= 1'b1;
                end else begin
                    counter12 <= counter12 + 1;
                    tick12 <= 1'b0;
                end
            end else if (btn_reset) begin
                counter12 <= 0;
                tick12 <= 0;
            end else begin
                counter12 <= counter12;
                tick12 <= tick12;
            end
        end
    end

endmodule

module capture (
    input logic clk,
    input logic reset,
    input logic capture_start,
    input logic v_sync,
    output logic [2:0] num,
    output logic [3:0] txt_num
);

    logic [$clog2(300_000_000 -1):0] counter;
    logic [$clog2(100_000_000 -1):0] txt_counter;

    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= 0;
            num <= 0;
        end else begin
            if (capture_start == 1) begin
                if (counter >= 300_000_000 - 1) begin
                    if (v_sync) begin
                        counter <= 0;
                        if (num < 5) begin
                            num <= num + 1;
                        end else if (num == 5) begin
                            num <= num;
                        end else begin
                            num <= 0;
                        end
                    end else begin
                        counter <= counter;
                        num <= num;
                    end
                end else begin
                    counter <= counter + 1;
                    num <= num;
                end
            end else begin
                counter <= 0;
                num <= 7;
            end
        end
        if (capture_start == 1) begin
            if (txt_counter >= 100_000_000 - 1) begin
                if (v_sync) begin
                    txt_counter <= 0;
                    if (txt_num < 15) begin
                        txt_num <= txt_num + 1;
                    end else if (txt_num == 15) begin
                        txt_num <= txt_num;
                    end else begin
                        txt_num <= 0;
                    end
                end else begin
                    txt_counter <= txt_counter;
                    txt_num <= txt_num;
                end
            end else begin
                txt_counter <= txt_counter + 1;
                txt_num <= txt_num;
            end
        end else begin
            txt_counter <= 0;
            txt_num <= 0;
        end
    end
endmodule


module tick_1sec (
    input logic clk,
    input logic reset,
    input logic capture_start,
    output logic [2:0] halfsec,
    output logic [3:0] qsec
);

    logic [26:0] counter;  // 27비트 카운터 (최대 134,217,728)
    logic [26:0] counter25;

    logic tick;
    logic tick25;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            tick <= 0;
        end else begin
            if (capture_start) begin
                if (counter >= 50_000_000 - 1) begin  // 1초 지남
                    counter <= 0;
                    tick <= 1;  // 1클럭 동안 틱 발생
                end else begin
                    counter <= counter + 1;
                    tick <= 0;
                end
            end else begin
                counter <= 0;
                tick <= 0;
            end

        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter25 <= 0;
            tick25 <= 0;
        end else begin
            if (capture_start) begin
                if (counter25 >= 25_000_000 - 1) begin  // 1초 지남
                    counter25 <= 0;
                    tick25 <= 1;  // 1클럭 동안 틱 발생
                end else begin
                    counter25 <= counter25 + 1;
                    tick25 <= 0;
                end
            end else begin
                counter25 <= 0;
                tick25 <= 0;
            end

        end
    end

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            halfsec <= 0;
        end else begin
            if (tick == 1) begin
                if (halfsec == 5) begin
                    halfsec <= 0;
                end else begin
                    halfsec <= (halfsec + 1);
                end
            end
        end
    end

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            qsec <= 0;
        end else begin
            if (tick25 == 1) begin
                if (qsec == 3) begin
                    qsec <= 0;
                end else begin
                    qsec <= (qsec + 1);
                end
            end
        end
    end
endmodule



module piezo_tone (
    input logic clk,
    input logic [2:0] halfsec,
    input logic [3:0] qsec,
    input logic reset,
    input logic capture_start,
    output logic buzzer
);

    logic [31:0] clk_div;
    logic [31:0] pwm_counter;
    logic [31:0] pwm_period;

    logic [16:0] piezo_cnt;
    logic [ 9:0] cnt;
    logic [ 3:0] note;

    always_comb begin
        if (capture_start && (qsec[1] == 1) && (qsec[0] == 1)) begin
            case (halfsec)
                3'b000:  note = 4'b1110;  //0     
                3'b001:  note = 4'b1110;  //0.5   
                3'b010:  note = 4'b1110;  //1     
                3'b011:  note = 4'b1110;  //1.5  
                3'b100:  note = 4'b0000;  //2.0  
                3'b101:  note = 4'b0000;  //2.5   
                3'b110:  note = 4'b1111;  //3.0   
                3'b111:  note = 4'b1111;  //3.5   
                default: note = 4'b1111;
            endcase
        end else begin
            note = 4'b1111;
        end
    end

    always_comb begin
        case (note)
            4'b0000: pwm_period = 32'd764816;  // C2 (약 65Hz)
            4'b0001: pwm_period = 32'd170262;  // D4 (294Hz)
            4'b0010: pwm_period = 32'd151685;  // E4 (330Hz)
            4'b0011: pwm_period = 32'd143173;  // F4 (349Hz)
            4'b0100: pwm_period = 32'd127551;  // G4 (392Hz)
            4'b0101: pwm_period = 32'd113636;  // A4 (440Hz)
            4'b0110: pwm_period = 32'd101239;  // B4 (494Hz)
            4'b0111: pwm_period = 32'd95556;  // C5 (523Hz)
            4'b1000: pwm_period = 32'd85131;  // D5 (587Hz)
            4'b1001: pwm_period = 32'd75843;  // E5 (659Hz)
            4'b1010: pwm_period = 32'd71586;  // F5 (698Hz)
            4'b1011: pwm_period = 32'd63776;  // G5 (784Hz)
            4'b1100: pwm_period = 32'd56818;  // A5 (880Hz)
            4'b1101: pwm_period = 32'd50592;  // B5 (988Hz)
            4'b1110: pwm_period = 32'd47778;  // C6 (1046Hz)
            4'b1111: pwm_period = 32'd0;  // 
            default: pwm_period = 32'd0;  // 음소거
        endcase
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_div <= 0;
            buzzer  <= 0;
        end else begin
            if (capture_start && (qsec[0] == 1) && (qsec[1] == 1)) begin
                if (clk_div >= pwm_period * 2) begin
                    clk_div <= 0;
                    buzzer  <= 1;
                end else if (clk_div >= pwm_period) begin
                    clk_div <= clk_div + 1;
                    buzzer  <= 0;
                end else begin
                    clk_div <= clk_div + 1;
                    buzzer  <= 1;
                end
            end else begin
                clk_div <= 0;
                buzzer  <= 0;
            end
        end
    end
endmodule

module btn_debounce (
    input  logic i_btn,
    input  logic clk,
    input  logic reset,
    output logic o_btn
);

    logic [3:0] r_debounce;
    logic r_dff;
    logic w_debounce;
    logic [$clog2(100_000)-1:0] r_counter;
    logic w_clk;

    // for debounce clock div 100M > 1Khz
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            w_clk <= 1'b0;
        end else begin
            if (r_counter == 100_000) begin
                r_counter <= 0;
                w_clk <= 1'b1;
            end else begin
                r_counter <= r_counter + 1;
                w_clk <= 1'b0;
            end
        end
    end

    always @(posedge w_clk, posedge reset) begin
        if (reset) begin
            r_debounce <= 0;
        end else begin
            r_debounce <= {i_btn, r_debounce[3:1]};
        end
    end


    assign w_debounce = &r_debounce;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_dff <= 1'b0;
        end else begin
            r_dff <= w_debounce;
        end
    end


    assign o_btn = w_debounce & (~r_dff);

endmodule
