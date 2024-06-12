`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: John Lopez
// 
// Create Date: 03/01/2024 7:31:04 PM
// Design Name: 
// Module Name: spi_driver_320x240
// Project Name: SPI Display 320x240
// Target Devices: 
// Tool Versions: 
// Description: SPI display driver (Write-only),
//              Does not contain a framebuffer to save pixel data.
//              Controls input interfaces  (WA, WD, WE), 
//              and SPI output signals (PMOD).
// 
// Dependencies: fifo_33x8
//               spi_controller
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Includes a small buffer, but can only handle bursts of data
// 
//////////////////////////////////////////////////////////////////////////////////

module spi_driver_320x240 (
  input CLK_50MHz,
  input RESET,
  input [16:0] WA,
  input [15:0] WD,
  input WE,
  output [7:0] PMOD,
  output BUSY
  );

  typedef enum {
    NOP,         // send 4 empty commands
    MADCTL,      // Memory Access Control (send command)
    MADCTL_DATA, // Memory Access Control (send data)
    COLMOD,      // Pixel Format Set (send command)
    COLMOD_DATA, // Pixel Format Set (send data)
    CASET,       // Column Address Set (send command)
    CASET_SC,    // Column Address Set (send first addr)
    CASET_EC,    // Column Address Set (send last addr)
    PASET,       // Page Address Set (send command)
    PASET_SC,    // Page Address Set (send first addr)
    PASET_EC,    // Page Address Set (send last addr)
    RAMWR,       // Memory Write (send command)
    RAMWR_DATA   // Memory Write (send data)
  } STATE_T;

  logic clk_25MHz = 0;
  
  logic cs_out, reset_out, dc_out, sdi_out, sck_out;

  logic [15:0] data;
  logic [3:0] len;
  logic mode;
  logic send;
  STATE_T state;

  logic [3:0] sending = 0;
  logic [8:0] current_col;
  logic [7:0] current_row;
  logic [15:0] current_data;

  logic fifo_read;
  logic [32:0] fifo_out;

  logic ready;
  logic [1:0] init_burn = 0;
  logic busy = 0;
  assign BUSY = busy;

  always_ff @(posedge CLK_50MHz) begin
    // clock divider
    clk_25MHz <= ~clk_25MHz;

    // queue write commands    
    if (RESET) begin
      sending <= 0;
    end
    if (state != RAMWR_DATA) begin
      busy <= 1;
    end
    if (WE) begin
      sending <= sending + 1; // track the number of data frames to be sent
      if (sending > 7) begin
        busy <= 1;
      end
    end
    // get current data (enable read before the current data is set)
    if (state == CASET && sending > 0 && ~clk_25MHz) begin
      fifo_read <= 1;
    end
    else begin
      fifo_read <= 0;
    end
    if (state == RAMWR_DATA && clk_25MHz) begin
      sending <= sending - 1;
      if (sending < 6) begin
        busy <= 0;
      end
    end
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

  // FIFO Queue
  fifo_33x8 queue(.CLK(CLK_50MHz), .WE(WE), .RE(fifo_read),
                      .RESET(RESET), .IN({WA,WD}), .OUT(fifo_out));

  // driver logic
  always_ff @(posedge clk_25MHz) begin
    if (RESET) begin
      state <= MADCTL;
      send <= 0;
    end
    else begin
      if (ready) begin
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
            state <= CASET;
          end
          CASET: begin
            // wait for data to be sent
            if (sending > 0) begin
              current_col <= fifo_out[32:16]%320;
              current_row <= fifo_out[32:16]/320;
              current_data <= fifo_out[15:0];
              data <= 8'h2A;
              len <= 15;
              mode <= 0;
              send <= 1;
              state <= CASET_SC;
            end
            else begin
              send <= 0;
              state <= CASET;
            end
          end
          CASET_SC: begin
            data <= current_col;
            len <= 15;
            mode <= 1;
            state <= CASET_EC;
          end
          CASET_EC: begin
            data <= current_col;
            len <= 15;
            mode <= 1;
            send <= 1;
            state <= PASET;
          end
          PASET: begin
            data <= 8'h2B;
            len <= 15;
            mode <= 0;
            send <= 1;
            state <= PASET_SC;
          end
          PASET_SC: begin
            data <= current_row;
            len <= 15;
            mode <= 1;
            send <= 1;
            state <= PASET_EC;
          end
          PASET_EC: begin
            data <= current_row;
            len <= 15;
            mode <= 1;
            send <= 1;
            state <= RAMWR;
          end
          RAMWR: begin
            data <= 8'h2C;
            len <= 7;
            mode <= 0;
            send <= 1;
            state <= RAMWR_DATA;
          end
          RAMWR_DATA: begin
            data <= current_data;
            len <= 15;
            mode <= 1;
            send <= 1;
            state <= CASET;
          end
          default: state <= MADCTL;
        endcase
      end
    end
  end

endmodule
