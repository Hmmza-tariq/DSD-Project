`timescale 1ns / 1ps
module vector_mult (
    input wire [79:0] vector1,   // Each element now occupies 8 bits, 10 elements total
    input wire [79:0] vector2,
    input wire clk,
    input wire reset,
    output reg [31:0] result     // Larger result width to avoid overflow
);
    reg [7:0] vec1 [9:0];        // 10 elements array
    reg [7:0] vec2 [9:0];
    reg [15:0] product [9:0];    // Products of each element pair
    reg [31:0] sum_reg;          // Larger accumulator for the sum of products
    reg [3:0] state;
    reg input_loaded;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            integer i;
            for (i = 0; i < 10; i = i + 1) begin
                vec1[i] <= 8'd0;
                vec2[i] <= 8'd0;
                product[i] <= 16'd0;
            end
            sum_reg <= 32'd0;
            state <= 4'd0;
            result <= 32'd0;
            input_loaded <= 1'b0;
        end else begin
            if (!input_loaded) begin
                integer j;
                for (j = 0; j < 10; j = j + 1) begin
                    vec1[j] <= vector1[8*j+7 : 8*j];
                    vec2[j] <= vector2[8*j+7 : 8*j];
                }
                input_loaded <= 1'b1;
                sum_reg <= 32'd0;
            end else begin
                if (state < 10) begin
                    product[state] <= vec1[state] * vec2[state];
                    sum_reg <= (state == 0) ? product[state] : sum_reg + product[state];
                    state <= state + 1;
                end else begin
                    result <= sum_reg;
                    state <= 0;
                    input_loaded <= 1'b0;
                end
            end
        end
    end
endmodule
