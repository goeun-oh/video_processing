`timescale 1ns/1ps


module tick_400kHz(
    input logic clk,
    input logic reset,
    output logic tick_400kHz
);
    localparam FCOUNT = 250;
    logic [$clog2(FCOUNT)-1:0] counter;

    always_ff @( posedge clk, posedge reset ) begin
        if(reset) begin
            tick_400kHz <=0;
            counter <=0;
        end else begin
            if(counter == FCOUNT-1) begin
                counter <=0;
                tick_400kHz <= 1'b1;
            end else begin
                counter <= counter +1;
                tick_400kHz <= 1'b0;
            end
        end
    end


endmodule