`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: John Lopez
// 
// Create Date: 03/01/2024 7:31:04 PM
// Design Name: 
// Module Name: spi_fb_driver_80x60_tb
// Project Name: SPI Testbench 80x60
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: spi_fb_driver_80x60
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module spi_fb_driver_80x60_tb();

  logic tb_CLK, tb_RESET, tb_WE;
  logic [12:0] tb_WA;
  logic [7:0] tb_WD, tb_RD, tb_PMOD;

  spi_fb_driver_80x60 tb_spi_display(
    .CLK_50MHz(tb_CLK),
    .RESET(tb_RESET),
    .WE(tb_WE),
    .WA(tb_WA),
    .WD(tb_WD),
    .RD(tb_RD),
    .PMOD(tb_PMOD)
  );

  always #2 tb_CLK = ~tb_CLK;

  initial begin
    tb_CLK = 0;
    tb_RESET = 0;
    tb_WE = 0;
    tb_WA = 0;
    tb_WD = 8'he5;
    
    # 4
    tb_WE = 1;
    # 4
    tb_WE = 0;
    
    # 4
    tb_WE = 1;
    tb_WA = 2;
    tb_WD = 8'hff;
    # 4
    tb_WE = 0;
  end
    
endmodule
