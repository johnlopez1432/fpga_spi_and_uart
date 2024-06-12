`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: John Lopez
// 
// Create Date: 03/01/2024 7:31:04 PM
// Design Name: 
// Module Name: text_driver_80x60
// Project Name: Text Display for 80x60 Display
// Target Devices: 
// Tool Versions: 
// Description: Text display driver that stores a character buffer (13x6)
//              and sends out pixel information for a 80x60 pixel display
// 
// Dependencies: ram256_8_13x6
//               ascii_rom
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Accepts ASCII characters 32-126 and 
//                      \r (13) \n (10) \t (9) \b (8)
//                      if CHAR = 127 (DEL) the screen will clear (clears buffer)
// 
//////////////////////////////////////////////////////////////////////////////////

module text_driver_80x60 (
  input CLK_50MHz,
  input RESET,
  input [7:0] CHAR,
  input WE,
  output [12:0] DISP_ADDR, // {row, col}
  output [7:0] DISP_DATA,
  output DISP_WE
  );

  logic [12:0] addr;
  logic [7:0] data;
  logic send = 0;

  logic s_reset = 0;

  logic [6:0] write_cursor;
  logic [3:0] write_col = 0; // 0-12
  logic [2:0] write_row = 0; // 0-5

  logic [7:0] write_char;
  logic write_en = 0;

  logic [6:0] read_cursor;
  logic [3:0] read_col = 0; // 0-12
  logic [2:0] read_row = 0; // 0-5

  logic [7:0] read_char;
  logic [5:0] pos = 59;
  logic pixel_status;

  logic [6:0] out_col = 0; // 0-79
  logic [5:0] out_row = 0; // 0-59

  logic [2:0] px_col = 0; // 0-5
  logic [3:0] px_row = 0; // 0-9

  assign write_cursor = {write_row, write_col};
  assign read_cursor = {read_row, read_col};

  // SPI Framebuffer Driver
  // spi_fb_driver_80x60 framebuffer(.CLK_50MHz(CLK_50MHz), .RESET(s_reset), .WA(addr), 
  //                           .WD(data), .WE(send), .RD(l), .PMOD(PMOD));
  assign DISP_ADDR = addr;
  assign DISP_DATA = data;
  assign DISP_WE = send;
  
  // Character Buffer
  ram256_8_13x6 char_buffer(.CLK_50MHz(CLK_50MHz), .RESET(s_reset), .WE(write_en), .WA(write_cursor), 
                            .RA(read_cursor), .WD(write_char), .RD(read_char));

  // ASCII ROM
  ascii_rom bitmap(.CHAR(read_char), .POS(pos), .PIXEL(pixel_status));

  always_ff @(posedge CLK_50MHz) begin
    if (RESET || CHAR == 127) begin
      // handle reset
      s_reset <= 1;
      write_col <= 0;
      write_row <= 0;
      read_col <= 0;
      read_row <= 0;
      out_col <= 0;
      out_row <= 0;
      px_col <= 0;
      px_col <= 0;
      pos <= 59;
      send <= 0;
    end
    else begin
      s_reset <= 0;
    


      // add char to char buffer (and advance write cursor)
      write_en <= 0;
      if (WE) begin
        write_char <= CHAR;
        write_en <= 1;
        if (write_char == 10) begin
          // newline
          if (write_row < 5) begin
            write_row <= write_row + 1;
          end
          else begin
            write_row <= 0;
          end
          write_col <= 0;
        end
        else if (write_char == 13) begin
          // carriage return
          write_col <= 0;
        end
        else if (write_char == 9) begin
          // tab
          if (write_col < 11) begin
            write_col <= write_col + 2;
          end
        end
        else if (write_char == 32) begin
          // space
          if (write_col < 12) begin
            write_col <= write_col + 1;
          end
        end
        else if (write_char == 8) begin
          // backspace
          if (write_col > 0) begin
            write_col <= write_col - 1;
          end
        end
        else if (write_char >= 32 && write_char <= 126 && write_col < 13 && write_row < 6) begin
          write_col <= write_col + 1;
        end
      end



      // send characters to framebuffer
      if (pixel_status) begin
        data <= 8'h00;
      end
      else begin
        data <= 8'hFF;
      end
      addr <= {out_row+px_row, out_col+px_col};
      send <= 1;

      // get next pixel
      if (pos > 0) begin
        pos <= pos - 1;
        // get next pixel position
        px_col <= px_col + 1;
        if (px_col >= 5) begin // each char is 6 px wide
          px_row <= px_row + 1;
          px_col <= 0;
          if (px_row >= 9) begin // each char is 10 px tall
            px_row <= 0;
          end
        end
      end
      else begin
        pos <= 59;
        px_col <= 0;
        px_row <= 0;
        // get next char position
        read_col <= read_col + 1;
        out_col <= out_col + 6; // each char is 6 px wide
        if (read_col > 12) begin // screen is 12 chars wide
          read_row <= read_row + 1;
          out_row <= out_row + 10; // each char is 10 px tall
          read_col <= 0;
          out_col <= 0;
          if (read_row > 5) begin // screen is 6 rows tall
            read_row <= 0;
            out_row <= 0;
          end
        end
      end
    end

  end

endmodule
