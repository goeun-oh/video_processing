`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/21 17:21:30
// Design Name: 
// Module Name: i2c
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module i2c_write (
    input logic clk,
    input logic reset,
    output logic scl,
    inout logic sda,
    output logic done
);

    logic start_4khz;
    logic prev;
    logic [4:0] addr;
    logic [15:0] dout;
    logic next_start;
    logic start;

    always_ff @(posedge clk, posedge reset) begin : start_signal
        if (reset) begin
            start_4khz <= 0;
            prev <= 0;
            start <= 1;
        end else begin
            if (start || next_start) begin
                start_4khz <= 1;
                prev <= clk_4kHz;
                start <= 0;
            end else if (start_4khz && clk_4kHz != prev) begin
                start_4khz <= 0;
                start <= 0;
            end
        end
    end

    OV7670_config_rom U_Config_Rom (
        .clk (clk),
        .addr(addr),
        .dout(dout)
    );

    always_ff @(posedge clk_4kHz, posedge reset) begin : sccb_rom_addr
        if (reset) begin
            addr <= 0;
            next_start <= 1'b0;
        end else begin
            if (done) begin
                if (dout != 16'hffff) begin
                    addr <= addr + 1;
                    next_start <= 1'b1;
                end else begin
                    addr <= addr;
                    next_start <= 1'b0;
                end
            end
        end
    end

    clk_div_4kHz U_Clk_Div_4kHz (
        .clk  (clk),
        .reset(reset),
        .tick (clk_4kHz)
    );

    i2c_write_3byte U_I2C_Write_3byte (
        .clk(clk_4kHz),
        .reset(reset),
        .start(start_4khz),
        .indata({7'h21, 1'b0, dout}),
        .scl(scl),
        .sda(sda),
        .done(done)
    );



endmodule


//------------------------------------------------------------

module clk_div_4kHz (
    input  logic clk,
    input  logic reset,
    output logic tick
);
    logic [$clog2(25_000)-1:0] counter;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
            tick    <= 1'b0;
        end else begin
            if (counter == 25000 - 1) begin
                counter <= 0;
                tick    <= 1'b1;
            end else begin
                counter <= counter + 1;
                tick    <= 1'b0;
            end
        end
    end
endmodule



module i2c_write_3byte (  
    input  logic        clk,
    input  logic        reset,
    input  logic        start,
    input  logic [23:0] indata,
    output logic        scl,
    inout  logic        sda,
    output logic        done
);
    typedef enum logic [3:0] {
        IDLE,
        START_SDA,
        START_SCL,
        DATA_S0,
        DATA_S1,
        DATA_S2,
        DATA_S3,
        WAIT_ACK0,
        WAIT_ACK1,
        WAIT_ACK2,
        WAIT_ACK3,
        STOP_SCL,
        STOP_SDA
    } state_e;

    state_e state;
    logic [1:0] clk_counter;
    logic [4:0] bit_counter;
    logic iomode, outdata;
    logic [23:0] temp_data;
    logic ack, nack;

    assign sda = (iomode) ? outdata : 1'bz;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            scl         <= 1;
            outdata     <= 1;
            clk_counter <= 0;
            bit_counter <= 23;
            state       <= IDLE;
            iomode      <= 1;
            ack         <= 0;
            nack        <= 0;
            temp_data   <= 0;
            done        <= 0;
        end else begin
            scl         <= scl;
            outdata     <= outdata;
            clk_counter <= clk_counter;
            bit_counter <= bit_counter;
            state       <= state;
            iomode      <= iomode;
            ack         <= ack;
            nack        <= nack;
            temp_data   <= temp_data;
            done        <= done;
            case (state)
                IDLE: begin
                    iomode <= 1;
                    outdata <= 1;
                    scl <= 1;
                    ack <= 0;
                    nack <= 0;
                    done <= 0;
                    if (start) begin
                        state <= START_SDA;
                        temp_data <= indata;  //latching
                    end
                end
                START_SDA: begin
                    outdata <= 0;
                    if (clk_counter == 2) begin
                        state       <= START_SCL;
                        clk_counter <= 0;
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
                end
                START_SCL: begin
                    scl   <= 0;
                    state <= DATA_S0;
                end
                DATA_S0: begin
                    scl     <= 0;
                    outdata <= temp_data[bit_counter];
                    state   <= DATA_S1;
                end
                DATA_S1: begin
                    scl         <= 1;
                    outdata     <= outdata;
                    bit_counter <= bit_counter;
                    state       <= DATA_S2;
                end
                DATA_S2: begin
                    scl         <= 1;
                    outdata     <= outdata;
                    bit_counter <= bit_counter;
                    state       <= DATA_S3;
                end
                DATA_S3: begin
                    scl         <= 0;
                    outdata     <= outdata;
                    bit_counter <= bit_counter;
                    if (bit_counter == 0) begin
                        state       <= WAIT_ACK0;
                        bit_counter <= 23;
                    end else if (bit_counter == 16) begin
                        state <= WAIT_ACK0;
                        bit_counter <= bit_counter - 1;
                    end else if (bit_counter == 8) begin
                        state <= WAIT_ACK0;
                        bit_counter <= bit_counter - 1;
                    end else begin
                        state <= DATA_S0;
                        bit_counter <= bit_counter - 1;
                    end
                end
                WAIT_ACK0: begin
                    scl    <= 0;
                    iomode <= 0;
                    state  <= WAIT_ACK1;
                end
                WAIT_ACK1: begin
                    scl     <= 1;
                    outdata <= 0;
                    if (sda == 1'b0) begin
                        ack <= 1;
                    end else begin
                        nack <= 1;
                    end
                    state <= WAIT_ACK2;
                end
                WAIT_ACK2: begin
                    scl   <= 1;
                    state <= WAIT_ACK3;
                end
                WAIT_ACK3: begin
                    scl   <= 0;
                    state <= STOP_SCL;
                end
                STOP_SCL: begin
                    scl     <= 0;
                    iomode  <= 1;
                    outdata <= 0;
                    if (bit_counter != 23) begin
                        state   <= DATA_S1;
                        outdata <= temp_data[bit_counter];
                    end else if (clk_counter == 1) begin
                        clk_counter <= 0;
                        scl <= 1;
                        state <= STOP_SDA;
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
                end
                STOP_SDA: begin
                    if (clk_counter == 2) begin
                        state       <= IDLE;
                        done        <= 1;
                        outdata     <= 1;
                        clk_counter <= 0;
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
                end

            endcase
        end
    end
endmodule



