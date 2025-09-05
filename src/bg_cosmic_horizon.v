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

    localparam H_RES = (DISPLAY_MODE == 0) ? 640  : 1024;
    localparam V_RES = (DISPLAY_MODE == 0) ? 480  : 768;
    localparam GROUND_Y = (DISPLAY_MODE == 0) ? 450 : 840;

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
    localparam STAR_SIZE = 1;
    localparam NUM_STARS = 70;

// ------------------ STAR_X / STAR_Y constants ------------------

localparam STAR_SIZE = 1;
localparam NUM_STARS = 70;

// ---------------------- Flattened STAR_X / STAR_Y for VGA ----------------------
localparam NUM_STARS = 70;

// Flattened star data
localparam [10*NUM_STARS-1:0] STAR_X_VGA_FLAT = {
    10'd230,10'd210,10'd190,10'd170,10'd150,10'd130,10'd110,10'd90,10'd70,10'd50,
    10'd220,10'd200,10'd180,10'd160,10'd140,10'd120,10'd100,10'd80,10'd60,10'd40,
    10'd398,10'd287,10'd176,10'd87,10'd501,10'd412,10'd323,10'd234,10'd145,10'd56,
    10'd343,10'd254,10'd165,10'd76,10'd578,10'd467,10'd356,10'd245,10'd134,10'd23,
    10'd489,10'd356,10'd201,10'd112,10'd543,10'd454,10'd365,10'd276,10'd187,10'd98,
    10'd445,10'd298,10'd178,10'd34,10'd612,10'd523,10'd412,10'd289,10'd156,10'd67,
    10'd467,10'd345,10'd234,10'd89,10'd578,10'd456,10'd389,10'd267,10'd123,10'd45
};

localparam [10*NUM_STARS-1:0] STAR_Y_VGA_FLAT = {
    10'd496,10'd595,10'd152,10'd456,10'd288,10'd584,10'd488,10'd200,10'd520,10'd536,
    10'd648,10'd640,10'd624,10'd608,10'd592,10'd576,10'd560,10'd464,10'd512,10'd528,
    10'd587,10'd196,10'd462,10'd214,10'd409,10'd284,10'd516,10'd142,10'd392,10'd267,
    10'd214,10'd441,10'd316,10'd72,10'd196,10'd462,10'd214,10'd441,10'd316,10'd72,
    10'd587,10'd196,10'd462,10'd249,10'd124,10'd374,10'd302,10'd427,10'd72,10'd444,
    10'd214,10'd321,10'd124,10'd552,10'd196,10'd427,10'd302,10'd72,10'd374,10'd427,
    10'd142,10'd196,10'd374,10'd427,10'd302,10'd72,10'd196,10'd89,10'd552,10'd267
};

localparam [2*NUM_STARS-1:0] STAR_COLOR_FLAT = {
    2'd1,2'd0,2'd2,2'd1,2'd0,2'd2,2'd1,2'd0,2'd2,2'd1,
    2'd0,2'd2,2'd1,2'd0,2'd2,2'd1,2'd0,2'd2,2'd1,2'd0,
    2'd2,2'd0,2'd1,2'd2,2'd0,2'd1,2'd2,2'd0,2'd1,2'd2,
    2'd0,2'd1,2'd2,2'd0,2'd1,2'd2,2'd0,2'd1,2'd2,2'd0,
    2'd0,2'd1,2'd2,2'd0,2'd1,2'd2,2'd0,2'd1,2'd2,2'd0,
    2'd1,2'd2,2'd0,2'd1,2'd2,2'd0,2'd1,2'd2,2'd0,2'd1,
    2'd0,2'd1,2'd2,2'd0,2'd1,2'd2,2'd0,2'd1,2'd2,2'd0
};

// Output arrays as wires
wire [9:0] STAR_X [0:NUM_STARS-1];
wire [9:0] STAR_Y [0:NUM_STARS-1];
wire [1:0] STAR_COLOR [0:NUM_STARS-1];

genvar i;
generate
    for (i = 0; i < NUM_STARS; i = i + 1) begin : STAR_ASSIGN
        assign STAR_X[i]     = STAR_X_VGA_FLAT[i*10 +: 10];
        assign STAR_Y[i]     = STAR_Y_VGA_FLAT[i*10 +: 10];
        assign STAR_COLOR[i] = STAR_COLOR_FLAT[i*2 +: 2];
    end
endgenerate

    reg [2:0] twinkle_counter;
    always @(posedge vsync) begin
        twinkle_counter <= twinkle_counter + 1;
    end


    reg [9:0] star_scroll;
    always @(posedge vsync) begin
        star_scroll <= star_scroll + 5;  
    end


    wire is_star;
    reg star_accum;
    reg [1:0] star_color_out;
    integer i;


    reg [9:0] sx;
    reg [9:0] sy;

    always @* begin
        star_accum = 0;
        star_color_out = 0;

        for (i = 0; i < NUM_STARS; i = i + 1) begin
            if (STAR_X[i] >= (star_scroll >> 1))
                sx = STAR_X[i] - (star_scroll >> 1);
            else
                sx = STAR_X[i] + H_RES - (star_scroll >> 1);

            sy = STAR_Y[i];

            if ((pix_x >= sx - STAR_SIZE) && (pix_x <= sx + STAR_SIZE) &&
                (pix_y >= sy - STAR_SIZE) && (pix_y <= sy + STAR_SIZE)) begin
        
                if (((i + twinkle_counter) % 8) != 0) begin
                    star_accum = 1;
                    star_color_out = STAR_COLOR[i];
                end
            end
        end
    end

    assign is_star = star_accum;


    //---------------------------Planet-1 (Hot, near sun)-----------------------------

    localparam P1_X = (DISPLAY_MODE == 0) ? 120 : 192;
    localparam P1_Y = (DISPLAY_MODE == 0) ? 200 : 320;
    localparam P1_R = (DISPLAY_MODE == 0) ? 30 : 48;

    wire signed [11:0] p1x = pix_x - P1_X;
    wire signed [11:0] p1y = pix_y - P1_Y;
    wire [18:0] dist_sq = p1x*p1x + p1y*p1y;

    wire [7:0] noise = {p1x[2]^p1y[3], p1x[4]^p1y[1], p1y[2]^p1x[5], p1x[0]^p1y[0]};  
    wire signed [4:0] bump = (noise % 9) - 4; 
    wire [11:0] distorted_r = P1_R + bump;

    wire [18:0] distorted_r_sq = distorted_r * distorted_r;

    wire in_p1 = (dist_sq <= distorted_r_sq);

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
    end

    //------------------------------------------Planet-2 (Earth)-----------------------------------------

    localparam P2_X = (DISPLAY_MODE == 0) ? 300 : 480;
    localparam P2_Y = (DISPLAY_MODE == 0) ? 140 : 224;
    localparam P2_R = (DISPLAY_MODE == 0) ? 40 : 64;

    wire [9:0] p2_dx = (pix_x > P2_X) ? (pix_x - P2_X) : (P2_X - pix_x);
    wire [9:0] p2_dy = (pix_y > P2_Y) ? (pix_y - P2_Y) : (P2_Y - pix_y);
    wire [19:0] p2_dist_sq = p2_dx * p2_dx + p2_dy * p2_dy;
    wire [15:0] p2_r_sq    = P2_R * P2_R;

    wire in_p2 = (p2_dist_sq <= p2_r_sq);

    reg [1:0] p2_red, p2_green, p2_blue;

    always @(*) begin
        if (in_p2) begin
            reg [2:0] noise;
            noise = (pix_x[7:5] ^ pix_y[6:4]) + (pix_x[4] ^ pix_y[5]);

            if (noise < 3) begin
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

    // -----------------------------Planet-3 (Saturn) ---------------------------------------
    localparam P3_X = (DISPLAY_MODE == 0) ? 455 : 728;
    localparam P3_Y = (DISPLAY_MODE == 0) ? 340 : 544;
    localparam P3_R = (DISPLAY_MODE == 0) ? 55 : 88;

    wire signed [11:0] dx3 = $signed(pix_x) - $signed(P3_X);
    wire signed [11:0] dy3 = $signed(pix_y) - $signed(P3_Y);

    wire [23:0] p3_dist_sq = (dx3*dx3) + (dy3*dy3);
    wire [15:0] p3_r_sq    = P3_R * P3_R;
    wire in_p3 = (p3_dist_sq <= p3_r_sq);


    localparam RING_SLOPE_NUM = 1;  
    localparam RING_SLOPE_DEN = 2;  

    wire signed [23:0] u_scaled3 = (dx3*RING_SLOPE_DEN) + (dy3*RING_SLOPE_NUM);
    wire signed [23:0] v_scaled3 = (dy3*RING_SLOPE_DEN) - (dx3*RING_SLOPE_NUM);

    function automatic [23:0] abs24(input signed [23:0] s);
        abs24 = (s < 0) ? -s : s;
    endfunction

    localparam integer RING3_LEN     = P3_R*4*RING_SLOPE_DEN; 
    localparam integer RING3_THICK   = 2*RING_SLOPE_DEN;           
    localparam integer RING3_OFFSET  = 10*RING_SLOPE_DEN;         

    wire in_band3_0 = (abs24(v_scaled3)                 <= RING3_THICK) && (abs24(u_scaled3) <= RING3_LEN);
    wire in_band3_1 = (abs24(v_scaled3 - RING3_OFFSET)  <= RING3_THICK) && (abs24(u_scaled3) <= RING3_LEN);
    wire in_band3_2 = (abs24(v_scaled3 + RING3_OFFSET)  <= RING3_THICK) && (abs24(u_scaled3) <= RING3_LEN);

    wire in_ring3_any = in_band3_0 | in_band3_1 | in_band3_2;


    wire ring3_front = in_ring3_any && ( !in_p3 || (v_scaled3 < 0) );
    wire ring3_back  = in_ring3_any && (  in_p3 && (v_scaled3 >= 0) );  

    reg [1:0] p3_red, p3_green, p3_blue;

    always @* begin
        if (ring3_front) begin
            
            p3_red   = 2'b11; p3_green = 2'b11; p3_blue  = 2'b00;  
        end else if (in_p3) begin
            
            p3_red   = 2'b10; p3_green = 2'b1; p3_blue  = 2'b0; 
        end else if (ring3_back) begin
            
            p3_red   = 2'b01; p3_green = 2'b01; p3_blue  = 2'b01;
        end else begin
            
            p3_red   = 2'b00; p3_green = 2'b00; p3_blue  = 2'b00;
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
        
            reg [2:0] noise4;
            noise4 = (pix_x[6:4] ^ pix_y[5:3]) + (pix_x[3] ^ pix_y[4]);

            if (noise4 < 7) begin
                p4_red   = 2'b00;  
                p4_green = 2'b10;  
                p4_blue  = 2'b10;  
            end else begin
                p4_red   = 2'b0;  
                p4_green = 2'b01;  
                p4_blue  = 2'b01; 
            end
        end else begin
            p4_red   = 2'b00;
            p4_green = 2'b00;
            p4_blue  = 2'b00;
        end
    end


    //--------------------------------Sun------------------------------------
    localparam SUN_X = (DISPLAY_MODE == 0) ? 50 : 80;
    localparam SUN_Y = (DISPLAY_MODE == 0) ? 50 : 80;
    localparam SUN_R = (DISPLAY_MODE == 0) ? 70 : 112;

    wire [9:0] sun_dx = (pix_x > SUN_X) ? (pix_x - SUN_X) : (SUN_X - pix_x);
    wire [9:0] sun_dy = (pix_y > SUN_Y) ? (pix_y - SUN_Y) : (SUN_Y - pix_y);
    wire [20:0] sun_dist_sq = sun_dx * sun_dx + sun_dy * sun_dy;
    wire [15:0] sun_r_sq = SUN_R * SUN_R;

    wire in_sun = (sun_dist_sq <= sun_r_sq);

    localparam SUN_CORONA_OFFSET = (DISPLAY_MODE == 0) ? 10 : 16;
    localparam SUN_D1_R_OFFSET = (DISPLAY_MODE == 0) ? 60 : 96;
    localparam SUN_D2_R_OFFSET = (DISPLAY_MODE == 0) ? 90 : 144;

    wire [15:0] sun_corona_r_sq = (SUN_R + SUN_CORONA_OFFSET) * (SUN_R + SUN_CORONA_OFFSET);
    wire in_sun_corona = (sun_dist_sq <= sun_corona_r_sq) && (sun_dist_sq > sun_r_sq);

    wire [20:0] sun_d1_r_sq = (SUN_R + SUN_D1_R_OFFSET) * (SUN_R + SUN_D1_R_OFFSET);
    wire in_sun_d1 = (sun_dist_sq <= sun_d1_r_sq) && (sun_dist_sq > sun_corona_r_sq); 

    wire [20:0] sun_d2_r_sq = (SUN_R + SUN_D2_R_OFFSET) * (SUN_R + SUN_D2_R_OFFSET);
    wire in_sun_d2 = (sun_dist_sq <= sun_d2_r_sq) && (sun_dist_sq >sun_d1_r_sq); 


    // -------------------- Foreground Planet --------------------
 
    localparam FG_X = H_RES/2;

    localparam FG_Y_OFFSET =  (DISPLAY_MODE == 0) ? 530 : 1200;    
    localparam FG_Y = V_RES + FG_Y_OFFSET; 
    localparam FG_R = (DISPLAY_MODE == 0) ? 620 : 200;        

    wire [9:0] fg_dx = (pix_x > FG_X) ? (pix_x - FG_X) : (FG_X - pix_x);
    wire [9:0] fg_dy = (pix_y > FG_Y) ? (pix_y - FG_Y) : (FG_Y - pix_y);
    wire [25:0] fg_dist_sq = fg_dx * fg_dx + fg_dy * fg_dy;
    wire [25:0] fg_r_sq    = FG_R * FG_R;

    wire in_foreground = (fg_dist_sq <= fg_r_sq-10000);
    wire in_edge = (fg_dist_sq>fg_r_sq-10000 &&fg_dist_sq<=fg_r_sq );

    reg [1:0] fg_red, fg_green, fg_blue;

    always @(*) begin
        if (in_foreground) begin
            fg_red   = 2'b01; 
            fg_green = 2'b01;
            fg_blue  = 2'b01;
        end else begin
            fg_red   = 2'b00;
            fg_green = 2'b00;
            fg_blue  = 2'b00;
        end
    end
    // ---------------- Final Color Assignment ---------------------
    assign R = (!video_active)  ? 2'b00 :
            in_sun              ? 2'b11 : 
            in_sun_corona       ? 2'b10 :
            in_foreground &&   (DISPLAY_MODE == 0)      ? fg_red:
            in_edge&&   (DISPLAY_MODE == 0)             ? 2'b10:
            
            in_p1               ? p1_red:
            in_p2               ? p2_red:
            in_p3               ? p3_red:
            in_p4               ? p4_red:

            is_star && (star_color_out == 0) ? 2'b11 : 
            is_star && (star_color_out == 1) ? 2'b11 :   
            is_star && (star_color_out == 2) ? 2'b01 : 
            
            in_sun_d1           ? 2'b01:
            in_sun_d2           ?2'b01:
            
            2'b00;

    assign G = (!video_active)  ? 2'b00 :           
            in_sun              ? 2'b10 :
            in_sun_corona       ? 2'b01 :

            in_foreground &&   (DISPLAY_MODE == 0)      ? fg_green:
            in_edge  &&   (DISPLAY_MODE == 0)          ? 2'b10:

            in_p1               ? p1_green:
            in_p2               ? p2_green:
            in_p3               ? p3_green:
            in_p4               ? p4_green:

            is_star && (star_color_out == 0) ? 2'b11 : 
            is_star && (star_color_out == 1) ? 2'b01 :  
            is_star && (star_color_out == 2) ? 2'b10 :  
                
            in_sun_d1           ? 2'b00:
            in_sun_d2           ? 2'b00:
            
            2'b00;

    assign B = (!video_active)  ? 2'b00 :
            in_sun              ? 2'b00 :
            in_sun_corona       ? 2'b00 :

            in_foreground &&   (DISPLAY_MODE == 0)    ? fg_blue:
            in_edge   &&   (DISPLAY_MODE == 0)          ? 2'b10:

            in_p1               ? p1_blue:
            in_p2               ? p2_blue:
            in_p3               ? p3_blue:
            in_p4               ? p4_blue:

            is_star && (star_color_out == 0) ? 2'b11 :  
            is_star && (star_color_out == 1) ? 2'b00 :  
            is_star && (star_color_out == 2) ? 2'b11 : 
            
            in_sun_d1           ? 2'b00:
            in_sun_d2           ? 2'b01:
            
            2'b00;

  
endmodule

