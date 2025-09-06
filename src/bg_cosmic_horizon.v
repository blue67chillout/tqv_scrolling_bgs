// add space background here

module bg_pixel_planets(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        bg_en,
    input  wire        video_active,  // 1 = pixel is valid
    input  wire [10:0]  pix_x,
    input  wire [10:0]  pix_y,
    input  wire        vsync,
    output wire [1:0]  R,
    output wire [1:0]  G,
    output wire [1:0]  B
);

    localparam DISPLAY_MODE = 1; // 0=640x480 (VGA), 1=1024x768 (XGA)

    localparam H_RES = 1024;
    localparam V_RES = 768;
    localparam GROUND_Y = 840;

    //----------------------- Scrolling Counter -------------------------
    reg [9:0] scroll_counter;
    always @(posedge vsync or negedge rst_n)
        if (!rst_n)
            scroll_counter <= 0;
        else
            scroll_counter <= scroll_counter + 1;


    // ------------------------Stars-------------------------------------
    localparam STAR_SIZE = 1;
    localparam NUM_STARS = 70;  


    // Flattened STAR_X / STAR_Y for VGA
    // localparam [10*NUM_STARS-1:0] STAR_X_VGA_FLAT = {
    //     10'd230,10'd210,10'd190,10'd170,10'd150,10'd130,10'd110,10'd90,10'd70,10'd50,
    //     10'd220,10'd200,10'd180,10'd160,10'd140,10'd120,10'd100,10'd80,10'd60,10'd40,
    //     10'd398,10'd287,10'd176,10'd87,10'd501,10'd412,10'd323,10'd234,10'd145,10'd56,
    //     10'd343,10'd254,10'd165,10'd76,10'd578,10'd467,10'd356,10'd245,10'd134,10'd23,
    //     10'd489,10'd356,10'd201,10'd112,10'd543,10'd454,10'd365,10'd276,10'd187,10'd98,
    //     10'd445,10'd298,10'd178,10'd34,10'd612,10'd523,10'd412,10'd289,10'd156,10'd67,
    //     10'd467,10'd345,10'd234,10'd89,10'd578,10'd456,10'd389,10'd267,10'd123,10'd45
    // };

    // localparam [10*NUM_STARS-1:0] STAR_Y_VGA_FLAT = {
    //     10'd496,10'd595,10'd152,10'd456,10'd288,10'd584,10'd488,10'd200,10'd520,10'd536,
    //     10'd648,10'd640,10'd624,10'd608,10'd592,10'd576,10'd560,10'd464,10'd512,10'd528,
    //     10'd587,10'd196,10'd462,10'd214,10'd409,10'd284,10'd516,10'd142,10'd392,10'd267,
    //     10'd214,10'd441,10'd316,10'd72,10'd196,10'd462,10'd214,10'd441,10'd316,10'd72,
    //     10'd587,10'd196,10'd462,10'd249,10'd124,10'd374,10'd302,10'd427,10'd72,10'd444,
    //     10'd214,10'd321,10'd124,10'd552,10'd196,10'd427,10'd302,10'd72,10'd374,10'd427,
    //     10'd142,10'd196,10'd374,10'd427,10'd302,10'd72,10'd196,10'd89,10'd552,10'd267
    // };




    //---------------------------Planet-1 (Hot, near sun)-----------------------------

    localparam P1_X = 192;
    localparam P1_Y = 320;
    localparam P1_R = 48;

  wire signed [11:0] p1x = pix_x - P1_X;
    wire signed [11:0] p1y = pix_y - P1_Y;
    wire [15:0] p1_r_sq    = P1_R * P1_R;
    wire [18:0] dist_sq = p1x*p1x + p1y*p1y;

   
    wire in_p1 = (dist_sq <= p1_r_sq);

    reg [1:0] p1_red, p1_green, p1_blue;

    always @* begin
        if (in_p1) begin
            if (pix_x + pix_y < P1_X + P1_Y) begin
                
                    p1_red = 2'd3; p1_green = 2'd1; p1_blue = 2'd0; 
                end
            
            else begin
                
                    p1_red = 2'd3; p1_green = 2'd0; p1_blue = 2'd0; 
                end
            
        end else begin
            p1_red = 2'd0; p1_green = 2'd0; p1_blue = 2'd0; 
        end
    enD
    //------------------------------------------Planet-2 (Earth)-----------------------------------------

    localparam P2_X = 480;
    localparam P2_Y = 224;
    localparam P2_R = 64;

    wire [9:0] p2_dx = (pix_x > P2_X) ? (pix_x - P2_X) : (P2_X - pix_x);
    wire [9:0] p2_dy = (pix_y > P2_Y) ? (pix_y - P2_Y) : (P2_Y - pix_y);
    wire [19:0] p2_dist_sq = p2_dx * p2_dx + p2_dy * p2_dy;
    wire [15:0] p2_r_sq    = P2_R * P2_R;

    wire in_p2 = (p2_dist_sq <= p2_r_sq);

    reg [1:0] p2_red, p2_green, p2_blue;
    wire noise6 = (pix_x[7:5] ^ pix_y[6:4]) + (pix_x[4] ^ pix_y[5]) ;
    
    always @(*) begin
        if (in_p2) begin
            if (noise6 < 3) begin
                p2_red   = 2'b00;
                p2_green = 2'b01;
                p2_blue  = 2'b00;
            end else begin
                p2_red   = 2'b00;
                p2_green = 2'b01;
                p2_blue  = 2'b11;
            end
        end else begin
            p2_red   = 2'b00;
            p2_green = 2'b00;
            p2_blue  = 2'b00;
        end
    end

 

    //----------------------------Planet-4 (Uranus)-----------------------------------------

  localparam P4_X = (DISPLAY_MODE == 0) ? 580 : 928;
    localparam P4_Y = (DISPLAY_MODE == 0) ? 80 : 128;
    localparam P4_R = (DISPLAY_MODE == 0) ? 40 : 64;

    wire [9:0] p4_dx = (pix_x > P4_X) ? (pix_x - P4_X) : (P4_X - pix_x);
    wire [9:0] p4_dy = (pix_y > P4_Y) ? (pix_y - P4_Y) : (P4_Y - pix_y);
    wire [19:0] p4_dist_sq = p4_dx * p4_dx + p4_dy * p4_dy;
    wire [15:0] p4_r_sq    = P4_R * P4_R;

    wire in_p4 = (p4_dist_sq <= p4_r_sq);

    reg [1:0] p4_red, p4_green, p4_blue;

    always @(*) begin
        if (in_p4) begin
        
         
                p4_red   = 2'b0;  
                p4_green = 2'b10;  
                p4_blue  = 2'b10; 
            end
         else begin
            p4_red   = 2'b00;
            p4_green = 2'b00;
            p4_blue  = 2'b00;
        end
    end

    //--------------------------------Sun------------------------------------
    localparam SUN_X = 80;
    localparam SUN_Y = 80;
    localparam SUN_R = 112;

    wire [9:0] sun_dx = (pix_x > SUN_X) ? (pix_x - SUN_X) : (SUN_X - pix_x);
    wire [9:0] sun_dy = (pix_y > SUN_Y) ? (pix_y - SUN_Y) : (SUN_Y - pix_y);
    wire [20:0] sun_dist_sq = sun_dx * sun_dx + sun_dy * sun_dy;
    wire [15:0] sun_r_sq = SUN_R * SUN_R;

    wire in_sun = (sun_dist_sq <= sun_r_sq);

    localparam SUN_CORONA_OFFSET = 16;
    localparam SUN_D1_R_OFFSET = 96;
    localparam SUN_D2_R_OFFSET = 144;

    wire [15:0] sun_corona_r_sq = (SUN_R + SUN_CORONA_OFFSET) * (SUN_R + SUN_CORONA_OFFSET);
    wire in_sun_corona = (sun_dist_sq <= sun_corona_r_sq) && (sun_dist_sq > sun_r_sq);

    wire [20:0] sun_d1_r_sq = (SUN_R + SUN_D1_R_OFFSET) * (SUN_R + SUN_D1_R_OFFSET);
    wire in_sun_d1 = (sun_dist_sq <= sun_d1_r_sq) && (sun_dist_sq > sun_corona_r_sq); 

    wire [20:0] sun_d2_r_sq = (SUN_R + SUN_D2_R_OFFSET) * (SUN_R + SUN_D2_R_OFFSET);
    wire in_sun_d2 = (sun_dist_sq <= sun_d2_r_sq) && (sun_dist_sq >sun_d1_r_sq); 


  
    // ---------------- Final Color Assignment ---------------------
    assign R = (!video_active)  ? 2'b00 :
            in_sun              ? 2'b11 : 
            in_sun_corona       ? 2'b11 :
           
            in_p1               ? p1_red:
            in_p2               ? p2_red:
           
            in_p4               ? p4_red:

           
            in_sun_d1           ? 2'b01:
            in_sun_d2           ?2'b01:
            
            2'b00;

    assign G = R;

    assign B = R;

  
endmodule

