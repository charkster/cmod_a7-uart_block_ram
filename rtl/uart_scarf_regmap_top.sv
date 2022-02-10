
module uart_scarf_regmap_top
( input  logic clk,          // board clock, 100MHz
  input  logic button_0,     // used as async reset
  input  logic uart_txd_in,  // from FT2232H
  output logic uart_rxd_out  // to FT2232H
  );
  
  logic        clk_100mhz;
  logic        reset;
  logic  [7:0] read_data_in;
  logic  [7:0] data_out;
  logic        data_out_valid;
  logic        data_out_finished;
  logic  [6:0] slave_id;
  logic        rnw;
  logic        rst_n_100mhz_sync;
  logic        bram_wen;
  logic        bram_ren;
  logic [12:0] bram_addr;
  logic  [7:0] bram_read_data;
  logic  [7:0] bram_write_data;

  assign clk_100mhz = clk;      // no PLL needed
  assign reset      = button_0; // button is low until pressed, then it is high 

uart_scarf u_uart_scarf
  ( .rx               (uart_txd_in),       // input
    .tx               (uart_rxd_out),      // output
    .clk              (clk_100mhz),        // input
    .rst_n            (~reset),            // input
    .read_data_in,                         // input  [7:0]
    .rst_n_sync       (rst_n_100mhz_sync), // output
    .data_out,                             // output [7:0]
    .data_out_valid,                       // output
    .data_out_finished,                    // output
    .slave_id,                             // output [6:0]
    .rnw                                   // output
   );

  scarf_bram
  # ( .SLAVE_ID(7'h01) )
  u_scarf_bram
  ( .clk              (clk_100mhz),         // input
    .rst_n_sync       (rst_n_100mhz_sync),  // input
    .data_in          (data_out),           // input  [7:0]
    .data_in_valid    (data_out_valid),     // input
    .data_in_finished (data_out_finished),  // input
    .slave_id,                              // input  [6:0]
    .rnw,                                   // input
    .read_data_out    (read_data_in),       // output [7:0] 
    .bram_read_data,                        // input  [7:0]
    .bram_write_data,                       // output [7:0]
    .bram_addr,                             // output [12:0]
    .bram_wen,                              // output
    .bram_ren                               // output
   );

  block_ram
  #( .RAM_WIDTH(8),
     .RAM_ADDR_BITS(13) )
  u_block_ram
  ( .clk          (clk_100mhz),      // input
    .write_enable (bram_wen),        // input 
    .address      (bram_addr),       // input  [RAM_ADDR_BITS-1:0]
    .write_data   (bram_write_data), // input  [RAM_WIDTH-1:0]
    .read_enable  (bram_ren),        // input
    .read_data    (bram_read_data)   // output [RAM_WIDTH-1:0]
   );

endmodule
