`timescale 1ns / 1ps

module TM_UART(
    input wire clk, rst, rx_data,
    output reg [7:0] data,
    output wire tx_status, tx_data, rx_status,
    output wire [7:0] rx_output,
    output reg [7:0] rx_out,
	 input wire ready
);
    reg [7:0] matric_result[2:0][2:0];
    reg [7:0] matric1[2:0][2:0]; // 3x3 matrix
    reg [7:0] matric2[2:0][2:0]; // 3x3 result matrix

    wire bclk, bclk_x8;
    wire [9:0] temp_reg;
    wire flag, tx_flag;
    
	  // Flattened inputs for matrix multiplication
    wire [71:0] A, B;  // Flattened 3x3 matrices
    wire [143:0] C;    // Flattened result matrix

    wire done;

    baudrate #(.baud_sel(0)) br(
        .clk(clk), 
        .rst(rst), 
        .bclk(bclk), 
        .bclk_x8(bclk_x8)
    );

    transmitter tr(
        .bclk(bclk), 
        .rst(rst), 
        .ready(ready), 
        .data(data), 
        .tx_status(tx_status), 
        .tx_data(tx_data),
        .tx_flag(tx_flag)
    );

    receiver rc(
        .bclk_x8(bclk_x8), 
        .rst(rst), 
        .rx_data(rx_data), 
        .rx_status(rx_status), 
        .rx_output(temp_reg), 
        .flag(flag)
    );

    assign rx_output = temp_reg[8:1];

    reg [1:0] state = 2'd0;
    reg [3:0] index; // To track matrix elements being received
    reg [3:0] i; // To track result matrix element to send

    reg prev_flag, prev_tx_flag; // Rising edge detection for the flag

    always @(posedge clk or posedge rst) begin
        if (rst) prev_flag <= 0;
        else prev_flag <= flag;

        if (rst) prev_tx_flag <= 0;
        else prev_tx_flag <= tx_flag;
    end

    wire flag_rising = (flag && ~prev_flag);
    wire tx_flag_rising = (tx_flag && ~prev_tx_flag);
 // Flatten matric1 and matric2 into A and B
    assign A = {matric1[2][2], matric1[2][1], matric1[2][0], matric1[1][2], matric1[1][1], matric1[1][0], matric1[0][2], matric1[0][1], matric1[0][0]};
    assign B = {matric2[2][2], matric2[2][1], matric2[2][0], matric2[1][2], matric2[1][1], matric2[1][0], matric2[0][2], matric2[0][1], matric2[0][0]};

    matrix_multiply_3x3 serial_multiplier(
        .clk(clk),
        .reset(rst),
        .start(state == 2'd2),  // Start when in multiplication state
        .A(A),
        .B(B),
        .C(C),
        .done(done)
    );
    // Main state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all variables
            state <= 2'd0;
            index <= 4'd0;
            i <= 4'd0;
            matric1[0][0] <= 8'd0; matric1[0][1] <= 8'd0; matric1[0][2] <= 8'd0;
            matric1[1][0] <= 8'd0; matric1[1][1] <= 8'd0; matric1[1][2] <= 8'd0;
            matric1[2][0] <= 8'd0; matric1[2][1] <= 8'd0; matric1[2][2] <= 8'd0;

            matric2[0][0] <= 8'd0; matric2[0][1] <= 8'd0; matric2[0][2] <= 8'd0;
            matric2[1][0] <= 8'd0; matric2[1][1] <= 8'd0; matric2[1][2] <= 8'd0;
            matric2[2][0] <= 8'd0; matric2[2][1] <= 8'd0; matric2[2][2] <= 8'd0;

            matric_result[0][0] <= 8'd0; matric_result[0][1] <= 8'd0; matric_result[0][2] <= 8'd0;
            matric_result[1][0] <= 8'd0; matric_result[1][1] <= 8'd0; matric_result[1][2] <= 8'd0;
            matric_result[2][0] <= 8'd0; matric_result[2][1] <= 8'd0; matric_result[2][2] <= 8'd0;

            data <= 8'd0;
            rx_out <= 8'd0;
        end else begin
            case (state)
                2'd0: begin // Receiving matrix 1
                    if (flag_rising) begin
                        matric1[index / 3][index % 3] <= rx_output;
                        rx_out <= 8'd1;
                        if (index == 8) begin
                            index <= 4'd0;
                            state <= 2'd1;
                        end else begin
                            index <= index + 1;
                        end
                    end
                end
                2'd1: begin // Receiving matrix 2
                    if (flag_rising) begin
                        matric2[index / 3][index % 3] <= rx_output;
                        rx_out <= 8'd2;
                        if (index == 8) begin
                            index <= 4'd0;
                            state <= 2'd2;
                        end else begin
                            index <= index + 1;
                        end
                    end
                end
                2'd2: begin // Perform matrix addition
                    if (done) begin
                        // Store the result from C back into matric_result
                        matric_result[0][0] <= C[135:128];
                        matric_result[0][1] <= C[119:112];
                        matric_result[0][2] <= C[103:96];
                        matric_result[1][0] <= C[87:80];
                        matric_result[1][1] <= C[71:64];
                        matric_result[1][2] <= C[55:48];
                        matric_result[2][0] <= C[39:32];
                        matric_result[2][1] <= C[23:16];
                        matric_result[2][2] <= C[7:0];
                        state <= 2'd3; // Move to result sending state
                    end
                end
                2'd3: begin
                    if (ready) begin
                        data <= matric_result[i/3][i%3]; // Send current result matrix element
                        if (tx_flag_rising) begin
                            rx_out <= 8'd5;
                            if (i == 8) begin
                                rx_out <= 8'd6;
                                i <= 4'd0;
                                state <= 2'd0; // Reset to initial state after sending all elements
                            end else begin
                                i <= i + 1;
                            end
                        end
                    end
                end
                default: state <= 2'd0;
            endcase
        end
    end
endmodule

