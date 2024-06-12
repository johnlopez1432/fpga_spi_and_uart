`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: John Lopez
// 
// Create Date: 03/01/2024 7:31:04 PM
// Design Name: 
// Module Name: spi_fb_driver_160x120
// Project Name: SPI Display 160x120
// Target Devices: 
// Tool Versions: 
// Description: SPI framebuffer driver. Creates 20k x 16 framebuffer, 
//              control input interfaces (WA, WD, WE, RD),
//              and SPI output signals (RD, PMOD).
//              
//              Downscales the SPI display by 2 times (320x240 -> 160x120) and
//              allows for 16-bit high color
// 
// Dependencies: ram20k_16_160x120
//               spi_controller
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Since the Basys3 board has limited RAM this module
//                      is needed to downscale the resolution of the display.
//                      This allows both the OTTER MCU and the display
//                      to be implemented on the Basys3 board.
// 
//////////////////////////////////////////////////////////////////////////////////

module spi_fb_driver_160x120 (
  input CLK_50MHz,
  input RESET,
  input [14:0] WA,
  input [15:0] WD,
  input WE,
  output [15:0] RD,
  output [7:0] PMOD
  );

  typedef enum {
    NOP,
    MADCTL,      // Memory Access Control (send command)
    MADCTL_DATA, // Memory Access Control (send data)
    COLMOD,      // Pixel Format Set (send command)
    COLMOD_DATA, // Pixel Format Set (send data)
    RAMWR,       // Memory Write (send command)
    RAMWR_DATA   // Memory Write (send data)
  } STATE_T;

  logic clk_25MHz = 0;
  
  logic cs_out, reset_out, dc_out, sdi_out, sck_out, ready;

  logic [14:0] s_fb_ra;
  logic [15:0] s_fb_rd;

  logic [16:0] current_addr = 0;

  logic [15:0] data;
  logic [3:0] len;
  logic mode;
  logic send = 0;
  STATE_T state;
  logic [1:0] init_burn = 0;

  // clock divider
  always_ff @(posedge CLK_50MHz) begin
    clk_25MHz <= ~clk_25MHz;
  end

  // SPI Controller
  spi_controller spi_controller (
  .CLK_25MHz(clk_25MHz),
  .DATA(data),
  .LEN(len),
  .MODE(mode),
  .RESET(RESET),
  .WE(send),
  .SPI_CS(cs_out),
  .SPI_RESET(reset_out),
  .SPI_DC(dc_out),
  .SPI_SDI(sdi_out),
  .SPI_SCK(sck_out),
  .READY(ready)
  );
  
  assign PMOD = {cs_out,reset_out,dc_out,sdi_out,3'b000,sck_out};

  // Framebuffer
  ram20k_16_160x120 framebuffer(.CLK(CLK_50MHz), .WE1(WE), .ADDR2(s_fb_ra),
                                  .ADDR1(WA), .WD(WD), .RD2(s_fb_rd), .RD1(RD));

  assign s_fb_ra = ((current_addr/640)*160) + ((current_addr%320)>>1);

  // driver logic
  always_ff @(negedge clk_25MHz) begin
    if (RESET) begin
      current_addr <= 0;
      state <= NOP;
      send <= 0;
      init_burn <= 0;
    end
    else if (ready) begin
      case (state)
        NOP: begin
          data <= 8'h00;
          len <= 7;
          mode <= 0;
          send <= 1;
          if (init_burn == 3) begin
            state <= MADCTL;
          end
          init_burn <= init_burn + 1;
        end
        MADCTL: begin
          data <= 8'h36;
          len <= 7;
          mode <= 0;
          send <= 1;
          state <= MADCTL_DATA;
        end
        MADCTL_DATA: begin
          data <= 8'b00100000;
          len <= 7;
          mode <= 1;
          send <= 1;
          state <= COLMOD;
        end
        COLMOD: begin
          data <= 8'h3A;
          len <= 7;
          mode <= 0;
          send <= 1;
          state <= COLMOD_DATA;
        end
        COLMOD_DATA: begin
          data <= 8'b01010101;
          len <= 7;
          mode <= 1;
          send <= 1;
          state <= RAMWR;
        end
        RAMWR: begin
          data <= 8'h2C;
          len <= 7;
          mode <= 0;
          send <= 1;
          current_addr <= 0;
          state <= RAMWR_DATA;
        end
        RAMWR_DATA: begin
          data <= s_fb_rd;
          len <= 15;
          mode <= 1;
          send <= 1;
          if (current_addr >= 76799) begin
            current_addr <= 0;
          end
          else begin
            current_addr <= current_addr + 1;
          end
        end
        default: state <= NOP;
      endcase
    end
    else begin
      send <= 0;
    end
  end

endmodule
