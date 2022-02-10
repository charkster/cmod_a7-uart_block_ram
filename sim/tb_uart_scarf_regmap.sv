
module tb_spi_slave_lbus ();

   parameter EXT_CLK_PERIOD_NS = 10;
   parameter UART_PERIOD_NS = 83;

   logic clk;
   logic button_0;
   logic uart_txd_in;

   integer error_count;

   initial begin
      clk = 1'b0;
      forever
        #(EXT_CLK_PERIOD_NS/2) clk = ~clk;
   end

   task send_byte (input [7:0] byte_val);
      begin
         $display("Called send_byte task: given byte_val is %h",byte_val);
         uart_txd_in  = 1'b0;
         #(UART_PERIOD_NS);
         for (int i=0; i <= 7; i=i+1) begin
            $display("Inside send_byte for loop, index is %d",i);
            uart_txd_in = byte_val[i];
            #(UART_PERIOD_NS);
         end
         uart_txd_in  = 1'b1;
         #(UART_PERIOD_NS);
      end
   endtask
   
   task check_byte (input [7:0] send_byte_val, input [7:0] check_byte_val);
      begin
         $display("Called send_byte_check_byte task: send_byte_val is %h, check_byte_val is %h",send_byte_val,check_byte_val);
         uart_txd_in  = 1'b0;
         #(UART_PERIOD_NS);
         for (int i=0; i <= 7; i=i+1) begin
           //$display("Inside send_byte for loop, index is %d",i);
           uart_txd_in = send_byte_val[i];
           #(UART_PERIOD_NS);
         end
         uart_txd_in  = 1'b1;
         #(UART_PERIOD_NS);
      end
   endtask

   initial begin
      error_count = 'd0;
      uart_txd_in  = 1'b1;
      button_0 = 1'b1;
      #UART_PERIOD_NS;
      button_0 = 1'b0;
      #(UART_PERIOD_NS*8);    
      $display("Write 1 bytes byte to regmap address 0x0034");
      #(UART_PERIOD_NS/2);
      send_byte(8'h01);       // slave id 0x01, rnw = 0
      send_byte(8'h00);       // address upper byte
      send_byte(8'h34);       // address lower byte
      send_byte(8'hA5);       // write data
      #(UART_PERIOD_NS * 16);    
      $display("Write 4 bytes byte to regmap address 0x01CE");
      #(UART_PERIOD_NS/2);
      send_byte(8'h01);       // slave id 0x01, rnw = 0
      send_byte(8'h01);       // address upper byte
      send_byte(8'hCE);       // address lower byte
      send_byte(8'h93);       // value at address 0x01CE
      send_byte(8'h5A);       // value at address 0x01CF
      send_byte(8'hA5);       // value at address 0x01D0
      send_byte(8'hF0);       // value at address 0x01D1
      #(UART_PERIOD_NS * 16);
      $display("Read 3 bytes byte to regmap address 0x01CE");
      #(UART_PERIOD_NS/2);
      send_byte(8'h81);        // slave id 0x01, rnw = 1
      send_byte(8'h01);        // address upper byte
      send_byte(8'hCE);        // address lower byte
      check_byte(8'h00,8'h93); // 1st byte comes out
      check_byte(8'h00,8'h5A); // 2nd byte
      check_byte(8'h00,8'hA5); // 3rd byte
      #(UART_PERIOD_NS * 16);
      $display("Read 1 bytes byte to regmap address 0x0A");
      #(UART_PERIOD_NS/2);
      send_byte(8'h81);        // slave id 0x01, rnw = 1
      send_byte(8'h00);        // address upper byte
      send_byte(8'h34);        // address lower byte
      check_byte(8'h00,8'h34); // 1st byte comes out
      #(UART_PERIOD_NS * 16);
      $display("Write a single byte to sram address 0x029FF");
      #(UART_PERIOD_NS/2);
      send_byte(8'h02);        // Salve id is 0x02, RNW = 0
      send_byte(8'h00);
      send_byte(8'h29);
      send_byte(8'hFF);
      send_byte(8'hE7);
      #(UART_PERIOD_NS * 16);
      $display("Write a 3 bytes to sram address 0x029FF");
      #(UART_PERIOD_NS/2);
      send_byte(8'h03);        // Slave id is 0x03, RNW = 0
      send_byte(8'h00);
      send_byte(8'h29);
      send_byte(8'hFF);
      send_byte(8'h34);
      send_byte(8'h42); 
      send_byte(8'hA1);
      #(UART_PERIOD_NS * 16);
      $display("Read a single byte from sram address 0x002A");
      #(UART_PERIOD_NS/2);
      send_byte(8'h81);        // Salve id is 0x01, RNW = 1
      send_byte(8'h00);        // address upper byte
      send_byte(8'h2A);        // address lower byte
      check_byte(8'h00,8'hA1); // 1st byte comes out
      #(UART_PERIOD_NS * 16);
      #10us;
      $finish;
   end

   // dump waveforms
   initial begin
      $shm_open("waves.shm");
      $shm_probe("MAS");
   end

uart_scarf_regmap_top u_uart_scarf_regmap_top
( .clk,             // input
  .button_0,        // input
  .uart_txd_in,     // input
  .uart_rxd_out ()  // output
  );

endmodule
