
`timescale 1ns / 1ps

module receiver(input bclk_x8, rst, rx_data,
                output reg rx_status,
                output reg [9:0] rx_output,output reg flag);
  parameter DATA_SIZE = 8;
  // states
  parameter START = 0, SAMPLE = 1,
  			STORE = 2, END = 3;
  
  reg [2:0] state, next_state;
  always @ (posedge bclk_x8 or posedge rst) begin
    if (rst) state <= START;
    else state <= next_state;
  end

  reg [3:0] bit_counter = 0; // counting the bits we get initially
  reg inc_bit_counter = 0; // for incrementing bit counter
  reg clear_buffer = 0;
  always @ (posedge bclk_x8 or posedge clear_buffer) begin
    if (clear_buffer) bit_counter <= 4'd0;
    else if (inc_bit_counter) bit_counter <= bit_counter + 4'd1;
    else bit_counter <= bit_counter;
  end
  
  // sample counter logic
  reg [3:0] sample_counter = 0;
  reg rst_sample_counter;
  always @ (posedge bclk_x8 or posedge rst_sample_counter) begin
    if (rst_sample_counter) sample_counter <= 4'd0;
    else sample_counter <= sample_counter + 4'd1;
  end
  
  // next state logic
  always @ (*) begin
    next_state = state;
    case (state)
      START: begin if (rx_data == 0) next_state = SAMPLE; else next_state = START; end
      // we want to sample till the second last value, so we can store the next value in rx_register
      SAMPLE: begin if (sample_counter == DATA_SIZE - 2) next_state = STORE; else next_state = SAMPLE; end
      // store needs 8 bits as input as we are also taking stop bit as input
      STORE: begin if(bit_counter == 10) next_state = END; else next_state = SAMPLE; end
      END: next_state = START;
      default: next_state = state;
    endcase
  end
  
  // updating the rx_output
  reg write_reg = 0;
  always @ (posedge bclk_x8 or posedge rst) begin
		if (rst) rx_output <= 10'd0;
		else if (write_reg) rx_output[bit_counter] <= snap_shot[3];
		else rx_output <= rx_output;
  end
  
  reg [7:0] snap_shot = 0;
  // state outputs
  always @ (*) begin
    rst_sample_counter = 0;
    inc_bit_counter = 0;
    clear_buffer = 0;
	 write_reg = 0;
	 snap_shot = snap_shot;
    case(state)
      START: begin
		  flag <= 0;
        rx_status = 0;
        rst_sample_counter = 1;
        clear_buffer = 1;
      end
      
      SAMPLE: begin
        rx_status = 1;
        snap_shot[sample_counter] = rx_data;
      end
      
      STORE: begin
        //rx_output[bit_counter] = snap_shot[3];
		  write_reg = 1;
        rx_status = 1;
        inc_bit_counter = 1;
        rst_sample_counter = 1;
      end
      
      END: begin
        rx_status = 0;
		  flag <= 1;
      end
      
      default: rx_status = 0;
    endcase
  end
endmodule
