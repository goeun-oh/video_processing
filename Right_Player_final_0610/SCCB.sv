`timescale 1ns / 1ps

module SCCB (
    input  logic clk,
    input  logic reset,
    output logic scl,
    output logic sda
);

    logic [7:0] rom_addr;
    logic [15:0] rom_data;


    SCCB_Controller U_SCCB_CNTR(
        .*,
        .reg_addr(rom_data[15:8]),
        .rom_data(rom_data[7:0])
    );

    OV7670_config_rom CONFIG_ROM(.*);

endmodule
