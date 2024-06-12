`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: John Lopez
// 
// Create Date: 03/01/2024 7:31:04 PM
// Design Name: 
// Module Name: text_display_hw_test
// Project Name: Hardware Test Wrapper for 80x60 Text Display
// Target Devices: 
// Tool Versions: 
// Description: Sends a few characters to the text display and relays 
//              the pixel data to a VGA screen
// 
// Dependencies: text_driver_80x60
//               vga_fb_driver_80x60
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Accepts ASCII characters 32-126 and 
//                      \r (13) \n (10) \t (9) \b (8)
//                      if CHAR = 127 (DEL) the screen will clear (clears buffer)
// 
//////////////////////////////////////////////////////////////////////////////////


module text_display_hw_test(
  input CLK,
  input BTNC,
  // output [7:0] JA,    // comment out for VGA
  output [7:0] VGA_RGB,  // comment out for SPI
  output VGA_HS,         // comment out for SPI
  output VGA_VS          // comment out for SPI
  );

  logic clk_50MHz = 0;
  logic slow_clk = 0;
  logic [24:0] clk_div = 0;

  logic s_reset = 0;

  logic [2:0] sending = 0;

  logic [12:0] r_disp_wa;
  logic [7:0] r_disp_wd;
  logic r_disp_we;
  logic [7:0] r_disp_rd;

  logic [7:0] r_char = 10; // newline
  logic r_char_we;

  // clock divider
  always_ff @(posedge CLK) begin
    clk_50MHz <= ~clk_50MHz;
  end

  always_ff @(posedge clk_50MHz) begin
    s_reset <= 0;
    if(BTNC) begin
      clk_div   <= 0;
      slow_clk <= 1'b0;
      s_reset <= 1;
    end
    else begin
      clk_div <= clk_div + 1;
      if (clk_div == 3) r_char_we <= 1;
      if (clk_div == 4) r_char_we <= 0;
      if (clk_div > 25000000) begin
        clk_div <= 0;
        slow_clk <= ~slow_clk;
      end
    end
  end

  always_ff @(posedge slow_clk) begin
    case (sending)
      0: r_char <= 65;  // A
      1: r_char <= 66;  // B
      2: r_char <= 67;  // C
      3: r_char <= 10;  // newline
      4: r_char <= 120; // x
      5: r_char <= 121; // y
      6: r_char <= 122; // z
      7: r_char <= 10;  // newline
      default: sending <= 0;
    endcase
    sending <= sending + 1;
  end


  text_driver_80x60 char_mem( .CLK_50MHz(clk_50MHz), .RESET(s_reset), .CHAR(r_char), 
                              .WE(r_char_we), .DISP_ADDR(r_disp_wa), .DISP_DATA(r_disp_wd), .DISP_WE(r_disp_we));

  // // comment out if using VGA
  // spi_fb_driver_80x60 display( .CLK_50MHz(CLK_50MHz), .RESET(s_reset), .WA(r_disp_wa), 
  //                              .WD(r_disp_wd), .WE(r_disp_we), .RD(r_disp_rd), .PMOD(JA));

  // comment out if using SPI
  vga_fb_driver_80x60 VGA( .CLK_50MHz(clk_50MHz), .WA(r_disp_wa), .WD(r_disp_wd), .WE(r_disp_we), 
                            .RD(r_disp_rd), .ROUT(VGA_RGB[7:5]), .GOUT(VGA_RGB[4:2]), 
                            .BOUT(VGA_RGB[1:0]), .HS(VGA_HS), .VS(VGA_VS));

endmodule
