`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: John Lopez
// 
// Create Date: 03/01/2024 7:31:04 PM
// Design Name: 
// Module Name: color_8to18
// Project Name: Color Map 8-bit to 18-bit
// Target Devices: 
// Tool Versions: 
// Description: Remaps 8-bit colors into 18-bit colors
// 
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module color_8to18(
  input [7:0] COLOR_8BIT,
  output [17:0] COLOR_18BIT
  );

  logic [2:0] in_r;
  logic [2:0] in_g;
  logic [1:0] in_b;

  logic [5:0] out_r;
  logic [5:0] out_g;
  logic [5:0] out_b;

  assign in_r = COLOR_8BIT[7:5];
  assign in_g = COLOR_8BIT[4:2];
  assign in_b = COLOR_8BIT[1:0];


  assign COLOR_18BIT[17:12] = out_r;
  assign COLOR_18BIT[11:6] = out_g;
  assign COLOR_18BIT[5:0] = out_b;

  always_comb begin
    case (in_r)
      0: out_r = 0;
      1: out_r = 9;
      2: out_r = 18;
      3: out_r = 27;
      4: out_r = 36;
      5: out_r = 45;
      6: out_r = 54;
      7: out_r = 63;
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
      1: out_b = 21;
      2: out_b = 42;
      3: out_b = 63;
    endcase
  end

endmodule
