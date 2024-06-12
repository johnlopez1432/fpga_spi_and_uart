`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: John Lopez
// 
// Create Date: 03/01/2024 7:31:04 PM
// Design Name: 
// Module Name: uart_8n1_115200_tb
// Project Name: UART Testbench
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: uart_8n1_115200
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_8n1_115200_tb();

  logic tb_clk_a, tb_we_a, tb_tx_ready_a, tb_rx_valid_a;
  logic tb_clk_b, tb_we_b, tb_tx_ready_b, tb_rx_valid_b;
  logic [7:0] tb_data_in_a, tb_data_out_a;
  logic [7:0] tb_data_in_b, tb_data_out_b;

  // connect two modules together
  logic tb_rx_a_tx_b, tb_tx_a_rx_b;

  uart_8n1_115200 uart_a( 
    .CLK_25MHz(tb_clk_a), 
    .WE(tb_we_a), 
    .DATA_IN(tb_data_in_a), 
    .RX_LINE(tb_rx_a_tx_b), 
    .DATA_OUT(tb_data_out_a), 
    .TX_LINE(tb_tx_a_rx_b), 
    .TX_READY(tb_tx_ready_a), 
    .RX_VALID(tb_rx_valid_a)
  );

  uart_8n1_115200 uart_b( 
    .CLK_25MHz(tb_clk_b), 
    .WE(tb_we_b), 
    .DATA_IN(tb_data_in_b), 
    .RX_LINE(tb_tx_a_rx_b), 
    .DATA_OUT(tb_data_out_b), 
    .TX_LINE(tb_rx_a_tx_b), 
    .TX_READY(tb_tx_ready_b), 
    .RX_VALID(tb_rx_valid_b)
  );

  always #6 tb_clk_a = ~tb_clk_a;
  always #6 tb_clk_b = ~tb_clk_b;

  initial begin
    tb_clk_a = 0;
    tb_we_a = 0;
    # 3 // a and b have same internal frequency, but are offset
    tb_clk_b = 1;
    
    // a sending to b
    # 500
    tb_we_a = 1;
    tb_data_in_a = 72; // H
    # 12
    tb_we_a = 0;
    
    # 70000
    tb_we_a = 1;
    tb_data_in_a = 101; // e
    # 12
    tb_we_a = 0;
    
    # 70000
    tb_we_a = 1;
    tb_data_in_a = 108; // l
    # 12
    tb_we_a = 0;
    
    // b sending to a
    tb_we_b = 1;
    tb_data_in_b = 66; // B
    # 12
    tb_we_b = 0;
    
    // a sending to b
    # 90000
    tb_we_a = 1;
    tb_data_in_a = 108; // l
    # 12
    tb_we_a = 0;
    
    # 70000
    tb_we_a = 1;
    tb_data_in_a = 111; // o
    # 12
    tb_we_a = 0;
    
    // b sending to a
    tb_we_b = 1;
    tb_data_in_b = 121; // y
    # 12
    tb_we_b = 0;
    
    # 70500
    tb_we_b = 1;
    tb_data_in_b = 101; // e
    # 12
    tb_we_b = 0;
    
  end
    
endmodule
