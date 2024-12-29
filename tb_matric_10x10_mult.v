module tb_MatrixMultiplication;
    reg clk;
    reg reset;
    reg start;
    reg [71:0] A_flat;
    reg [71:0] B_flat;
    wire [71:0] C_flat;
    wire done;
    
    // Instantiate the MatrixMultiplication module
    MatrixMultiplication uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .A_flat(A_flat),
        .B_flat(B_flat),
        .C_flat(C_flat),
        .done(done)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Monitor the results
    always @(done) begin
        if (done) begin
            $display("\nMatrix A:");
            $display("%d %d %d", A_flat[71:64], A_flat[63:56], A_flat[55:48]);
            $display("%d %d %d", A_flat[47:40], A_flat[39:32], A_flat[31:24]);
            $display("%d %d %d", A_flat[23:16], A_flat[15:8],  A_flat[7:0]);
            
            $display("\nMatrix B:");
            $display("%d %d %d", B_flat[71:64], B_flat[63:56], B_flat[55:48]);
            $display("%d %d %d", B_flat[47:40], B_flat[39:32], B_flat[31:24]);
            $display("%d %d %d", B_flat[23:16], B_flat[15:8],  B_flat[7:0]);
            
            $display("\nMatrix C_flat (Result):");
            $display("%d %d %d", C_flat[71:64], C_flat[63:56], C_flat[55:48]);
            $display("%d %d %d", C_flat[47:40], C_flat[39:32], C_flat[31:24]);
            $display("%d %d %d", C_flat[23:16], C_flat[15:8],  C_flat[7:0]);
        end
    end
    
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        start = 0;
        A_flat = 72'b0;
        B_flat = 72'b0;
        
        // Apply reset
        #10 reset = 0;
        
        // Load test matrices - Using 8-bit values
        // Matrix A = [9 8 7]
        //           [6 5 4]
        //           [3 2 1]
        A_flat = {8'd9, 8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1};
        
        // Matrix B = [1 2 3]
        //           [4 5 6]
        //           [7 8 9]
        B_flat = {8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8, 8'd9};
        
        // Start multiplication
        #10 start = 1;
        #10 start = 0;
        
        // Wait for done signal
        wait(done);
        
        // Add some delay before finishing
        #100 $finish;
    end
endmodule
