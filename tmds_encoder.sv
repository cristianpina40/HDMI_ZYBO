`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/10/2026 03:34:12 PM
// Design Name: 
// Module Name: tmds_encoder
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


module tmds_encoder (
    input  logic        pixel_clk,
    input  logic        rst,

    input  logic [7:0]  red,
    input  logic [7:0]  green,
    input  logic [7:0]  blue,

    input  logic        video_active,
    input  logic        hsync,
    input  logic        vsync,

    output logic [9:0]  tmds_red,
    output logic [9:0]  tmds_green,
    output logic [9:0]  tmds_blue

);

logic [9:0]  next_tmds_red;
logic [9:0]  next_tmds_green;
logic [9:0]  next_tmds_blue;

logic xor_xnor_r;
logic xor_xnor_g;
logic xor_xnor_b;

logic [$clog2(8) : 0] count_ones_red;
logic [$clog2(8) : 0] count_ones_green;
logic [$clog2(8) : 0] count_ones_blue;

logic [$clog2(8) : 0] count_ones_disparity_red;
logic [$clog2(8) : 0] count_ones_disparity_green;
logic [$clog2(8) : 0] count_ones_disparity_blue;

logic [$clog2(8) : 0] count_zeros_disparity_red;
logic [$clog2(8) : 0] count_zeros_disparity_green;
logic [$clog2(8) : 0] count_zeros_disparity_blue;

logic [8:0] q_m_red;
logic [8:0] q_m_green;
logic [8:0] q_m_blue;

logic [8:0] next_q_m_red;
logic [8:0] next_q_m_green;
logic [8:0] next_q_m_blue;

logic signed [4:0] disparity_red;
logic signed [4:0] disparity_green;
logic signed [4:0] disparity_blue;

logic signed [4:0] next_disparity_red;
logic signed [4:0] next_disparity_green;
logic signed [4:0] next_disparity_blue;

integer i;
logic pipe_video_active;
logic pipe_vsync;
logic pipe_hsync;

always_ff @(posedge pixel_clk) begin
    if (rst) begin
        q_m_red   <= 0;
        q_m_green <= 0;
        q_m_blue  <= 0;

        tmds_red   <= 0;
        tmds_green <= 0;
        tmds_blue  <= 0;

        disparity_red   <= 0;
        disparity_green <= 0;
        disparity_blue  <= 0;

        pipe_video_active <= 0;
        pipe_hsync        <= 0;
        pipe_vsync        <= 0;
    end
    else begin
        q_m_red   <= next_q_m_red;
        q_m_green <= next_q_m_green;
        q_m_blue  <= next_q_m_blue;

        tmds_red   <= next_tmds_red;
        tmds_green <= next_tmds_green;
        tmds_blue  <= next_tmds_blue;

        disparity_red   <= next_disparity_red;
        disparity_green <= next_disparity_green;
        disparity_blue  <= next_disparity_blue;

        pipe_video_active <= video_active;
        pipe_hsync        <= hsync;
        pipe_vsync        <= vsync;
    end
end

//Combinational block for red
always_comb begin 

    next_q_m_red   = q_m_red;
    

    next_tmds_red   = tmds_red;
    
    next_disparity_red = disparity_red;

    

        if(video_active) begin
            /***STAGE 1*********************************************************************///
            count_ones_red = $countones(red);

            xor_xnor_r = (count_ones_red > 4) || ((count_ones_red == 4) && (red[0] == 0));

            next_q_m_red[0] = red[0];
            next_q_m_red[8] = ~xor_xnor_r;

            
            if(xor_xnor_r)begin 
                for(i = 1; i < 8; i++)begin
                    next_q_m_red[i] = ~(red[i] ^ next_q_m_red[i - 1]);
                end
            end
            else begin 
                for(i = 1; i < 8; i++)begin
                    next_q_m_red[i] = (red[i] ^ next_q_m_red[i - 1]);
                end
            end
        end

        if(pipe_video_active)begin
        /***STAGE 2: Disparity *********************************************************************///

            count_ones_disparity_red = $countones(q_m_red[7:0]);
            count_zeros_disparity_red = 8 - $countones(q_m_red[7:0]);

            if((disparity_red == 0) | (count_ones_disparity_red == count_zeros_disparity_red) )begin 
                next_tmds_red[9] = ~q_m_red[8];
                next_tmds_red[8] = q_m_red[8];
                next_tmds_red[7:0] = q_m_red[7:0] ^ {8{~q_m_red[8]}};
                if (q_m_red[8])
                    next_disparity_red = disparity_red + count_ones_disparity_red - count_zeros_disparity_red;
                else
                    next_disparity_red = disparity_red + count_zeros_disparity_red - count_ones_disparity_red;
            end
            else if((disparity_red > 0 && count_ones_disparity_red > count_zeros_disparity_red) || (disparity_red < 0 && count_ones_disparity_red < count_zeros_disparity_red))begin 
                next_tmds_red[9]   = 1'b1;
                next_tmds_red[8]   = q_m_red[8];
                next_tmds_red[7:0] = ~q_m_red[7:0];
                next_disparity_red = disparity_red + count_zeros_disparity_red - count_ones_disparity_red + (q_m_red[8] ? 2 : 0);
            end
            else begin

                next_tmds_red[9]   = 1'b0;
                next_tmds_red[8]   = q_m_red[8];
                next_tmds_red[7:0] = q_m_red[7:0];
                next_disparity_red = disparity_red + count_ones_disparity_red - count_zeros_disparity_red + (q_m_red[8] ? -2 : 0);
            end
        end

        else begin 
            next_tmds_red   = 10'b1101010100;


        end
end

// Combinational block for green
always_comb begin

    next_q_m_green = q_m_green;

    next_tmds_green = tmds_green;

    next_disparity_green = disparity_green;


    if (video_active) begin
        /*** STAGE 1 ***************************************************************/

        count_ones_green = $countones(green);

        xor_xnor_g = (count_ones_green > 4) ||
                     ((count_ones_green == 4) && (green[0] == 0));

        next_q_m_green[0] = green[0];
        next_q_m_green[8] = ~xor_xnor_g;


        if (xor_xnor_g) begin
            for (i = 1; i < 8; i++) begin
                next_q_m_green[i] =
                    ~(green[i] ^ next_q_m_green[i - 1]);
            end
        end
        else begin
            for (i = 1; i < 8; i++) begin
                next_q_m_green[i] =
                    green[i] ^ next_q_m_green[i - 1];
            end
        end
    end


    if (pipe_video_active) begin
        /*** STAGE 2: Disparity ***************************************************/

        count_ones_disparity_green =
            $countones(q_m_green[7:0]);

        count_zeros_disparity_green =
            8 - $countones(q_m_green[7:0]);


        if ((disparity_green == 0) |
            (count_ones_disparity_green == count_zeros_disparity_green)) begin

            next_tmds_green[9]   = ~q_m_green[8];
            next_tmds_green[8]   = q_m_green[8];
            next_tmds_green[7:0] =
                q_m_green[7:0] ^ {8{~q_m_green[8]}};

            if (q_m_green[8])
                next_disparity_green =
                    disparity_green +
                    count_ones_disparity_green -
                    count_zeros_disparity_green;
            else
                next_disparity_green =
                    disparity_green +
                    count_zeros_disparity_green -
                    count_ones_disparity_green;

        end

        else if ((disparity_green > 0 &&
                  count_ones_disparity_green >
                  count_zeros_disparity_green) ||
                 (disparity_green < 0 &&
                  count_ones_disparity_green <
                  count_zeros_disparity_green)) begin

            next_tmds_green[9]   = 1'b1;
            next_tmds_green[8]   = q_m_green[8];
            next_tmds_green[7:0] = ~q_m_green[7:0];

            next_disparity_green =
                disparity_green +
                count_zeros_disparity_green -
                count_ones_disparity_green +
                (q_m_green[8] ? 2 : 0);

        end

        else begin

            next_tmds_green[9]   = 1'b0;
            next_tmds_green[8]   = q_m_green[8];
            next_tmds_green[7:0] = q_m_green[7:0];

            next_disparity_green =
                disparity_green +
                count_ones_disparity_green -
                count_zeros_disparity_green +
                (q_m_green[8] ? -2 : 0);

        end
    end

    else begin
        next_tmds_green = 10'b1101010100;
    end

end


// Combinational block for blue
always_comb begin


    next_q_m_blue = q_m_blue;

    next_tmds_blue = tmds_blue;

    next_disparity_blue = disparity_blue;


    if (video_active) begin
        /*** STAGE 1 ***************************************************************/

        count_ones_blue = $countones(blue);

        xor_xnor_b = (count_ones_blue > 4) ||
                     ((count_ones_blue == 4) && (blue[0] == 0));

        next_q_m_blue[0] = blue[0];
        next_q_m_blue[8] = ~xor_xnor_b;


        if (xor_xnor_b) begin
            for (i = 1; i < 8; i++) begin
                next_q_m_blue[i] =
                    ~(blue[i] ^ next_q_m_blue[i - 1]);
            end
        end
        else begin
            for (i = 1; i < 8; i++) begin
                next_q_m_blue[i] =
                    blue[i] ^ next_q_m_blue[i - 1];
            end
        end
    end


    if (pipe_video_active) begin
        /*** STAGE 2: Disparity ***************************************************/

        count_ones_disparity_blue =
            $countones(q_m_blue[7:0]);

        count_zeros_disparity_blue =
            8 - $countones(q_m_blue[7:0]);


        if ((disparity_blue == 0) |
            (count_ones_disparity_blue == count_zeros_disparity_blue)) begin

            next_tmds_blue[9]   = ~q_m_blue[8];
            next_tmds_blue[8]   = q_m_blue[8];
            next_tmds_blue[7:0] =
                q_m_blue[7:0] ^ {8{~q_m_blue[8]}};

            if (q_m_blue[8])
                next_disparity_blue =
                    disparity_blue +
                    count_ones_disparity_blue -
                    count_zeros_disparity_blue;
            else
                next_disparity_blue =
                    disparity_blue +
                    count_zeros_disparity_blue -
                    count_ones_disparity_blue;

        end

        else if ((disparity_blue > 0 &&
                  count_ones_disparity_blue >
                  count_zeros_disparity_blue) ||
                 (disparity_blue < 0 &&
                  count_ones_disparity_blue <
                  count_zeros_disparity_blue)) begin

            next_tmds_blue[9]   = 1'b1;
            next_tmds_blue[8]   = q_m_blue[8];
            next_tmds_blue[7:0] = ~q_m_blue[7:0];

            next_disparity_blue =
                disparity_blue +
                count_zeros_disparity_blue -
                count_ones_disparity_blue +
                (q_m_blue[8] ? 2 : 0);

        end

        else begin

            next_tmds_blue[9]   = 1'b0;
            next_tmds_blue[8]   = q_m_blue[8];
            next_tmds_blue[7:0] = q_m_blue[7:0];

            next_disparity_blue =
                disparity_blue +
                count_ones_disparity_blue -
                count_zeros_disparity_blue +
                (q_m_blue[8] ? -2 : 0);

        end
    end

    else begin
        /*** CONTROL PERIOD *******************************************************/

        case ({pipe_vsync, pipe_hsync})

            2'b00: begin
                next_tmds_blue = 10'b1101010100;
            end

            2'b01: begin
                next_tmds_blue = 10'b0010101011;
            end

            2'b10: begin
                next_tmds_blue = 10'b0101010100;
            end

            2'b11: begin
                next_tmds_blue = 10'b1010101011;
            end

        endcase

        next_disparity_blue = 0;

    end

end


endmodule