`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/10/2026 03:33:34 PM
// Design Name: 
// Module Name: test_pattern
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module test_pattern (
    input  logic        [11:0] pixel_x,
    input  logic        [10:0] pixel_y,
    input  logic               video_active,

    output logic [7:0]         red,
    output logic [7:0]         green,
    output logic [7:0]         blue
);



always_comb begin

    red   = 8'h00;
    green = 8'h00;
    blue  = 8'h00;

    if (video_active) begin

        // Animated-looking repeating gradient pattern
        red   = pixel_x[7:0];
        green = pixel_y[7:0];
        blue  = pixel_x[7:0] ^ pixel_y[7:0];

        // Checkerboard overlay
        if (pixel_x[6] ^ pixel_y[6]) begin
            red   = ~pixel_x[7:0];
            green = pixel_y[7:0];
            blue  = 8'hFF;
        end

        // Center white box
        if ((pixel_x >= 540) && (pixel_x < 740) &&
            (pixel_y >= 260) && (pixel_y < 460)) begin

            red   = 8'hFF;
            green = 8'hFF;
            blue  = 8'hFF;

        end

        // Small black box inside
        if ((pixel_x >= 590) && (pixel_x < 690) &&
            (pixel_y >= 310) && (pixel_y < 410)) begin

            red   = 8'h00;
            green = 8'h00;
            blue  = 8'h00;

        end

    end
end

endmodule
