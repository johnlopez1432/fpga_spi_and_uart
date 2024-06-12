//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: John Lopez
// 
// Create Date: 03/01/2024 7:31:04 PM
// Design Name: 
// Module Name: uart_terminal_15200
// Project Name: UART Terminal 115200
// Target Devices: 
// Tool Versions: 
// Description: Terminal for UART protocol. Runs at 115200 baud rate 
//              with 8N1 UART config (1 character per transmission)
// 
// Dependencies: debounce_one_shot
//               uart_8n1_115200
//               text_driver_80x60
//               spi_fb_driver_80x60 OR vga_fb_driver_80x60
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: THIS MODULE IS NOT WORKING. 
//                      IT HAS BEEN KEPT HERE FOR FUTURE WORK
// 
//////////////////////////////////////////////////////////////////////////////////

module uart_terminal_115200 (
  input CLK,
  input BTNC, // enter
  input BTNU, // reset
  input BTND, // new line
  input BTNL, // backspace
  input BTNR, // space
  input [7:0] SWITCHES, // ascii
  output JB_IN,
  output [6:0] JB_OUT,
//  output [15:0] LEDS,
  // output [7:0] JA,       // comment out for VGA
  output [7:0] VGA_RGB,  // comment out for SPI
  output VGA_HS,         // comment out for SPI
  output VGA_VS          // comment out for SPI
  );

  logic clk_50MHz = 0;
  logic clk_25MHz = 0;
  logic clk_2Hz = 0;
  logic [24:0] clk_div = 0;

  logic s_reset;

  logic btn_confirm;
  logic btn_return;
  logic btn_back;
  logic btn_space;

  logic show_char = 0;
  logic [7:0] shown_char = 0;
  logic new_char = 0;
  logic pulsed = 0;
  logic disp_one_shot = 0;
  logic r_char_we = 0;
  logic [7:0] r_char = 0;

  logic save_char = 0;
  logic [7:0] saved_char = 255;
  logic [7:0] next_char = 255;
  logic del_char = 0;

  logic [7:0] r_disp_rd;
  logic [12:0] r_disp_wa;
  logic [7:0] r_disp_wd;
  logic r_disp_we;

  logic uart_send = 0;
  logic uart_rx = 0;
  logic [7:0] uart_char = 255;
  logic r_uart_we = 0;
  logic [7:0] r_uart_data_in;
  logic [7:0] r_uart_data_out;
  logic r_uart_rx_line;
  logic r_uart_tx_line;
  logic r_uart_rx_valid;
  logic r_uart_tx_ready;

  assign JB_IN = r_uart_rx_line;
  assign JB_OUT = {2'b0, ~s_reset, 2'b0, r_uart_tx_line, 1'b0};

  // clock dividers
  always_ff @(posedge CLK) begin
    clk_50MHz <= ~clk_50MHz;
    s_reset <= 0;
    if(BTNU) begin
      clk_div   <= 0;
      clk_2Hz <= 1'b0;
      s_reset <= 1;
    end
    else begin
      clk_div <= clk_div + 1;
      if(clk_div > 25000000) begin
        clk_div <= 0;
        clk_2Hz <= ~clk_2Hz;
      end
    end
  end

  // display logic
  always_ff @(posedge clk_50MHz) begin
    clk_25MHz <= ~clk_25MHz;

    // send temporary char to display
    r_char_we <= 0;
    if (clk_2Hz & ~pulsed) begin
      pulsed <= 1;
      r_char_we <= 1;
    end
    else if (~clk_2Hz & pulsed) begin
      pulsed <= 0;
      disp_one_shot <= 0;
    end

    // center button pressed, confirm character
    saved_char <= 255;
    if (btn_confirm) begin
      save_char <= 1;
      saved_char <= shown_char;
    end
    // down button pressed, add newline character
    if (btn_return) begin
      save_char <= 1;
      saved_char <= 10;
    end
    // left button pressed, add backspace character
    if (btn_return) begin
      save_char <= 1;
      saved_char <= 8;
    end
    // right button pressed, add space character
    if (btn_return) begin
      save_char <= 1;
      saved_char <= 32;
    end
    if (uart_rx) begin
      save_char <= 1;
      saved_char <= uart_char;
    end
    // delete shown (temporary) char if necessary, then save new char to display
     if (~new_char & save_char & show_char) begin
       save_char <= 0;
       r_char_we <= 1;
       if (uart_rx) begin
         uart_rx <= 0;
       end
       else begin
         uart_send <= 1;
       end
     end
//    if (save_char) begin
//      r_char_we <= 1;
//      if (uart_rx) begin
//        uart_rx <= 0;
//      end
//      else begin
//        uart_send <= 1;
//      end
//      // delete this char
//      if (show_char) begin
//        next_char <= saved_char; // buffer char
//        del_char <= 1;
//        saved_char <= 8; // backspace;
//      end
//      else if (del_char) begin
//        saved_char <= next_char; // grab from buffer
//        save_char <= 0;
//        del_char <= 0;
//      end
//      else begin // else just send the char
//        save_char <= 0;
//      end
//    end


    // uart tx logic
    if (clk_25MHz) begin
      if (uart_send) begin
        r_uart_data_in <= saved_char;
        r_uart_we <= 1;
        uart_send <= 0;
      end
      if (r_uart_rx_valid) begin
        uart_char <= r_uart_data_out;
        uart_rx <= 1;
      end
    end
  end

  always_comb begin
    if (saved_char != 255) begin
      r_char = saved_char;
    end
    else begin
      r_char = shown_char;
    end
  end

  // show current char as flashing (before sent to UART)
  always_ff @(posedge clk_2Hz) begin
    show_char <= ~show_char;
    if (show_char) begin
      shown_char <= SWITCHES[7:0];
    end
    else begin
      shown_char <= 8; // backspace
    end
  end


  uart_8n1_115200 uart( .CLK_25MHz(clk_25MHz), .WE(r_uart_we), .DATA_IN(r_uart_data_in), 
                        .RX_LINE(r_uart_rx_line), .DATA_OUT(r_uart_data_out), .TX_LINE(r_uart_tx_line), 
                        .TX_READY(r_uart_tx_ready), .RX_VALID(r_uart_rx_valid));

  text_driver_80x60 char_mem( .CLK_50MHz(clk_50MHz), .RESET(s_reset), .CHAR(r_char), 
                              .WE(r_char_we), .DISP_ADDR(r_disp_wa), .DISP_DATA(r_disp_wd), .DISP_WE(r_disp_we));

  debounce_one_shot debouncer_c (.CLK(clk_50MHz), .BTN(BTNC), .DB_BTN(btn_confirm));
  debounce_one_shot debouncer_d (.CLK(clk_50MHz), .BTN(BTND), .DB_BTN(btn_return));
  debounce_one_shot debouncer_l (.CLK(clk_50MHz), .BTN(BTNL), .DB_BTN(btn_back));
  debounce_one_shot debouncer_r (.CLK(clk_50MHz), .BTN(BTNR), .DB_BTN(btn_space));

  // // comment out if using VGA
  // spi_fb_driver_80x60 display( .CLK_50MHz(clk_50MHz), .RESET(s_reset), .WA(r_disp_wa), 
  //                              .WD(r_disp_wd), .WE(r_disp_we), .RD(r_disp_rd), .PMOD(JA));

  // comment out if using SPI
  vga_fb_driver_80x60 VGA( .CLK_50MHz(clk_50MHz), .WA(r_disp_wa), .WD(r_disp_wd), .WE(r_disp_we), 
                            .RD(r_disp_rd), .ROUT(VGA_RGB[7:5]), .GOUT(VGA_RGB[4:2]), 
                            .BOUT(VGA_RGB[1:0]), .HS(VGA_HS), .VS(VGA_VS));


endmodule
