// add space background here

module bg_pixel_planets(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        bg_en,
    input  wire        video_active,  // 1 = pixel is valid
    input  wire [9:0]  pix_x,
    input  wire [9:0]  pix_y,
    input  wire        vsync,
    output wire [1:0]  R,
    output wire [1:0]  G,
    output wire [1:0]  B
);

  localparam DISPLAY_MODE = 0; // 0=640x480 (VGA), 1=1024x768 (XGA)

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
    localparam [9:0] STAR_X_VGA [0:NUM_STARS-1] = '{
        45, 123, 267, 389, 456, 578, 89, 234, 345, 467,
        67, 156, 289, 412, 523, 612, 34, 178, 298, 445,
        98, 187, 276, 365, 454, 543, 112, 201, 356, 489,
        23, 134, 245, 356, 467, 578, 76, 165, 254, 343,
        56, 145, 234, 323, 412, 501, 87, 176, 287, 398,
        40, 60, 80, 100, 120, 140, 160, 180, 200, 220,
        50, 70, 90, 110, 130, 150, 170, 190, 210, 230
    };

    localparam [9:0] STAR_Y_VGA [0:NUM_STARS-1] = '{
        56, 123, 89, 234, 167, 345, 78, 201, 134, 278,
        45, 189, 267, 123, 345, 89, 156, 234, 67, 298,
        234, 78, 156, 289, 123, 367, 45, 198, 276, 134,
        167, 245, 89, 323, 178, 256, 134, 289, 67, 345,
        123, 267, 45, 189, 234, 78, 156, 289, 123, 367,
        V_RES-150, V_RES-160, V_RES-190, V_RES-130, V_RES-120,
        V_RES-110, V_RES-100, V_RES-90,  V_RES-80,  V_RES-75,
        V_RES-145, V_RES-155, V_RES-355, V_RES-175, V_RES-115,
        V_RES-300, V_RES-195, V_RES-385, V_RES-108, V_RES-170
    };

    localparam [9:0] STAR_X_XGA [0:NUM_STARS-1] = '{
        72, 196, 427, 622, 729, 924, 142, 374, 552, 747, 
        107, 249, 462, 659, 836, 979, 54, 284, 476, 712, 
        156, 299, 441, 584, 726, 868, 179, 321, 569, 782, 
        36, 214, 392, 569, 747, 924, 121, 264, 406, 548, 
        89, 232, 374, 516, 659, 801, 139, 281, 459, 636, 
        64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 
        80, 112, 144, 176, 208, 240, 272, 304, 336, 368
    };

    localparam [9:0] STAR_Y_XGA [0:NUM_STARS-1] = '{
        89, 196, 142, 374, 267, 552, 124, 321, 214, 444, 
        72, 302, 427, 196, 552, 142, 249, 374, 107, 476, 
        374, 124, 249, 462, 196, 587, 72, 316, 441, 214,
        267, 392, 142, 516, 284, 409, 214, 462, 107, 552,
        196, 427, 72, 302, 374, 124, 249, 462, 196, 587,
        528, 512, 464, 560, 576, 592, 608, 624, 640, 648, 
        536, 520, 200, 488, 584, 288, 456, 152, 595, 496
    };

    localparam [9:0] STAR_X [0:NUM_STARS-1] = (DISPLAY_MODE == 0) ? STAR_X_VGA : STAR_X_XGA;
    localparam [9:0] STAR_Y [0:NUM_STARS-1] = (DISPLAY_MODE == 0) ? STAR_Y_VGA : STAR_Y_XGA;

    localparam [1:0] STAR_COLOR [0:NUM_STARS-1] = '{
        0,1,2,0,1,2,0,1,2,0,
        1,2,0,1,2,0,1,2,0,1,
        2,0,1,2,0,1,2,0,1,2,
        0,1,2,0,1,2,0,1,2,0,
        1,2,0,1,2,0,1,2,0,1,
        0,1,2,0,1,2,0,1,2,0,
        1,2,0,1,2,0,1,2,0,1
    };

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

