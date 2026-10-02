`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/10/2026 07:27:54 PM
// Design Name: 
// Module Name: oserdes_hdmi
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


module oserdes_hdmi (
    input  logic       pixel_clk,
    input  logic       serial_clk,
    input  logic       rst,

    input  logic [9:0] tmds_data,

    output logic       tmds_serial
);

    // ============================================================
    // MASTER / SLAVE interconnect
    // ============================================================

    logic slave_shiftout1;
    logic slave_shiftout2;

    logic master_oq;


    // ============================================================
    // 10-bit OSERDESE2 SLAVE
    //
    // Bits [9:8] are supplied through D3/D4.
    // ============================================================

    OSERDESE2 #(
        .DATA_RATE_OQ("DDR"),
        .DATA_RATE_TQ("DDR"),
        .DATA_WIDTH(10),
        .INIT_OQ(1'b0),
        .INIT_TQ(1'b0),
        .SERDES_MODE("SLAVE"),
        .SRVAL_OQ(1'b0),
        .SRVAL_TQ(1'b0),
        .TBYTE_CTL("FALSE"),
        .TBYTE_SRC("FALSE"),
        .TRISTATE_WIDTH(1)
    )
    oserdes_slave (
        .OFB(),
        .OQ(),

        .SHIFTOUT1(slave_shiftout1),
        .SHIFTOUT2(slave_shiftout2),

        .TBYTEOUT(),
        .TFB(),
        .TQ(),

        .CLK(serial_clk),
        .CLKDIV(pixel_clk),

        // D3/D4 contain bits 8/9 for 10-bit width expansion
        .D1(1'b0),
        .D2(1'b0),
        .D3(tmds_data[8]),
        .D4(tmds_data[9]),
        .D5(1'b0),
        .D6(1'b0),
        .D7(1'b0),
        .D8(1'b0),

        .OCE(1'b1),
        .RST(rst),

        .SHIFTIN1(1'b0),
        .SHIFTIN2(1'b0),

        .T1(1'b0),
        .T2(1'b0),
        .T3(1'b0),
        .T4(1'b0),

        .TBYTEIN(1'b0),
        .TCE(1'b0)
    );


    // ============================================================
    // 10-bit OSERDESE2 MASTER
    //
    // Bits [7:0] are supplied through D1-D8.
    // ============================================================

    OSERDESE2 #(
        .DATA_RATE_OQ("DDR"),
        .DATA_RATE_TQ("DDR"),
        .DATA_WIDTH(10),
        .INIT_OQ(1'b0),
        .INIT_TQ(1'b0),
        .SERDES_MODE("MASTER"),
        .SRVAL_OQ(1'b0),
        .SRVAL_TQ(1'b0),
        .TBYTE_CTL("FALSE"),
        .TBYTE_SRC("FALSE"),
        .TRISTATE_WIDTH(1)
    )
    oserdes_master (
        .OFB(),
        .OQ(master_oq),

        // Slave -> Master
        .SHIFTOUT1(),
        .SHIFTOUT2(),

        .TBYTEOUT(),
        .TFB(),
        .TQ(),

        .CLK(serial_clk),
        .CLKDIV(pixel_clk),

        .D1(tmds_data[0]),
        .D2(tmds_data[1]),
        .D3(tmds_data[2]),
        .D4(tmds_data[3]),
        .D5(tmds_data[4]),
        .D6(tmds_data[5]),
        .D7(tmds_data[6]),
        .D8(tmds_data[7]),

        .OCE(1'b1),
        .RST(rst),

        // Slave -> Master
        .SHIFTIN1(slave_shiftout1),
        .SHIFTIN2(slave_shiftout2),

        .T1(1'b0),
        .T2(1'b0),
        .T3(1'b0),
        .T4(1'b0),

        .TBYTEIN(1'b0),
        .TCE(1'b0)
    );


    // ============================================================
    // Serialized TMDS output
    // ============================================================

    assign tmds_serial = master_oq;

endmodule
