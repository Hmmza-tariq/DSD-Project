`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    02:44:49 12/29/2024 
// Design Name: 
// Module Name:    mult_10x10 
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
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    02:15:08 12/29/2024 
// Design Name: 
// Module Name:    matrix_10x10_mult 
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
module matrix_multiply_10x10_pipelined(
    input wire clk,
    input wire reset,
    input wire start,
    input wire [799:0] A,  // 100 elements, 8 bits each (10x10)
    input wire [799:0] B,  // 100 elements, 8 bits each (10x10)
    output reg [799:0] C, // 100 elements, 16 bits each (10x10)
    output reg done
);
    // States
    localparam IDLE = 2'b00;
    localparam MULTIPLY = 2'b01;
    localparam ACCUMULATE = 2'b10;
    
    reg [1:0] state;
    reg [4:0] i, j, k;  // Changed to 5 bits for counting up to 10
    reg [15:0] temp_sum;
    
    // Individual matrix elements
    wire [7:0] A_matrix [99:0];  // Changed to 100 elements
    wire [7:0] B_matrix [99:0];  // Changed to 100 elements
    
    // Multiply result register
    reg [8:0] mult_result;
    
    // Unpack matrices into individual elements
    generate
        genvar idx;
        for (idx = 0; idx < 100; idx = idx + 1) begin : matrix_unpack
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
                    mult_result <= A_matrix[i*10 + k] * B_matrix[k*10 + j];  // Changed to 10 for matrix width
                    state <= ACCUMULATE;
                end

                ACCUMULATE: begin
                    // Accumulate result
                    if (k == 0)
                        temp_sum <= mult_result;
                    else
                        temp_sum <= temp_sum + mult_result;
                        
                    // Check if dot product is complete
                    if (k == 9) begin  // Changed to 9 for 10x10 matrix
                        // Store result
                        C[8*(i*10 + j) +: 8] <= temp_sum + mult_result;  // Changed to 10 for matrix width
                        
                        // Update indices
                        if (i == 9 && j == 9) begin  // Changed to 9 for 10x10 matrix
                            state <= IDLE;
                            done <= 1;
                        end
                        else if (j == 9) begin  // Changed to 9 for matrix width
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
