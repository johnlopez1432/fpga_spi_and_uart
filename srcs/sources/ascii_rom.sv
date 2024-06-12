`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: John Lopez
//
// Create Date: 03/01/2024 7:31:04 PM
// Design Name:
// Module Name: ascii_rom
// Project Name: ASCII ROM
// Target Devices: 
// Tool Versions: 
// Description: ASCII Read Only Memory for SPI display driver (9x5 font)
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Uses font "BPdots Square Bold"
//                      Memory file generated with font_to_mem.py
// 
//////////////////////////////////////////////////////////////////////////////////


module ascii_rom(
  input [7:0] CHAR,   // read character
  input [5:0] POS,    // pixel position
  output PIXEL       // pixel info (on or off)
  );
  
  logic [59:0] rom [0:94]; // 60 pixel positions, 95 characters

  initial begin
    $readmemh("ascii.mem", rom, 0, 94);
  end
  
  logic out;
  assign PIXEL = out;

  always_comb begin
    // only allow simple ASCII chars to be used
    if (CHAR < 32 || CHAR > 126) begin
      out = 0;
    end
    else begin
      // don't read anything outside of the address space
      if (POS > 59) begin
        out = 0;
      end
      else begin
        out = rom[CHAR-32][POS];
      end
    end
  end

endmodule
