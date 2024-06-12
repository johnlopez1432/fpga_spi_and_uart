//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: John Lopez
// 
// Create Date: 03/01/2024 7:31:04 PM
// Design Name: 
// Module Name: uart_8n1_115200
// Project Name: UART 8N1 115200
// Target Devices: 
// Tool Versions: 
// Description: 8 data bits, no partity, 1 stop bit, 115200 baud rate
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: 
// 
//////////////////////////////////////////////////////////////////////////////////

module uart_8n1_115200 (
  input CLK_25MHz,
  input WE,
  input [7:0] DATA_IN,
  input RX_LINE,
  output [7:0] DATA_OUT,
  output TX_LINE,
  output TX_READY,
  output RX_VALID
  );

  const integer max_div = 217; // base clock divider 25M / 115.2k = 217.01
  const integer held_req = max_div / 2; // half of base block to detect start bit
  const integer held_rest = max_div - held_req; // the rest of the clock length to trigger clock pulse

  logic base_clk = 0;
  logic tx_clk = 0;
  logic [7:0] div_count = 0;
  logic [7:0] tx_div_count = 0;
  logic [6:0] rx_held = 0;
  logic start_bit_rx = 0;

  logic rx_valid = 0;
  logic tx_ready = 1;
  logic tx_line = 1;

  logic receiving = 0;
  logic transmitting = 0;

  logic [3:0] rx_bit = 0;
  logic [3:0] tx_bit = 0;

  logic [7:0] rx_char;
  logic [7:0] tx_char;
  assign DATA_OUT = rx_char;

  logic rx_done = 1;
  logic rx_pulse = 0;
  logic rx_success = 0;
  logic stop_rx = 0;
  logic stop_tx = 0;
  
  assign RX_VALID = rx_valid;
  assign TX_READY = tx_ready | transmitting;
  assign TX_LINE = tx_line;

  always_ff @(posedge CLK_25MHz) begin
    // base clock 115200 Hz for receiving
    // this clock needs to be resynchronized
    div_count <= div_count + 1;
    if (div_count > max_div) begin 
      base_clk <= ~base_clk;
      div_count <= 0;
    end

    // tx clock 115200 Hz for transmission
    // this clock does not need to be resynchronized
    // second clock used so rx and tx can be independent
    tx_div_count <= tx_div_count + 1;
    if (tx_div_count > max_div) begin 
      tx_clk <= ~tx_clk;
      tx_div_count <= 0;
    end


    // "catch" start bit and resynchronize base clock
    // rx needs to be held low for half the base clock to be considered valid
    if (rx_done && RX_LINE) begin
      rx_held <= 0;
    end
    else if (rx_done && ~RX_LINE || start_bit_rx) begin
      rx_held <= rx_held + 1;
      if (~start_bit_rx) begin
        // wait until rx has been held low for half the time
        if (rx_held > held_req) begin
          rx_held <= 0;
          start_bit_rx <= 1;
          div_count <= held_rest;
          start_bit_rx <= 0;
          receiving <= 1;
        end
      end
//      else begin
        // wait for the remaining duration of the base clock to pulse low
//        if (rx_held > held_rest) begin 
//          rx_held <= 0;
//          base_clk <= 0;
//          div_count <= 0;
//          start_bit_rx <= 0;
//          receiving <= 1;
//          rx_done <= 0;
//        end
//      end
    end
    



    // only hold rx signal for 1 "cpu" clock cycle
    if (receiving && stop_rx) begin
      rx_pulse <= 0;
      receiving <= 0;
    end
    if (rx_done && rx_success && ~rx_pulse) begin 
      rx_pulse <= 1;
      rx_valid <= 1;
    end
    else if (rx_pulse) begin
      rx_valid <= 0;
    end

    // save next char to transmit
    if (WE) begin
      tx_char <= DATA_IN;
      transmitting <= 1;
    end
    if (transmitting & stop_tx) begin
      transmitting <= 0;
    end

  end


  // receive on falling edge
  always_ff @(negedge base_clk) begin
    stop_rx <= 0;
    rx_done <= 1;
    rx_success <= 0;
    if (receiving) begin
      rx_done <= 0;
      // 1 start bit
      if (rx_bit == 0) begin
        if (RX_LINE) begin
          // start bit shouldn't be high, ignore this tranmission
          rx_done <= 1;
          stop_rx <= 1;
        end
      end
      // 8 data bits
      else if (rx_bit > 0 && rx_bit < 9) begin
        rx_char[rx_bit-1] <= RX_LINE;
      end
      // (no parity bit)
      // 1 stop bit
      else if (rx_bit == 9) begin
        // ignore this transmission if stop bit is low
        if (RX_LINE) begin
          rx_done <= 1;
          rx_success <= 1;
          stop_rx <= 1;
        end
      end
      // framing error
      else if (RX_LINE) begin
        // wait for the line to go high
        rx_done <= 1;
        stop_rx <= 1;
      end
      rx_bit <= rx_bit + 1; // LSB first, MSB last
    end
    else begin
      rx_bit <= 0;
    end
  end


  // transmit on rising edge
  always_ff @(posedge tx_clk) begin
    stop_tx <= 0;
    if (transmitting) begin
      tx_ready <= 0;
      // 1 start bit
      if (tx_bit == 0) begin
        tx_line <= 0;
      end
      // 8 data bits
      else if (tx_bit >= 1 && tx_bit <= 8) begin
        tx_line <= tx_char[tx_bit-1];
      end
      // (no parity bit)
      // 1 stop bit
      else begin
        tx_line <= 1;
        tx_ready <= 1;
        stop_tx <= 1;
      end
      tx_bit <= tx_bit + 1; // LSB first, MSB last
    end
    else begin
      // hold high while not transmitting
      tx_line <= 1;
      tx_bit <= 0;
    end
  end

endmodule
