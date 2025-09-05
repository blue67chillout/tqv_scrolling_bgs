/*
 * Copyright (c) 2025 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Change the name of this module to something that reflects its functionality and includes your name for uniqueness
// For example tqvp_yourname_spi for an SPI peripheral.
// Then edit tt_wrapper.v line 41 and change tqvp_example to your chosen module name.
module tqvp_example (
    input         clk,          // Clock - the TinyQV project clock is normally set to 64MHz.
    input         rst_n,        // Reset_n - low to reset.

    input  [7:0]  ui_in,        // The input PMOD, always available.  Note that ui_in[7] is normally used for UART RX.
                                // The inputs are synchronized to the clock, note this will introduce 2 cycles of delay on the inputs.

    output [7:0]  uo_out,       // The output PMOD.  Each wire is only connected if this peripheral is selected.
                                // Note that uo_out[0] is normally used for UART TX.

    input [5:0]   address,      // Address within this peripheral's address space
    input [31:0]  data_in,      // Data in to the peripheral, bottom 8, 16 or all 32 bits are valid on write.

    // Data read and write requests from the TinyQV core.
    input [1:0]   data_write_n, // 11 = no write, 00 = 8-bits, 01 = 16-bits, 10 = 32-bits
    input [1:0]   data_read_n,  // 11 = no read,  00 = 8-bits, 01 = 16-bits, 10 = 32-bits
    
    output [31:0] data_out,     // Data out from the peripheral, bottom 8, 16 or all 32 bits are valid on read when data_ready is high.
    output        data_ready,

    output        user_interrupt  // Dedicated interrupt request for this peripheral
);

    
    reg [7:0] CTRL; // 0x0  | mode | bg1_en | bg2_en | bg3_en | reset_interrupt| 3 unused bits

    //----mode ---///
    // 0 - configure 
    // 1 - stream

    always @(posedge clk) begin
        if (!rst_n) begin
            CTRL <= 0;
        end else begin
            if (address == 6'h0 && data_write_n == 2'b00) begin
                CTRL <= data_in[7:0];
            end
        end
    end


    reg hsync;
    reg vsync;
    wire visible;
    reg [10:0] pix_x;
    reg [10:0] pix_y;
    
    wire [1:0]R,G,B ;

    reg vga_en ;
    
    video_controller u_video_controller(
        .clk      	(clk       ),
        .reset    	(rst_n     ),
        .enable     (vga_en    ),
        .polarity 	(1'b1      ), // 0 = negative polarity (VGA, SVGA), 1 = positive polarity (XGA, SXGA)
        .hsync    	(hsync     ),
        .vsync    	(vsync     ),
        .visible  	(visible   ),
        .pix_x    	(pix_x     ),
        .pix_y    	(pix_y     )
    );
    

    wire [1:0] bg1_R, bg1_G, bg1_B;
    wire [1:0] bg2_R, bg2_G, bg2_B;
    wire [1:0] bg3_R, bg3_G, bg3_B;

    reg bg1_en, bg2_en, bg3_en;


    always @(posedge clk) begin
        if (!rst_n) begin
            vga_en <= 0;
            bg1_en <= 0;
            bg2_en <= 0;
            bg3_en <= 0;
        end else begin
            if (CTRL[0] == 1'b1) begin
                vga_en <= 1'b1;
                bg1_en <= CTRL[1];
                bg2_en <= CTRL[2];
                bg3_en <= CTRL[3];
            end else begin
                vga_en <= 1'b0;
                bg1_en <= 1'b0;
                bg2_en <= 1'b0;
                bg3_en <= 1'b0;
            end
        end
    end

    bg_pixel_dunes bg1 (
            .rst_n(rst_n),
            .bg_en (bg1_en),
            .video_active(visible),
            .pix_x(pix_x),
            .pix_y(pix_y),
            .vsync(vsync),
            .R(bg1_R),
            .G(bg1_G),
            .B(bg1_B)
        );

     bg_pixel_planets bg2 (
        .clk          (clk),
        .rst_n        (rst_n),
        .bg_en        (bg2_en),
        .video_active (visible),
        .pix_x        (pix_x), // truncate from 11-bit
        .pix_y        (pix_y),
        .vsync        (vsync),
        .R            (bg2_R),
        .G            (bg2_G),
        .B            (bg2_B)
    );

     bg_pixel_mario bg3 (
        .clk          (clk),
        .rst_n        (rst_n),
        .bg_en        (bg3_en),
        .video_active (visible),
        .pix_x        (pix_x),
        .pix_y        (pix_y),
        .vsync        (vsync),
        .R            (bg3_R),
        .G            (bg3_G),
        .B            (bg3_B)
    );
    // Address 0 reads the example data register.  
    // Address 4 reads ui_in
    // All other addresses read 0.
    assign data_out = (address == 6'h0) ? {24'b0,CTRL} :
                      32'h0;

    // All reads complete in 1 clock
    assign data_ready = 1;
    

    // List all unused inputs to prevent warnings
    // data_read_n is unused as none of our behaviour depends on whether
    // registers are being read.

    // Detect invalid enable combinations
    wire multiple_enables = (bg1_en & bg2_en) | (bg1_en & bg3_en) | (bg2_en & bg3_en);

    // Final color selection
    assign R = (multiple_enables) ? 2'b00 :
            (bg1_en) ? bg1_R :
            (bg2_en) ? bg2_R :
            (bg3_en) ? bg3_R : 2'b00;

    assign G = (multiple_enables) ? 2'b00 :
            (bg1_en) ? bg1_G :
            (bg2_en) ? bg2_G :
            (bg3_en) ? bg3_G : 2'b00;

    assign B = (multiple_enables) ? 2'b00 :
            (bg1_en) ? bg1_B  :
            (bg2_en) ? bg2_B  :
            (bg3_en) ? bg3_B  : 2'b00;

    reg interrupt;

    always @(posedge clk) begin
        if (!rst_n) begin
            interrupt <= 0;
        end

        if (multiple_enables) begin
            interrupt <= 1;
        end else if (CTRL[4]) begin
            interrupt <= 0;
        end

    end

    assign user_interrupt = interrupt;

    assign uo_out = {vsync, hsync, B, G, R};

    wire _unused = &{data_read_n, 1'b0};

endmodule
