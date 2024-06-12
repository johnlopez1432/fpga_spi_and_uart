`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: John Lopez
//
// Create Date: 03/01/2024 7:31:04 PM
// Design Name:
// Module Name: fifo_16x4
// Project Name: FIFO Queue 33 bits, 8 slots (264 bits total)
// Target Devices: 
// Tool Versions: 
// Description: FIFO queue that stores 8 slots of 33 bits each.
// 
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Does not have protection for reading faster than writing
// 
//////////////////////////////////////////////////////////////////////////////////

module fifo_33x8(
  input CLK,
  input RESET,
  input RE,
  input WE,
  input [32:0] IN,
  output [32:0] OUT
  );

  // pointers (0->7 then rollover)
  logic [2:0] read_idx = 0;
  logic [2:0] write_idx = 0;

  // 33-bit width, 8 slots
  logic [32:0] queue [0:7];
  
  logic [32:0] out_data;
  
  assign OUT = out_data;

  // synchronous read and write
  always_ff @(posedge CLK) begin
    if (RESET) begin 
      read_idx <= 0;
      write_idx <= 0;
    end
    else begin
      // synchronous write
      if (WE) begin
        queue[write_idx] <= IN;
        write_idx <= write_idx + 1;
      end

      // synchronous read
      if (RE) begin
        out_data <= queue[read_idx];
        read_idx <= read_idx + 1;
      end
    end
  end

endmodule
