`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: John Lopez
//
// Create Date: 03/01/2024 7:31:04 PM
// Design Name:
// Module Name: ram128_8_13x6
// Project Name: Character Buffer 13x6
// Target Devices: 
// Tool Versions: 
// Description: Character buffer memory for SPI text driver.
//              2 port memory, 1 for reading, 1 for writing
//              asynchronous read, synchronous write
//              WA - address only for writing, input is WD
//              WE - write enable, only save data when high
//              RA - address only for reading, output is RD
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Uses 9.5/50 BRAM tiles
// 
//////////////////////////////////////////////////////////////////////////////////


module ram256_8_13x6(
    input CLK_50MHz,
    input RESET,
    input WE,           // write enable
    input [6:0] WA,    // write address 1
    input [6:0] RA,    // read address 2
    input [7:0] WD,     // write data to address 1
    output [7:0] RD   // read data from address 1
    );
    
    logic [7:0] r_memory [92:0];  // 16 * 6 - (16 - 13)
    
    // Initialize all memory to 32s (space char)
    initial begin
        int i;
        for (i = 0; i < 93; i++) begin
            r_memory[i] = 32;
        end
    end
    
    // only save data on rising edge
    always_ff @(posedge CLK_50MHz) begin
        if (RESET) begin
            int i;
            for (i = 0; i < 93; i++) begin
                r_memory[i] = 32;
            end
        end
        else if (WE) begin
            r_memory[WA] <= WD;
        end
    end
    
    assign RD = r_memory[RA];
    
endmodule
