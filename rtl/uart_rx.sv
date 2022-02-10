module uart_rx 
( input  logic       clk,
  input  logic       rst_n,
  input  logic       rx,
  output logic       inactive,
  output logic       data_valid,
  output logic [7:0] data_out
);
    parameter   SYSCLOCK  = 100000000;  // <Hz>
    parameter   BAUDRATE  = 12000000;
    parameter   NEDORD    = 6;          // Nedge Detector order
    parameter   NEDPAT    = 7'b1110000; // Nedge Detector pattern
    parameter   NEDDLY    = 3;          // Nedge Detector delay
    parameter   CLKPERFRM = 8'd79;     // floor(SYSCLOCK/BAUDRATE*10)-NEDDLY-1
    // bit order is lsb-msb
    parameter   TBITAT    = 8'd1;      // starT bit, round(SYSCLOCK/BAUDRATE*.5)-NEDDLY
    parameter   BIT0AT    = 8'd10;     // round(SYSCLOCK/BAUDRATE*1.5)-NEDDLY
    parameter   BIT1AT    = 8'd18;     // round(SYSCLOCK/BAUDRATE*2.5)-NEDDLY
    parameter   BIT2AT    = 8'd26;     // round(SYSCLOCK/BAUDRATE*3.5)-NEDDLY
    parameter   BIT3AT    = 8'd35;     // round(SYSCLOCK/BAUDRATE*4.5)-NEDDLY
    parameter   BIT4AT    = 8'd43;     // round(SYSCLOCK/BAUDRATE*5.5)-NEDDLY
    parameter   BIT5AT    = 8'd51;     // round(SYSCLOCK/BAUDRATE*6.5)-NEDDLY
    parameter   BIT6AT    = 8'd60;     // round(SYSCLOCK/BAUDRATE*7.5)-NEDDLY
    parameter   BIT7AT    = 8'd68;     // round(SYSCLOCK/BAUDRATE*8.5)-NEDDLY
    parameter   PBITAT    = 8'd76;     // stoP bit, round(SYSCLOCK/BAUDRATE*9.5)-NEDDLY

    logic [NEDORD:1] prev_rx;    // reception start detect
    logic            rx_nedge;   // reception starts at nedge of rx
    logic [7:0]      rx_cnt;     // rx flow control
    logic            rx_bsy;     // rx flow control
    logic            timeout;    // 
    
    always@(posedge clk, negedge rst_n)
      if (~rst_n)                      rx_nedge <= 1'b0;
      else if ({prev_rx,rx} == NEDPAT) rx_nedge <= 1'b1;
      else                             rx_nedge <= 1'b0;
        
    always@(posedge clk, negedge rst_n)
      if (~rst_n) prev_rx <= {NEDORD{1'b1}};          // init val should be all 1s
      else        prev_rx <= {prev_rx[NEDORD-1:1],rx};

    always@(posedge clk, negedge rst_n)
      if (~rst_n)                                            rx_bsy <= 1'b0;
      else if (rx_nedge && (~rx_bsy))                        rx_bsy <= 1'b1;
      else if (rx_bsy && (rx_cnt == TBITAT) && (rx == 1'b1)) rx_bsy <= 1'b0; // start bit should be low
      else if (rx_bsy && (rx_cnt == PBITAT))                 rx_bsy <= 1'b0;
    
    always@(posedge clk, negedge rst_n)
      if (~rst_n)                               timeout <= 1'b0;               
      else if (rx_bsy && (rx_cnt == PBITAT))    timeout <= 1'b1;
      else if (rx_bsy)                          timeout <= 1'b0;
      else if ((~rx_bsy) && (rx_cnt == BIT7AT)) timeout <= 1'b0; // inactivity needs to be less than one full frame
    
    always@(posedge clk, negedge rst_n)
      if (~rst_n)                 inactive <= 1'b1;
      else if (rx_bsy || timeout) inactive <= 1'b0;
      else                        inactive <= 1'b1;
      
    always@(posedge clk, negedge rst_n)
      if (~rst_n)                            rx_cnt <= 'd0;
      else if (rx_nedge && (~rx_bsy))        rx_cnt <= 'd0;           // start bit 
      else if (rx_bsy && (rx_cnt == PBITAT)) rx_cnt <= 'd0;           // get ready for inactive count
      else if (rx_bsy)                       rx_cnt <= rx_cnt + 1'b1; 
      else if (timeout)                      rx_cnt <= rx_cnt + 1'b1;
      else                                   rx_cnt <= 'd0;
        
    always@(posedge clk, negedge rst_n)
      if (~rst_n)                            data_valid <= 1'b0;
      else if (rx_bsy && (rx_cnt == PBITAT)) data_valid <= 1'b1;
      else                                   data_valid <= 1'b0;

    // rx data control
    always@(posedge clk, negedge rst_n)
      if (~rst_n)                   data_out[7:0] <= 8'd0;
      else if (rx_bsy) case(rx_cnt)
                            BIT0AT: data_out[0] <= rx;
                            BIT1AT: data_out[1] <= rx;
                            BIT2AT: data_out[2] <= rx;
                            BIT3AT: data_out[3] <= rx;
                            BIT4AT: data_out[4] <= rx;
                            BIT5AT: data_out[5] <= rx;
                            BIT6AT: data_out[6] <= rx;
                            BIT7AT: data_out[7] <= rx;
                       endcase

endmodule