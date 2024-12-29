`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    01:22:51 12/29/2024 
// Design Name: 
// Module Name:    matrix_multiply_3x3 
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
module matrix_multiply_3x3_pipelined(
    input wire clk,
    input wire reset,
    input wire start,
    input wire [71:0] A,  // 9 elements, 8 bits each
    input wire [71:0] B,  // 9 elements, 8 bits each
    output reg [143:0] C, // 9 elements, 16 bits each
    output reg done
);

    // States
    localparam IDLE = 2'b00;
    localparam MULTIPLY = 2'b01;
    localparam ACCUMULATE = 2'b10;
    
    reg [1:0] state;
    reg [3:0] i, j, k;
    reg [15:0] temp_sum;
    
    // Individual matrix elements
    wire [7:0] A_matrix [8:0];
    wire [7:0] B_matrix [8:0];
    
    // Multiply result register
    reg [15:0] mult_result;
    
    // Unpack matrices into individual elements
    generate
        genvar idx;
        for (idx = 0; idx < 9; idx = idx + 1) begin : matrix_unpack
            assign A_matrix[idx] = A[8*idx +: 8];
            assign B_matrix[idx] = B[8*idx +: 8];
        end
    endgenerate

    // Main control and calculation logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            i <= 0;
            j <= 0;
            k <= 0;
            temp_sum <= 0;
            done <= 0;
            C <= 0;
            mult_result <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= MULTIPLY;
                        i <= 0;
                        j <= 0;
                        k <= 0;
                        temp_sum <= 0;
                        done <= 0;
                    end
                end

                MULTIPLY: begin
                    // Calculate current multiplication
                    mult_result <= A_matrix[i*3 + k] * B_matrix[k*3 + j];
                    state <= ACCUMULATE;
                end

                ACCUMULATE: begin
                    // Accumulate result
                    if (k == 0)
                        temp_sum <= mult_result;
                    else
                        temp_sum <= temp_sum + mult_result;
                        
                    // Check if dot product is complete
                    if (k == 2) begin
                        // Store result
                        C[16*(i*3 + j) +: 16] <= temp_sum + mult_result;
                        
                        // Update indices
                        if (i == 2 && j == 2) begin
                            state <= IDLE;
                            done <= 1;
                        end
                        else if (j == 2) begin
                            j <= 0;
                            i <= i + 1;
                            k <= 0;
                            state <= MULTIPLY;
                        end
                        else begin
                            j <= j + 1;
                            k <= 0;
                            state <= MULTIPLY;
                        end
                    end
                    else begin
                        k <= k + 1;
                        state <= MULTIPLY;
                    end
                end
            endcase
        end
    end

endmodule
