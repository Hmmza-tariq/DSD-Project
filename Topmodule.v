`timescale 1ns / 1ps

module TM_UART(
    input wire clk, rst, rx_data,
    output reg [7:0] data,
    output wire tx_status, tx_data, rx_status,
    output wire [7:0] rx_output,
    output reg [7:0] rx_out,
	 input wire ready
);
    reg [7:0] matric_result[1:0][1:0];
    reg [7:0] matric1[1:0][1:0]; // 2x2 matrix
    reg [7:0] matric2[1:0][1:0]; // 2x2 result matrix

    wire bclk, bclk_x8;
    wire [9:0] temp_reg;
    wire flag, tx_flag;
    

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
    reg [2:0] index; // To track matrix elements being received
    reg [2:0] i; // To track result matrix element to send

    reg prev_flag, prev_tx_flag; // Rising edge detection for the flag

    always @(posedge clk or posedge rst) begin
        if (rst) prev_flag <= 0;
        else prev_flag <= flag;

        if (rst) prev_tx_flag <= 0;
        else prev_tx_flag <= tx_flag;
    end

    wire flag_rising = (flag && ~prev_flag);
    wire tx_flag_rising = (tx_flag && ~prev_tx_flag);

    // Main state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all variables
            state <= 2'd0;
            index <= 3'd0;
            i <= 3'd0;
            matric1[0][0] <= 8'd0; matric1[0][1] <= 8'd0;
            matric1[1][0] <= 8'd0; matric1[1][1] <= 8'd0;
            matric2[0][0] <= 8'd0; matric2[0][1] <= 8'd0;
            matric2[1][0] <= 8'd0; matric2[1][1] <= 8'd0;
            matric_result[0][0] <= 8'd0; matric_result[0][1] <= 8'd0;
            matric_result[1][0] <= 8'd0; matric_result[1][1] <= 8'd0;
            data <= 8'd0;
            rx_out <= 8'd0;
        end else begin
            case (state)
                2'd0: begin // Receiving matrix 1
                    if (flag_rising) begin
                        matric1[index / 2][index % 2] <= rx_output;
                        rx_out <= 8'd1;
                        if (index == 3) begin
                            index <= 3'd0;
                            state <= 2'd1;
                        end else begin
                            index <= index + 1;
                        end
                    end
                end
                2'd1: begin // Receiving matrix 2
                    if (flag_rising) begin
                        matric2[index / 2][index % 2] <= rx_output;
                        rx_out <= 8'd2;
                        if (index == 3) begin
                            index <= 3'd0;
                            state <= 2'd2;
                        end else begin
                            index <= index + 1;
                        end
                    end
                end
                2'd2: begin // Perform matrix addition
                    matric_result[0][0] <= matric1[0][0] * matric2[0][0] + matric1[0][1] * matric2[1][0];
                    matric_result[0][1] <= matric1[0][0] * matric2[0][1] + matric1[0][1] * matric2[1][1];
                    matric_result[1][0] <= matric1[1][0] * matric2[0][0] + matric1[1][1] * matric2[1][0];
                    matric_result[1][1] <= matric1[1][0] * matric2[0][1] + matric1[1][1] * matric2[1][1];
                    i <= 3'd0; // Initialize index for result matrix sending
                    state <= 2'd3; // Move to the result sending state
                end
                2'd3: begin
                    if (ready) begin
                        data <= matric_result[i / 2][i % 2]; // Send current result matrix element
                        if (tx_flag_rising) begin
                            rx_out <= 8'd5;
                            if (i == 3) begin
                                rx_out <= 8'd6;
                                i <= 3'd0;
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

