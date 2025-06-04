`timescale 1ns / 1ps

module frameBuffer (
    // write side
    input  logic        wclk,
    input  logic        we,
    input  logic [ 2:0] num,
    input  logic [16:0] wAddr,
    input  logic [11:0] wData,
    // read side
    input  logic        rclk,
    input  logic        oe,
    input  logic [16:0] rAddr,
    output logic [11:0] rData,
    output logic [11:0] rData2,
    output logic [11:0] rData3,
    output logic [11:0] rData4

);
    logic [11:0] mem1[0 : (160 * 120 - 1)];
    logic [11:0] mem2[0 : (160 * 120 - 1)];
    logic [11:0] mem3[0 : (160 * 120 - 1)];
    logic [11:0] mem4[0 : (160 * 120 - 1)];

    // write side 
    always_ff @(posedge wclk) begin
        if (we) begin
            if (num == 3'b000) begin
                mem1[(wAddr)] <= wData;
            end else if (num == 3'b001) begin
                mem2[(wAddr)] <= wData;
            end else if (num == 3'b010) begin
                mem3[(wAddr)] <= wData;
            end else if (num == 3'b011) begin
                mem4[(wAddr)] <= wData;
            end else begin
                
            end
        end
    end

    // read side
    always_ff @(posedge rclk) begin
        if (oe) begin
            rData  <= mem1[rAddr];
            rData2 <= mem2[rAddr];
            rData3 <= mem3[rAddr];
            rData4 <= mem4[rAddr];
        end
    end
endmodule
