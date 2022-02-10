
module uart_scarf
  ( input  logic       rx,                  // UART
    output logic       tx,                  // UART
    input  logic       clk,                 // fpga clock
    input  logic       rst_n,               // async reset
    input  logic [7:0] read_data_in,        // read data fpga clk domain
    output logic       rst_n_sync,          // active low reset synchronized to fpga clk
    output logic [7:0] data_out,            // byte data,          fpga clk domain
    output logic       data_out_valid,      // byte data is valid, fpga clk domain
    output logic       data_out_finished,   // indicates bus cycle has finished
    output logic [6:0] slave_id,            // slave select        fpga clk domain
    output logic       rnw                  // read not-write      fpga clk domain
    );
    
    logic inactive;
    logic hold_inactive;
    logic data_valid;
    logic first_data_byte;
    logic send_trig;
    logic tx_bsy;
    
    synchronizer u_synchronizer_rst_n_sync
    ( .clk      (clk),
      .rst_n    (rst_n),
      .data_in  (1'b1),
      .data_out (rst_n_sync)
     );
       
    uart_rx u_uart_rx
    ( .clk,                      // input
      .rst_n      (rst_n_sync),  // input
      .rx,                       // input
      .inactive,                 // output
      .data_valid,               // output
      .data_out                  // output [7:0]
     );
     
    uart_tx u_uart_tx
    ( .clk,                      // input
      .rst_n,                    // input
      .send_trig,                // input
      .send_data (read_data_in), // input [7:0]
      .tx,                       // output
      .tx_bsy                    // output
     );
   
   always_ff @(posedge clk, negedge rst_n_sync)
     if (~rst_n_sync) hold_inactive <= 1'b1;
     else             hold_inactive <= inactive;
   
   always_ff @(posedge clk, negedge rst_n_sync)
     if (~rst_n_sync)                        first_data_byte <= 1'b0;
     else if (hold_inactive && (~inactive))  first_data_byte <= 1'b1;
     else if (first_data_byte && data_valid) first_data_byte <= 1'b0;
     
   always_ff @(posedge clk, negedge rst_n_sync)
     if (~rst_n_sync)                        slave_id <= 7'd0;
     else if (first_data_byte && data_valid) slave_id <= data_out[6:0]; //lower 7 bits
     
   always_ff @(posedge clk, negedge rst_n_sync)
     if (~rst_n_sync)                        rnw <= 1'b0;
     else if (first_data_byte && data_valid) rnw <= data_out[7]; // MSB
  
  always_ff @(posedge clk, negedge rst_n_sync)
     if (~rst_n_sync)                           data_out_finished <= 1'b1;
     else if (first_data_byte && data_valid)    data_out_finished <= 1'b0;
     else if ((~data_out_finished) && inactive) data_out_finished <= 1'b1;
  
  assign data_out_valid = (!first_data_byte) && data_valid;
  
  always_ff @(posedge clk, negedge rst_n_sync)
     if (~rst_n_sync)                 send_trig <= 1'b0;
     else if (data_out_valid && rnw)  send_trig <= 1'b1;
     else if (send_trig && (~tx_bsy)) send_trig <= 1'b0;

endmodule