`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:30:47 12/24/2024 
// Design Name: 
// Module Name:    let 
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
module level_det(input clk, input in, output reg pulse);
    reg last_state;

    always @(posedge clk) begin
        pulse <= in & ~last_state;
        last_state <= in;
    end
endmodule
