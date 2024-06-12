`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: John Lopez
// 
// Create Date: 03/01/2024 7:31:04 PM
// Design Name: 
// Module Name: spi_controller
// Project Name: SPI Display Controller
// Target Devices: 
// Tool Versions: 
// Description: Sends commands and data to an SPI display
// 
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: 
// 
//////////////////////////////////////////////////////////////////////////////////

module spi_controller(
  input CLK_25MHz,   // 25 MHz clock for clock dividers
  input [15:0] DATA, // 2 bytes of data
  input [3:0] LEN,   // send up to 16 bits at a time (len-1, len=0 mean 1 bit is sent)
  input MODE,        // 0 = command, 1 = data
  input RESET,       // active high
  input WE,          // active high
  output SPI_CS,     // active low
  output SPI_RESET,  // active low
  output SPI_DC,     // 0 = command, 1 = data
  output SPI_SDI,    // data
  output SPI_SCK,    // clock
  output READY
  );

  logic clk_12MHz = 0;
  logic clk_6MHz = 0;
  logic [3:0] pos = 0;
  logic [15:0] current_data = 0;
  logic [3:0] current_len = 0;
  logic current_mode = 0;
  
  logic [15:0] next_data = 0;
  logic [3:0] next_len = 0;
  logic next_mode = 0;
  
  logic busy = 1;
  logic sending = 0;
  
  logic sdi_out = 0;
  logic dc_out = 0;
  logic cs_out = 1;
  logic reset_out = 1;

  typedef enum { INIT_0, INIT_1, INIT_2, RUN } STATE_T;
  STATE_T state = INIT_0;

  logic [18:0] reset_count = 0;
  const integer reset_hold = 375000;

  assign SPI_DC = current_mode;
  assign SPI_RESET = reset_out; // RESET is active low
  assign SPI_SCK = clk_6MHz; // SCK runs at 6.25 MHz (can be overclocked to 6.6 MHz)
  assign SPI_SDI = sdi_out;
  assign SPI_CS = cs_out;
  assign READY = ~busy;

  always_ff @(posedge CLK_25MHz) begin
    clk_12MHz <= ~clk_12MHz; // 12.5 MHz clock since max clock speed is 6.6MHz

    if (RESET) begin
      cs_out <= 1;
      sending <= 0;
      busy <= 1;
    end

    case (state)
      INIT_0: begin
        busy <= 1;
        reset_out <= 1; // active low
        reset_count <= reset_count + 1;
        if (reset_count > reset_hold) begin
          state <= INIT_1;
          reset_count <= 0;
        end
      end
      INIT_1: begin
        reset_out <= 0;
        reset_count <= reset_count + 1;
        if (reset_count > reset_hold) begin
          state <= INIT_2;
          reset_count <= 0;
        end
      end
      INIT_2: begin
        reset_out <= 1;
        reset_count <= reset_count + 1;
        if (reset_count > reset_hold) begin
          state <= RUN;
          reset_count <= 0;
          busy <= 0;
        end
      end
      RUN: begin
        if (WE) begin
          busy <= 1;
          next_data <= DATA;
          next_mode <= MODE;
          next_len <= LEN;
        end
          
    //    if (busy) begin
    //      // disable chip select (active low)
    //      cs_out <= 0;
    //    end
        if (clk_12MHz) begin
          // handle spi display clock
          clk_6MHz <= ~clk_6MHz;
          
          if (clk_6MHz && ~busy) begin
            cs_out <= 1;
          end

          // get current data
          if (busy && ~sending) begin
            pos <= next_len;
            current_data <= next_data;
            current_mode <= next_mode;
            sending <= 1;
            cs_out <= 0;
          end
          
          // send data
          if (sending) begin
            // change data on falling edge (read on rising edge)
            if (clk_6MHz) begin
              // send each bit, starting with MSB
              sdi_out <= current_data[pos];
              pos <= pos - 1;
              if (pos == 0) begin
                busy <= 0;
                if (~WE) begin
                  sending <= 0;
                end
              end
            end
          end
        end
      end
      default:
        state <= INIT_0;
    endcase
  end

endmodule
