`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: J. Calllenes
//           P. Hummel
//           John Lopez
//
// Create Date: 01/20/2019 10:36:50 AM
// Module Name: OTTER_Wrapper
// Target Devices: OTTER MCU on Basys3
// Description: OTTER_WRAPPER with Switches, LEDs, Buttons, 
//                80x60 SPI display, and 7-segment display
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Updated MMIO Addresses, signal names
// Revision 0.03 - Add Buttons and RNG
// Revision 0.04 - Add 80x60 SPI Display (John Lopez)
/////////////////////////////////////////////////////////////////////////////

module OTTER_Wrapper(
   input CLK,
   input BTNC,
   input BTNU,
   input BTND,
   input BTNL,
   input BTNR,
   input [15:0] SWITCHES,
   output logic [15:0] LEDS,
   output [7:0] CATHODES,
   output [3:0] ANODES,
   output [7:0] JA
   );
       
    // INPUT PORT IDS ///////////////////////////////////////////////////////
    localparam SWITCHES_AD = 32'h11000000;
    localparam SPI_READ_AD = 32'h11000160;
    localparam RAND_AD     = 32'h11000180;
    localparam BTNU_AD     = 32'h11000060;
    localparam BTND_AD     = 32'h11000064;
    localparam BTNL_AD     = 32'h11000068;
    localparam BTNR_AD     = 32'h1100006c;
           
    // OUTPUT PORT IDS ///////////////////////////////////////////////////////
    localparam LEDS_AD      = 32'h11000020;
    localparam SSEG_AD      = 32'h11000040;
    localparam SPI_ADDR_AD  = 32'h11000120;
    localparam SPI_COLOR_AD = 32'h11000140; 
    
   // Signals for connecting OTTER_MCU to OTTER_wrapper /////////////////////
   logic clk_50 = 0;
    
   logic [31:0] IOBUS_out, IOBUS_in, IOBUS_addr;
   logic s_reset, IOBUS_wr/*, intr*/;
   
   // Signals for connecting SPI Framebuffer Driver
   logic r_spi_we;             // write enable
   logic [12:0] r_spi_wa;      // address of framebuffer to read and write
   logic [7:0] r_spi_wd;       // pixel color data to write to framebuffer
   logic [7:0] r_spi_rd;       // pixel color data read from framebuffer
   
   // Signals for connecting RNG
   logic [31:0] rand_num;
   
   // Registers for buffering outputs  /////////////////////////////////////
   logic [15:0] r_SSEG;
    
   // Declare DEBOUNCE ONE-SHOT ////////////////////////////////////////////////////
   //debounce_one_shot debouncer (.CLK(clk_50), .BTN(BTNL), .DB_BTN(intr));

   // Declare Random Number Gen ////////////////////////////////////////////////////
   RandGen rng (.CLK(CLK), .RST(s_reset), .RANDOM(rand_num));

   // Declare SPI Frame Buffer //////////////////////////////////////////////
   spi_fb_driver_80x60 spi_framebuffer(.CLK_50MHz(clk_50),.RESET(s_reset),
                                          .WA(r_spi_wa),.WD(r_spi_wd),
                                          .WE(r_spi_we),.RD(r_spi_rd),.PMOD(JA));

   // Declare SPI Write-Only Display //////////////////////////////////////////////
   // spi_driver_320x240 spi_display(.CLK_50MHz(clk_50),.RESET(s_reset),
   //                                 .WA(r_spi_wa),.WD(r_spi_wd),
   //                                 .WE(r_spi_we),.PMOD(JA));

   // Declare SPI Text Display //////////////////////////////////////////////
   // spi_text_driver spi_text_display(.CLK_50MHz(clk_50), .RESET(s_reset), 
   //                                  .CHAR(r_spi_wd), .WE(r_spi_we), .PMOD(JA));

   // Declare OTTER_CPU ////////////////////////////////////////////////////
   OTTER_MCU CPU (.CPU_RST(s_reset), .CPU_INTR(1'b0), .CPU_CLK(clk_50),
                  .CPU_IOBUS_OUT(IOBUS_out), .CPU_IOBUS_IN(IOBUS_in),
                  .CPU_IOBUS_ADDR(IOBUS_addr), .CPU_IOBUS_WR(IOBUS_wr));

   // Declare Seven Segment Display /////////////////////////////////////////
   SevSegDisp SSG_DISP (.DATA_IN(r_SSEG), .CLK(CLK), .MODE(1'b1),
                       .CATHODES(CATHODES), .ANODES(ANODES));
   
                           
   // Clock Divider to create 50 MHz Clock //////////////////////////////////
   always_ff @(posedge CLK) begin
       clk_50 <= ~clk_50;
   end
   
   // Connect Signals ///////////////////////////////////////////////////////
   assign s_reset = BTNC;
   
   
   // Connect Board input peripherals (Memory Mapped IO devices) to IOBUS
   always_comb begin
        case(IOBUS_addr)
            SWITCHES_AD: IOBUS_in = {16'b0,SWITCHES};
            SPI_READ_AD: IOBUS_in = {24'b0, r_spi_rd};
            BTNU_AD: IOBUS_in     = {31'b0,BTNU};
            BTND_AD: IOBUS_in     = {31'b0,BTND};
            BTNL_AD: IOBUS_in     = {31'b0,BTNL};
            BTNR_AD: IOBUS_in     = {31'b0,BTNR};
            RAND_AD: IOBUS_in     = rand_num;
            default:     IOBUS_in = 32'b0;    // default bus input to 0
        endcase
    end
   
   
   // Connect Board output peripherals (Memory Mapped IO devices) to IOBUS
    always_ff @ (posedge clk_50) begin
        r_spi_we<=0;       
        if(IOBUS_wr)
            case(IOBUS_addr)
                LEDS_AD: LEDS   <= IOBUS_out[15:0];
                SSEG_AD: r_SSEG <= IOBUS_out[15:0];
                SPI_ADDR_AD: r_spi_wa <= IOBUS_out[12:0];
                SPI_COLOR_AD: begin  
                        r_spi_wd <= IOBUS_out[7:0];
                        r_spi_we <= 1;  
                    end     
            endcase
    end
   
   endmodule
