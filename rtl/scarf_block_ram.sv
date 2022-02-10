
module scarf_bram
  ( input  logic        clk,
    input  logic        rst_n_sync,
    input  logic  [7:0] data_in,
    input  logic        data_in_valid,
    input  logic        data_in_finished,
    input  logic  [6:0] slave_id,
    input  logic        rnw,
    output logic  [7:0] read_data_out, 
    input  logic  [7:0] bram_read_data,
    output logic  [7:0] bram_write_data,
    output logic [12:0] bram_addr,
    output logic        bram_wen,
    output logic        bram_ren
    );
    
    parameter SLAVE_ID    = 7'h02;
    parameter MAX_ADDRESS = 13'h1FFF;
    
    logic  [1:0] byte_count;
    logic        valid_slave;
    
    assign valid_slave = (slave_id == SLAVE_ID);
    
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)                                           byte_count <= 'd0;
      else if (data_in_finished)                                 byte_count <= 'd0;
      else if (valid_slave && data_in_valid && (byte_count < 3)) byte_count <= byte_count + 1'd1;
   
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)                                                                                      bram_addr       <= 'd0;
      else if (valid_slave && data_in_valid && (byte_count == 'd0))                                         bram_addr[12:8] <= data_in;
      else if (valid_slave && data_in_valid && (byte_count == 'd1))                                         bram_addr[7:0]  <= data_in;
      else if (valid_slave && data_in_valid && (byte_count >= 'd2) && (bram_addr != MAX_ADDRESS) &&   rnw)  bram_addr       <= bram_addr + 1'b1;
      else if (valid_slave && data_in_valid && (byte_count == 'd3) && (bram_addr != MAX_ADDRESS) && (!rnw)) bram_addr       <= bram_addr + 1'b1;
      else if (byte_count == 'd0)                                                                           bram_addr       <= 'd0;
    
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)                                         bram_write_data <= 8'd0;
      else if (data_in_valid && (byte_count >= 'd2) && (!rnw)) bram_write_data <= data_in;
    
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)                                         bram_wen <= 1'b0;
      else if (data_in_valid && (byte_count >= 'd2) && (!rnw)) bram_wen <= 1'b1;
      else                                                     bram_wen <= 1'b0;
      
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)                                      bram_ren <= 1'b0;
      else if (data_in_valid && (byte_count == 'd1) && rnw) bram_ren <= 1'b1;
      else if (byte_count == 'd0)                           bram_ren <= 1'b0;
      
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)                             read_data_out <= 8'd0;
      else if (!valid_slave)                       read_data_out <= 8'd0;
      else if (valid_slave && (byte_count == 'd0)) read_data_out <= {1'b0,SLAVE_ID};
      else if (bram_ren)                           read_data_out <= bram_read_data;
    
endmodule
    
