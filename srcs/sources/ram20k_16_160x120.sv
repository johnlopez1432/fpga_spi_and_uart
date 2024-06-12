`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: John Lopez
//
// Create Date: 03/01/2024 7:31:04 PM
// Design Name:
// Module Name: ram20k_16_160x120
// Project Name: SPI Framebuffer RAM 160x120
// Target Devices: 
// Tool Versions: 
// Description: Framebuffer memory for SPI display driver.
//              Uses Block RAM which requires synchronous reads and writes
//              3 port memory, 2 for reading, 1 for writing
//              ADDR1 - first address for reading and writing,
//                        output is RD1, input is WD
//              WE1   - write enable, only save data (WD to ADDR1) when high
//              ADDR2 - second address only for reading, output is RD2
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Uses 9.5/50 BRAM tiles
// 
//////////////////////////////////////////////////////////////////////////////////


module ram20k_16_160x120(
  input CLK,
  input WE1,          // write enable
  input [14:0] ADDR1, // read/write address 1
  input [14:0] ADDR2, // read address 2
  input [15:0] WD,    // write data to address 1
  output [15:0] RD1,  // read data from address 1
  output [15:0] RD2   // read data from address 2
  );
  
  (* rom_style="{distributed | block}" *)
  (* ram_decomp = "power" *) logic [15:0] ram [0:19199]; // 16 color bits per pixel, 160 * 120 = 76800 pixels total
  
  logic [15:0] r_out1;
  logic [15:0] r_out2;
  
  assign RD1 = r_out1;
  assign RD2 = r_out2;
  
  initial begin
    $readmemh("image.mem", ram, 0, 19199);
  end

  // BRAM requires synchronous read and write
  always_ff @(posedge CLK) begin
    // synchronous write
    if (WE1 && ADDR1 < 19200)
      ram[ADDR1] <= WD;

    // synchronous read
    if (ADDR1 >= 19200)
      r_out1 <= 0;
    else
      r_out1 <= ram[ADDR1];

    if (ADDR2 >= 19200)
      r_out2 <= 0;
    else
      r_out2 <= ram[ADDR2];
  end

endmodule
