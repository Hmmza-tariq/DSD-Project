`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:09:29 12/24/2024 
// Design Name: 
// Module Name:    transmitter 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module transmitter(input bclk, rst, ready,
                   input [7:0] data,
                   output reg tx_status, tx_data,tx_flag);
  
  parameter DATA_SIZE = 8; // by default making data 8 bits
  reg [3:0] bit_counter = 0; // counter to count which bit we are transmitting
  // states
  parameter START = 0, LOAD = 1,
  			TR_START = 2, TR_DATA = 3,
  			TR_END = 4;
  
  // state registers
  reg [2:0] state, next_state;
  
  // level edge detector
  //wire ready_pulse;
  level_det ld (.clk(bclk), .in(ready), .pulse(ready_pulse));
 
  always @ (posedge bclk or posedge rst) begin
    if (rst) state <= START;
    else state <= next_state;
  end
  
  always @ (posedge bclk or posedge rst) begin
    if (rst) bit_counter <= 0;
    else if (tx_status) bit_counter <= bit_counter + 4'b1;
    else bit_counter <= -1;
  end
  
  // next state logic
  always @ (*) begin
    next_state = state;
    case (state)
      START: if (ready_pulse) next_state = LOAD;
      LOAD: next_state = TR_START;
      TR_START: next_state = TR_DATA;
      // transmitting from LSB
      TR_DATA: if (bit_counter == DATA_SIZE - 1) next_state = TR_END; // as counting starts from 0, we count 0 to seven
      TR_END: if (!ready_pulse) next_state = START; 
      default: next_state = state;
    endcase
  end
  
  // data reg
  reg [7:0] data_reg;
  reg write_data;
  always @ (posedge bclk or posedge rst) begin
   if (rst) data_reg <= 0;
	else if (write_data) data_reg <= data;
	else data_reg <= data_reg;
  end
  // output
  always @ (*) begin
  write_data = 0;
    case(state)
      START: begin
		  tx_flag=0;
        tx_status = 0; // no transmission taking place here so tx_status 0
        tx_data = 1; // data line high when we are not sending data
      end
      LOAD: begin
        tx_status = 0;
        tx_data = 1;
		  write_data = 1;
      end
      TR_START: begin
        tx_status = 1;
        tx_data = 0; // sending the start bit
      end
      TR_DATA: begin
        tx_status = 1;
        tx_data = data_reg[bit_counter]; // sending the data bit by bit
      end
      TR_END: begin
		tx_flag=1;
        tx_status = 1;
        tx_data = 1; // sending stop bit
      end
      default: begin tx_status = 0; tx_data = 1; end //faizan and zak changed 'tx_data = 1' to 'tx_data = 0' but it apparently it didnt effect.
    endcase
  end
endmodule
