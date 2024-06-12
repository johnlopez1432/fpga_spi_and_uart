`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: John Lopez
// 
// Create Date: 03/01/2024 7:31:04 PM
// Design Name: 
// Module Name: text_display_tb
// Project Name: Text Console Testbench
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: text_driver_80x60
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module text_display_tb();

  logic tb_CLK, tb_RESET, tb_WE, tb_disp_we;
  logic [12:0] tb_ADDR;
  logic [7:0] tb_CHAR, tb_DATA;

  text_driver_80x60 tb_spi_display(
    .CLK_50MHz(tb_CLK),
    .RESET(tb_RESET),
    .CHAR(tb_CHAR),
    .WE(tb_WE),
    .DISP_ADDR(tb_ADDR),
    .DISP_DATA(tb_DATA),
    .DISP_WE(tb_disp_we)
  );

  always #2 tb_CLK = ~tb_CLK;

  initial begin
    tb_CLK = 0;
    tb_RESET = 0;
    tb_WE = 0;
    tb_CHAR = 0;
    
    # 2
    tb_WE = 1;
    tb_CHAR = 72; // H
    # 4
    tb_CHAR = 101; // e
    
    # 4
    tb_CHAR = 108; // l (2 clock cycles)
    # 8
    tb_CHAR = 111; // o
    # 4
    tb_WE = 0;
    # 700
    tb_WE = 1;
    tb_CHAR = 127; // DEL
    # 4
    tb_WE = 0;
  end

endmodule
