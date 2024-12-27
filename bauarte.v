`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:10:14 12/24/2024 
// Design Name: 
// Module Name:    bauarte 
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
module baudrate(input clk, rst,
                output reg bclk,
                output reg bclk_x8);
  
  // states
  parameter IDLE = 0, TEST = 5,	// does nothing in this state
            S0 = 1, S1 = 2, // S1: 9600, S2: 19200
            S2 = 3, S3 = 4; // S3: 57600, S4: 115200
  
  parameter baud_sel = 0;

  reg [13:0] baud_rate, br_counter; // for transmitter
  reg [10:0] baud_rate_x8, br_x8_counter; // for reciever
  
  // state registers
  reg [2:0] state, next_state;
  always @ (posedge clk or posedge rst) begin
    if (rst) state <= 0;
    else state <= next_state;
  end
  
  // Counter logic
  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      br_counter <= 0;
      br_x8_counter <= 0;
    end
    else begin
      br_counter <= (br_counter < baud_rate - 1) ? br_counter + 14'd1 : 14'd0;
      br_x8_counter <= (br_x8_counter < baud_rate_x8 - 1) ? br_x8_counter + 11'd1 : 11'd0;
      bclk <= (br_counter < baud_rate/2 - 1) ? 1'b0 : 1'b1;
      bclk_x8 <= (br_x8_counter < baud_rate_x8/2 - 1) ? 1'b0 : 1'b1;
    end
  end
  
  // next state logic
  always @ (*) begin
    next_state = state;
    case (baud_sel)
      3'd0: next_state = S0;
      3'd1: next_state = S1;
      3'd2: next_state = S2;
      3'd3: next_state = S3;
      default: next_state = state;
    endcase
  end
  
  // output logic, computing baudrate in terms of clock cycles when using 100MHz clk
  always @ (*) begin
    case(next_state)
      S0: begin baud_rate = 14'd10417; baud_rate_x8 = 11'd1302; end // 9600
      S1: begin baud_rate = 14'd5208; baud_rate_x8 = 11'd651; end // 19200
      S2: begin baud_rate = 14'd1736; baud_rate_x8 = 11'd217; end // 57600
      S3: begin baud_rate = 14'd868; baud_rate_x8 = 11'd109; end // 115200
      // For testing if Data bits are being sent, we set the bclk to 1 Hz
      default: begin baud_rate = 17'd10417; baud_rate_x8 = 11'd1302; end // 9600
    endcase
  end
endmodule