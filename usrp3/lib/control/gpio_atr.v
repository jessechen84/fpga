
//
// Copyright 2011 Ettus Research LLC
//



module gpio_atr
  #(parameter BASE = 0,
    parameter WIDTH = 32,
    parameter default_ddr = 0,
    parameter default_idle = 0)
   (input clk, input reset,
    input set_stb, input [7:0] set_addr, input [31:0] set_data,
    input rx, input tx,
    inout [WIDTH-1:0] gpio,
    output reg [31:0] gpio_readback
    );
   
   wire [WIDTH-1:0]   ddr, in_idle, in_tx, in_rx, in_fdx;
   reg [WIDTH-1:0]    rgpio, igpio;
   reg [WIDTH-1:0]    gpio_pipe;
   
   
   setting_reg #(.my_addr(BASE+0), .width(WIDTH), .at_reset(default_idle)) reg_idle
     (.clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr), .in(set_data),
      .out(in_idle),.changed());

   setting_reg #(.my_addr(BASE+1), .width(WIDTH)) reg_rx
     (.clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr), .in(set_data),
      .out(in_rx),.changed());

   setting_reg #(.my_addr(BASE+2), .width(WIDTH)) reg_tx
     (.clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr), .in(set_data),
      .out(in_tx),.changed());

   setting_reg #(.my_addr(BASE+3), .width(WIDTH)) reg_fdx
     (.clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr), .in(set_data),
      .out(in_fdx),.changed());

   setting_reg #(.my_addr(BASE+4), .width(WIDTH), .at_reset(default_ddr)) reg_ddr
     (.clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr), .in(set_data),
      .out(ddr),.changed());

   // Delay rx and tx signals by 2 cycles, giving them enough time to get to the IOBUFs
   //  and not cause timing or fanout problems (hopefully)
   reg [1:0] 	      rx_d, tx_d;
   always @(posedge clk) rx_d <= {rx_d[0],rx};
   always @(posedge clk) tx_d <= {tx_d[0],tx};
   
   always @(posedge clk)
     case({tx_d[1],rx_d[1]})
       2'b00: rgpio <= in_idle;
       2'b01: rgpio <= in_rx;
       2'b10: rgpio <= in_tx;
       2'b11: rgpio <= in_fdx;
     endcase // case ({tx,rx})
   
   integer 	      n;
   always @*
     for(n=0;n<WIDTH;n=n+1)
       igpio[n] <= ddr[n] ? rgpio[n] : 1'bz;

   assign     gpio = igpio;

   // Double pipeline stage for timing, first flop is in IOB, second in core logic.
   always @(posedge clk) begin
      gpio_pipe <= gpio;
      gpio_readback <= gpio_pipe;
   end
   
endmodule // gpio_atr
