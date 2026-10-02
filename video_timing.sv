`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/10/2026 03:33:12 PM
// Design Name: 
// Module Name: video_timing
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


module video_timing (
    input          pixel_clk,
    input          rst,

    output logic [11:0] pixel_x,
    output logic [10:0] pixel_y,

    output logic        hsync,
    output logic        vsync,
    output logic        video_active
);

logic [11:0] next_pixel_x;
logic [10:0] next_pixel_y;

always_ff @(posedge pixel_clk)begin 
    if(rst)begin 
        pixel_x <= 0;
        pixel_y <= 0;
    end else begin 
        pixel_x <= next_pixel_x;
        pixel_y <= next_pixel_y;

    end

end

always_comb begin 
   

    next_pixel_x = (pixel_x < 1649) ? pixel_x + 1 : 0;
    next_pixel_y = ((pixel_x == 1649) & (pixel_y < 749)) ? pixel_y + 1 : ((pixel_x == 1649) & (pixel_y == 749 )) ? 0 : pixel_y;

end

assign video_active = (pixel_x < 1280) && (pixel_y < 720);
assign hsync = (pixel_x >= 1390) && (pixel_x < 1430);
assign vsync = (pixel_y >= 725) && (pixel_y < 730);


endmodule
