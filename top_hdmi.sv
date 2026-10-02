`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/10/2026 07:12:13 PM
// Design Name: 
// Module Name: top_hdmi
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


module top_hdmi (
    input  clk,
    input  rst,

    
    
    // HDMI TX differential outputs
    output logic [2:0] hdmi_tx_p,
    output logic [2:0] hdmi_tx_n,

    output logic hdmi_tx_clk_p,
    output logic hdmi_tx_clk_n
);


    // ============================================================
    // Clocks
    // ============================================================

    logic pixel_clk;
    logic serial_clk;

    //logic rst;
    //assign rst = !rst_n;

    // ============================================================
    // Video timing
    // ============================================================

    logic [11:0] pixel_x;
    logic [10:0] pixel_y;

    logic hsync;
    logic vsync;
    logic video_active;


    // ============================================================
    // RGB test pattern
    // ============================================================

    logic [7:0] red;
    logic [7:0] green;
    logic [7:0] blue;


    // ============================================================
    // Internal 10-bit TMDS data
    // ============================================================

    logic [9:0] tmds_red;
    logic [9:0] tmds_green;
    logic [9:0] tmds_blue;
    
    logic tmds_green_serial;
    logic tmds_blue_serial;
    logic tmds_red_serial;

    // ============================================================
    // Clock generation
    // ============================================================
    
   
    logic clk_locked;
    
    clk_wiz_0 u_clk_wiz (
        .pixel_clk  (pixel_clk),
        .serial_clk (serial_clk),
        .reset      (rst),
        .locked     (),
        .clk_in1    (clk)
    );

    // ============================================================
    // Video timing
    // ============================================================

    video_timing u_video_timing (
        .pixel_clk    (pixel_clk),
        .rst          (rst),

        .pixel_x      (pixel_x),
        .pixel_y      (pixel_y),

        .hsync        (hsync),
        .vsync        (vsync),
        .video_active (video_active)
    );


    // ============================================================
    // Test pattern
    // ============================================================

    test_pattern u_test_pattern (
        .pixel_x      (pixel_x),
        .pixel_y      (pixel_y),
        .video_active (video_active),

        .red          (red),
        .green        (green),
        .blue         (blue)
    );


    // ============================================================
    // TMDS Encoder
    // ============================================================

    tmds_encoder u_tmds_encoder (
        .pixel_clk    (pixel_clk),
        .rst          (rst),

        .red          (red),
        .green        (green),
        .blue         (blue),

        .video_active (video_active),
        .hsync        (hsync),
        .vsync        (vsync),

        .tmds_red     (tmds_red),
        .tmds_green   (tmds_green),
        .tmds_blue    (tmds_blue)
    );


    // ============================================================
    // RED OSERDES
    // ============================================================

    oserdes_hdmi u_oserdes_red (
        .pixel_clk   (pixel_clk),
        .serial_clk  (serial_clk),
        .rst         (rst),

        .tmds_data   (tmds_red),
        .tmds_serial (tmds_red_serial)
    );


    // ============================================================
    // GREEN OSERDES
    // ============================================================

    oserdes_hdmi u_oserdes_green (
        .pixel_clk   (pixel_clk),
        .serial_clk  (serial_clk),
        .rst         (rst),

        .tmds_data   (tmds_green),
        .tmds_serial (tmds_green_serial)
    );


    // ============================================================
    // BLUE OSERDES
    // ============================================================

    oserdes_hdmi u_oserdes_blue (
        .pixel_clk   (pixel_clk),
        .serial_clk  (serial_clk),
        .rst         (rst),

        .tmds_data   (tmds_blue),
        .tmds_serial (tmds_blue_serial)
    );

    OBUFDS #(
        .IOSTANDARD("TMDS_33")
    ) tmds_out_1 (
        .I(tmds_blue_serial),
        .O(hdmi_tx_p[0]),
        .OB(hdmi_tx_n[0])
    );
    
        OBUFDS #(
        .IOSTANDARD("TMDS_33")
    ) tmds_out_2 (
        .I(tmds_green_serial),
        .O(hdmi_tx_p[1]),
        .OB(hdmi_tx_n[1])
    );
        OBUFDS #(
        .IOSTANDARD("TMDS_33")
    ) tmds_out_3 (
        .I(tmds_red_serial),
        .O(hdmi_tx_p[2]),
        .OB(hdmi_tx_n[2])
    );
    
    OBUFDS #(
    .IOSTANDARD("TMDS_33")
) tmds_clk_out (
    .I(pixel_clk),
    .O(hdmi_tx_clk_p),
    .OB(hdmi_tx_clk_n)
);
endmodule