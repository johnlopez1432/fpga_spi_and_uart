`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: John Lopez
// 
// Create Date: 03/01/2024 7:31:04 PM
// Design Name: 
// Module Name: color_8to16
// Project Name: Color Map 8-bit to 16-bit
// Target Devices: 
// Tool Versions: 
// Description: Remaps 8-bit colors into 16-bit colors
// 
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module color_8to16(
  input [7:0] COLOR_8BIT,
  output [15:0] COLOR_16BIT
  );

  logic [2:0] in_r;
  logic [2:0] in_g;
  logic [1:0] in_b;

  logic [4:0] out_r;
  logic [5:0] out_g;
  logic [4:0] out_b;

  assign in_r = COLOR_8BIT[7:5];
  assign in_g = COLOR_8BIT[4:2];
  assign in_b = COLOR_8BIT[1:0];
  

  assign COLOR_16BIT[15:11] = out_r;
  assign COLOR_16BIT[10:5] = out_g;
  assign COLOR_16BIT[4:0] = out_b;

  always_comb begin
    case (in_r)
      0: out_r = 0;
      1: out_r = 4;
      2: out_r = 8;
      3: out_r = 13;
      4: out_r = 17;
      5: out_r = 22;
      6: out_r = 26;
      7: out_r = 21;
    endcase

    case (in_g)
      0: out_g = 0;
      1: out_g = 9;
      2: out_g = 18;
      3: out_g = 27;
      4: out_g = 36;
      5: out_g = 45;
      6: out_g = 54;
      7: out_g = 63;
    endcase

    case (in_b)
      0: out_b = 0;
      1: out_b = 10;
      2: out_b = 21;
      3: out_b = 31;
    endcase
  end

endmodule
