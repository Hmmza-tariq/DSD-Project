module matrix_multiply_3x3(
    input wire clk,
    input wire reset,
    input wire start,
    input wire [71:0] A,  // 9 elements, 8 bits each
    input wire [71:0] B,  // 9 elements, 8 bits each
    output reg [143:0] C, // 9 elements, 16 bits each for full precision
    output reg done
);

    // State definitions
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam FINISH = 2'b10;

    // Internal registers
    reg [1:0] state;
    reg [3:0] i, j, k;
    reg [15:0] temp_sum;

    // Wire arrays for easier matrix element access
    wire [7:0] A_matrix [0:8];
    wire [7:0] B_matrix [0:8];
    wire [15:0] current_product;

    // Unpack input matrices into 2D arrays
    generate
        genvar idx;
        for (idx = 0; idx < 9; idx = idx + 1) begin : unpack_matrices
            assign A_matrix[idx] = A[8*idx +: 8];
            assign B_matrix[idx] = B[8*idx +: 8];
        end
    endgenerate

    // Current product calculation
    assign current_product = A_matrix[i*3 + k] * B_matrix[k*3 + j];

    // Main state machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            done <= 0;
            i <= 0;
            j <= 0;
            k <= 0;
            temp_sum <= 0;
            C <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= COMPUTE;
                        i <= 0;
                        j <= 0;
                        k <= 0;
                        temp_sum <= 0;
                        done <= 0;
                    end
                end

                COMPUTE: begin
                    if (k == 0)
                        temp_sum <= current_product;
                    else
                        temp_sum <= temp_sum + current_product;

                    if (k == 2) begin
                        // Store final sum including the last product
                        C[16*(i*3 + j) +: 16] <= temp_sum + current_product;
                        
                        if (i == 2 && j == 2) begin
                            state <= FINISH;
                        end
                        else if (j == 2) begin
                            j <= 0;
                            i <= i + 1;
                        end
                        else begin
                            j <= j + 1;
                        end
                        k <= 0;
                        temp_sum <= 0;
                    end
                    else begin
                        k <= k + 1;
                    end
                end

                FINISH: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
