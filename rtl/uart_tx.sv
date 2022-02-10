module uart_tx 
( input  logic       clk,
  input  logic       rst_n,  
  input  logic       send_trig,
  input  logic [7:0] send_data,
  output logic       tx,
  output logic       tx_bsy
);

    parameter SYSCLOCK  = 100000000; // <Hz>
    parameter BAUDRATE  = 12000000;
    parameter CLKPERFRM = 16'd84; // ceil(SYSCLOCK/BAUDRATE*10)
    // bit order is lsb-msb
    parameter TBITAT    = 16'd1;  // starT bit, round(SYSCLOCK/BAUDRATE*0)+1
    parameter BIT0AT    = 16'd9;  // round(SYSCLOCK/BAUDRATE*1)+1
    parameter BIT1AT    = 16'd18; // round(SYSCLOCK/BAUDRATE*2)+1
    parameter BIT2AT    = 16'd26; // round(SYSCLOCK/BAUDRATE*3)+1
    parameter BIT3AT    = 16'd34; // round(SYSCLOCK/BAUDRATE*4)+1
    parameter BIT4AT    = 16'd43; // round(SYSCLOCK/BAUDRATE*5)+1
    parameter BIT5AT    = 16'd51; // round(SYSCLOCK/BAUDRATE*6)+1
    parameter BIT6AT    = 16'd59; // round(SYSCLOCK/BAUDRATE*7)+1
    parameter BIT7AT    = 16'd68; // round(SYSCLOCK/BAUDRATE*8)+1
    parameter PBITAT    = 16'd76; // stoP bit, round(SYSCLOCK/BAUDRATE*9)+1
    
    logic [15:0] tx_cnt;    // tx flow control
    logic [7:0]  data2send; // buffer
    
    always@(posedge clk, negedge rst_n)
      if      (~rst_n)                          tx_bsy <= 1'b0;
      else if (send_trig & (~tx_bsy))           tx_bsy <= 1'b1;
      else if (tx_bsy && (tx_cnt == CLKPERFRM)) tx_bsy <= 1'b0;
 
    always@(posedge clk, negedge rst_n)
      if      (~rst_n)                        tx_cnt <= 16'd0;
      else if (tx_bsy && (tx_cnt==CLKPERFRM)) tx_cnt <= 16'd0;
      else if (tx_bsy)                        tx_cnt <= tx_cnt + 1'b1;
    
    always@(posedge clk, negedge rst_n)
      if      (~rst_n)                 data2send <= 8'd0;
      else if (send_trig && (~tx_bsy)) data2send <= send_data;
    
    always@(posedge clk or negedge rst_n)
        if      (~rst_n)              tx <= 1'b1; // init val should be 1
        else if (tx_bsy) case(tx_cnt)
                              TBITAT: tx <= 1'b0;
                              BIT0AT: tx <= data2send[0];
                              BIT1AT: tx <= data2send[1];
                              BIT2AT: tx <= data2send[2];
                              BIT3AT: tx <= data2send[3];
                              BIT4AT: tx <= data2send[4];
                              BIT5AT: tx <= data2send[5];
                              BIT6AT: tx <= data2send[6];
                              BIT7AT: tx <= data2send[7];
                              PBITAT: tx <= 1'b1;
                         endcase
        else                          tx <= 1'b1;

endmodule