`timescale 1ns / 1ps
module matrix_mult_10(
    input wire [799:0] matrix1,  // 10x10 matrix, each element 8 bits
    input wire [799:0] matrix2,
    input wire clk,
    input wire reset,
    output reg done,
    output reg [799:0] result_array  // Each result element is now 8 bits, assuming max values are capped
);
    reg [31:0] result_matrix [9:0][9:0];  // Larger result matrix to hold intermediate products
    wire [31:0] mult_result [99:0];       // 100 multiplication results
    reg [4:0] state = 0;

    // Instantiate 100 vector_mult modules
    genvar i, j, k;
    generate
        for (i = 0; i < 10; i = i + 1) begin
            for (j = 0; j < 10; j = j + 1) begin
                vector_mult vm(
                    .vector1(matrix1[80*i+79:80*i]),
                    .vector2({matrix2[79-8*j], matrix2[159-8*j], matrix2[239-8*j], matrix2[319-8*j], matrix2[399-8*j],
                              matrix2[479-8*j], matrix2[559-8*j], matrix2[639-8*j], matrix2[719-8*j], matrix2[799-8*j]}),
                    .clk(clk),
                    .reset(reset),
                    .result(mult_result[10*i+j])
                );
            end
        end
    endgenerate

    // Handle the control flow for computing and resetting
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= 0;
            done <= 1'b0;
            // Reset result matrix
            integer x, y;
            for (x = 0; x < 10; x = x + 1) {
                for (y = 0; y < 10; y = y + 1) {
                    result_matrix[x][y] <= 32'd0;
                }
            }
        end else begin
            if (state < 100) begin
                // Assume each vector_mult returns a result in a single cycle for simplification
                result_matrix[state / 10][state % 10] <= mult_result[state];
                state <= state + 1;
            end else begin
                // All results ready, pack them into the output array
                integer p, q;
                for (p = 0; p < 10; p = p + 1) {
                    for (q = 0; q < 10; q = q + 1) {
                        result_array[8*(10*p+q)+7 : 8*(10*p+q)] <= result_matrix[p][q][7:0];  // Truncate to 8 bits
                    }
                }
                done <= 1'b1;
                state <= 0;
            }
        end
    end
endmodule
