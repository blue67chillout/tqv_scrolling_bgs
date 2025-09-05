module bg_pixel_dunes (
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
localparam GROUND_Y = (DISPLAY_MODE == 0) ? 450 : 840 ,
                        MOUND_X0 = 306,
                        MOUND_W = 64,
                        HALF_MOUND_W = 32;

// =================== Mound, Scrolling, and Clouds ===================
reg [10:0] scroll_counter;
always @(posedge vsync or negedge rst_n)
    if (!rst_n) scroll_counter <= 0;
    else        scroll_counter <= scroll_counter + 1;

function [2:0] mound_lut_val;
    input [4:0] idx;
    begin
        case(idx)
            5'd0, 5'd1, 5'd2, 5'd3, 5'd4, 5'd5: mound_lut_val = 3'd0;
            5'd6, 5'd7, 5'd8: mound_lut_val = 3'd1;
            5'd9, 5'd10, 5'd11, 5'd12: mound_lut_val = 3'd2;
            5'd13, 5'd14, 5'd15: mound_lut_val = 3'd3;
            5'd16, 5'd17, 5'd18: mound_lut_val = 3'd4;
            5'd19, 5'd20, 5'd21: mound_lut_val = 3'd5;
            default: mound_lut_val = 3'd6;
        endcase
    end
endfunction

wire [10:0] temp_x = pix_x + scroll_counter - MOUND_X0;
wire [10:0] mound_x = (temp_x >= H_RES) ? (temp_x - H_RES) : temp_x;
wire in_mound_region = (mound_x < MOUND_W);
wire [10:0] mound_index_a = (mound_x < HALF_MOUND_W) ? mound_x : (MOUND_W-1 - mound_x);
wire [4:0] mound_index = mound_index_a[4:0];
wire [2:0] mound_val = mound_lut_val(mound_index); // function input already 5 bits
wire [9:0] ground_y_for_x = in_mound_region ? (GROUND_Y - {{7{1'b0}}, mound_val}) : GROUND_Y;
wire is_ground_line = (pix_y == ground_y_for_x);

// ---- Ground Dots, Scrolling ----
wire [10:0] scroll_x = pix_x + scroll_counter;
wire [10:0] tmp16 = scroll_x - 11'd16;
wire [10:0] tmp8  = scroll_x - 11'd8;
wire [10:0] tmp22 = scroll_x - 11'd22;
wire [10:0] tmp11 = scroll_x - 11'd11;
wire [10:0] tmp34 = scroll_x - 11'd34;
wire [10:0] tmp17 = scroll_x - 11'd17;

wire [3:0] mod8  = (scroll_x >= 16) ? tmp16[3:0] :
                   (scroll_x >= 8)  ? tmp8[3:0]  :
                                      scroll_x[3:0];

wire [3:0] mod11 = (scroll_x >= 22) ? tmp22[3:0] :
                   (scroll_x >= 11) ? tmp11[3:0] :
                                      scroll_x[3:0];

wire [4:0] mod17 = (scroll_x >= 34) ? tmp34[4:0] :
                   (scroll_x >= 17) ? tmp17[4:0] :
                                      scroll_x[4:0];
wire is_ground_dot =
     (pix_y > ground_y_for_x) && (pix_y <= ground_y_for_x + 8) &&
     ((mod8  == 2 && pix_y == ground_y_for_x+3)  ||
      (mod11 == 4 && pix_y == ground_y_for_x+5)  ||
      (mod17 == 9 && pix_y == ground_y_for_x+7));

// =================== Clouds (Spread for XGA) ===================
localparam CLOUD_W = 20, CLOUD_H = 8, CLOUD_SCALE = 2;

function [CLOUD_W-1:0] get_cloud_sprite_line;
    input [2:0] y;
    begin
        case (y)
            3'd0: get_cloud_sprite_line = 20'b00000001111000000000;
            3'd1: get_cloud_sprite_line = 20'b00000111111100000000;
            3'd2: get_cloud_sprite_line = 20'b00011111111110000000;
            3'd3: get_cloud_sprite_line = 20'b00111111111111000000;
            3'd4: get_cloud_sprite_line = 20'b01111111111111100000;
            3'd5: get_cloud_sprite_line = 20'b00111111111111000000;
            3'd6: get_cloud_sprite_line = 20'b00011111111110000000;
            3'd7: get_cloud_sprite_line = 20'b00000111111100000000;
            default: get_cloud_sprite_line = 20'b0;
        endcase
    end
endfunction

localparam C1_Y_OFFSET = (DISPLAY_MODE == 0) ? 260 : 416;
localparam C2_Y_OFFSET = (DISPLAY_MODE == 0) ? 300 : 480;
localparam C1_X_BASE   = (DISPLAY_MODE == 0) ? 140 : 280;
localparam C2_X_BASE   = (DISPLAY_MODE == 0) ? 340 : 640;

localparam C1_Y = GROUND_Y - C1_Y_OFFSET;
localparam C2_Y = GROUND_Y - C2_Y_OFFSET;
wire [10:0] temp_c1_x = C1_X_BASE + H_RES - (scroll_counter >> 1);
wire [10:0]  c1_x = (temp_c1_x >= H_RES) ? (temp_c1_x - H_RES) : temp_c1_x;
wire [10:0] temp_c2_x = C2_X_BASE + H_RES - (scroll_counter >> 1);
wire [10:0]  c2_x = (temp_c2_x >= H_RES) ? (temp_c2_x - H_RES) : temp_c2_x;

wire in_cloud1_box = (pix_x >= c1_x) && (pix_x < c1_x + CLOUD_W*CLOUD_SCALE) &&
                     (pix_y >= C1_Y) && (pix_y < C1_Y + CLOUD_H*CLOUD_SCALE);
wire in_cloud2_box = (pix_x >= c2_x) && (pix_x < c2_x + CLOUD_W*CLOUD_SCALE) &&
                     (pix_y >= C2_Y) && (pix_y < C2_Y + CLOUD_H*CLOUD_SCALE);

wire [10:0] c1_local_x = pix_x - c1_x;
wire [10:0] c1_local_y = pix_y - C1_Y;
wire [10:0] c2_local_x = pix_x - c2_x;
wire [10:0] c2_local_y = pix_y - C2_Y;

wire [10:0] c1_sprite_x = c1_local_x >> 1; // CLOUD_SCALE = 2
wire [10:0] c1_sprite_y = c1_local_y >> 1;
wire [10:0] c2_sprite_x = c2_local_x >> 1;
wire [10:0] c2_sprite_y = c2_local_y >> 1;

wire [CLOUD_W-1:0] cloud_sprite_line  = get_cloud_sprite_line(c1_sprite_y[2:0]);
wire [CLOUD_W-1:0] cloud_sprite_line2 = get_cloud_sprite_line(c2_sprite_y[2:0]);

wire is_cloud1 = in_cloud1_box && cloud_sprite_line[CLOUD_W-1-c1_sprite_x];
wire is_cloud2 = in_cloud2_box && cloud_sprite_line2[CLOUD_W-1-c2_sprite_x];
wire is_cloud  = is_cloud1 || is_cloud2;

// =================== Stars ===================

localparam STAR_SIZE = 2;


localparam STAR_X0  = (DISPLAY_MODE == 0) ?  27 :  43 ;
localparam STAR_Y0  = (DISPLAY_MODE == 0) ? 300 : 480 ;
localparam STAR_X1  = (DISPLAY_MODE == 0) ? 110 : 176 ;
localparam STAR_Y1  = (DISPLAY_MODE == 0) ? 300 : 480 ;
localparam STAR_X2  = (DISPLAY_MODE == 0) ? 154 : 246 ;
localparam STAR_Y2  = (DISPLAY_MODE == 0) ? 275 : 440 ;
localparam STAR_X3  = (DISPLAY_MODE == 0) ? 205 : 328 ;
localparam STAR_Y3  = (DISPLAY_MODE == 0) ? 265 : 424 ;
localparam STAR_X4  = (DISPLAY_MODE == 0) ? 270 : 432 ;
localparam STAR_Y4  = (DISPLAY_MODE == 0) ? 255 : 408 ;
localparam STAR_X5  = (DISPLAY_MODE == 0) ? 302 : 483 ;
localparam STAR_Y5  = (DISPLAY_MODE == 0) ? 245 : 392 ;
localparam STAR_X6  = (DISPLAY_MODE == 0) ? 420 : 672 ;
localparam STAR_Y6  = (DISPLAY_MODE == 0) ? 235 : 376 ;
localparam STAR_X7  = (DISPLAY_MODE == 0) ? 396 : 634 ;
localparam STAR_Y7  = (DISPLAY_MODE == 0) ? 220 : 352 ;
localparam STAR_X8  = (DISPLAY_MODE == 0) ? 100 : 160 ;
localparam STAR_Y8  = (DISPLAY_MODE == 0) ? 355 : 568 ;
localparam STAR_X9  = (DISPLAY_MODE == 0) ? 130 : 208 ;
localparam STAR_Y9  = (DISPLAY_MODE == 0) ? 345 : 552 ;
localparam STAR_X10 = (DISPLAY_MODE == 0) ? 250 : 400 ;
localparam STAR_Y10 = (DISPLAY_MODE == 0) ? 335 : 536 ;
localparam STAR_X11 = (DISPLAY_MODE == 0) ? 360 : 576 ;
localparam STAR_Y11 = (DISPLAY_MODE == 0) ? 325 : 520 ;
localparam STAR_X12 = (DISPLAY_MODE == 0) ? 390 : 624 ;
localparam STAR_Y12 = (DISPLAY_MODE == 0) ? 315 : 504 ;
localparam STAR_X13 = (DISPLAY_MODE == 0) ? 480 : 768 ;
localparam STAR_Y13 = (DISPLAY_MODE == 0) ? 345 : 552 ;
localparam STAR_X14 = (DISPLAY_MODE == 0) ? 530 : 848 ;
localparam STAR_Y14 = (DISPLAY_MODE == 0) ? 295 : 472 ;
localparam STAR_X15 = (DISPLAY_MODE == 0) ? 605 : 968 ;
localparam STAR_Y15 = (DISPLAY_MODE == 0) ? 285 : 456 ;


// --- Star Twinkle ---

reg star_toggle;
always @(posedge vsync or negedge rst_n)
    if (!rst_n) star_toggle <= 0;
    else        star_toggle <= ~star_toggle;

// --- Star 'Plus' Logic ---

wire is_star_plus_0  = (((pix_x == STAR_X0 ) && (pix_y >= (GROUND_Y-STAR_Y0 -STAR_SIZE) && pix_y <= (GROUND_Y-STAR_Y0 +STAR_SIZE))) ||
                        ((pix_y == (GROUND_Y-STAR_Y0 )) && (pix_x >= (STAR_X0 -STAR_SIZE) && pix_x <= (STAR_X0 +STAR_SIZE))));
wire is_star_plus_1  = (((pix_x == STAR_X1 ) && (pix_y >= (GROUND_Y-STAR_Y1 -STAR_SIZE) && pix_y <= (GROUND_Y-STAR_Y1 +STAR_SIZE))) ||
                        ((pix_y == (GROUND_Y-STAR_Y1 )) && (pix_x >= (STAR_X1 -STAR_SIZE) && pix_x <= (STAR_X1 +STAR_SIZE))));
wire is_star_plus_2  = (((pix_x == STAR_X2 ) && (pix_y >= (GROUND_Y-STAR_Y2 -STAR_SIZE) && pix_y <= (GROUND_Y-STAR_Y2 +STAR_SIZE))) ||
                        ((pix_y == (GROUND_Y-STAR_Y2 )) && (pix_x >= (STAR_X2 -STAR_SIZE) && pix_x <= (STAR_X2 +STAR_SIZE))));
wire is_star_plus_3  = (((pix_x == STAR_X3 ) && (pix_y >= (GROUND_Y-STAR_Y3 -STAR_SIZE) && pix_y <= (GROUND_Y-STAR_Y3 +STAR_SIZE))) ||
                        ((pix_y == (GROUND_Y-STAR_Y3 )) && (pix_x >= (STAR_X3 -STAR_SIZE) && pix_x <= (STAR_X3 +STAR_SIZE))));
wire is_star_plus_4  = (((pix_x == STAR_X4 ) && (pix_y >= (GROUND_Y-STAR_Y4 -STAR_SIZE) && pix_y <= (GROUND_Y-STAR_Y4 +STAR_SIZE))) ||
                        ((pix_y == (GROUND_Y-STAR_Y4 )) && (pix_x >= (STAR_X4 -STAR_SIZE) && pix_x <= (STAR_X4 +STAR_SIZE))));
wire is_star_plus_5  = (((pix_x == STAR_X5 ) && (pix_y >= (GROUND_Y-STAR_Y5 -STAR_SIZE) && pix_y <= (GROUND_Y-STAR_Y5 +STAR_SIZE))) ||
                        ((pix_y == (GROUND_Y-STAR_Y5 )) && (pix_x >= (STAR_X5 -STAR_SIZE) && pix_x <= (STAR_X5 +STAR_SIZE))));
wire is_star_plus_6  = (((pix_x == STAR_X6 ) && (pix_y >= (GROUND_Y-STAR_Y6 -STAR_SIZE) && pix_y <= (GROUND_Y-STAR_Y6 +STAR_SIZE))) ||
                        ((pix_y == (GROUND_Y-STAR_Y6 )) && (pix_x >= (STAR_X6 -STAR_SIZE) && pix_x <= (STAR_X6 +STAR_SIZE))));
wire is_star_plus_7  = (((pix_x == STAR_X7 ) && (pix_y >= (GROUND_Y-STAR_Y7 -STAR_SIZE) && pix_y <= (GROUND_Y-STAR_Y7 +STAR_SIZE))) ||
                        ((pix_y == (GROUND_Y-STAR_Y7 )) && (pix_x >= (STAR_X7 -STAR_SIZE) && pix_x <= (STAR_X7 +STAR_SIZE))));
wire is_star_plus_8  = (((pix_x == STAR_X8 ) && (pix_y >= (GROUND_Y-STAR_Y8 -STAR_SIZE) && pix_y <= (GROUND_Y-STAR_Y8 +STAR_SIZE))) ||
                        ((pix_y == (GROUND_Y-STAR_Y8 )) && (pix_x >= (STAR_X8 -STAR_SIZE) && pix_x <= (STAR_X8 +STAR_SIZE))));
wire is_star_plus_9  = (((pix_x == STAR_X9 ) && (pix_y >= (GROUND_Y-STAR_Y9 -STAR_SIZE) && pix_y <= (GROUND_Y-STAR_Y9 +STAR_SIZE))) ||
                        ((pix_y == (GROUND_Y-STAR_Y9 )) && (pix_x >= (STAR_X9 -STAR_SIZE) && pix_x <= (STAR_X9 +STAR_SIZE))));
wire is_star_plus_10 = (((pix_x == STAR_X10) && (pix_y >= (GROUND_Y-STAR_Y10-STAR_SIZE) && pix_y <= (GROUND_Y-STAR_Y10+STAR_SIZE))) ||
                        ((pix_y == (GROUND_Y-STAR_Y10)) && (pix_x >= (STAR_X10-STAR_SIZE) && pix_x <= (STAR_X10+STAR_SIZE))));
wire is_star_plus_11 = (((pix_x == STAR_X11) && (pix_y >= (GROUND_Y-STAR_Y11-STAR_SIZE) && pix_y <= (GROUND_Y-STAR_Y11+STAR_SIZE))) ||
                        ((pix_y == (GROUND_Y-STAR_Y11)) && (pix_x >= (STAR_X11-STAR_SIZE) && pix_x <= (STAR_X11+STAR_SIZE))));
wire is_star_plus_12 = (((pix_x == STAR_X12) && (pix_y >= (GROUND_Y-STAR_Y12-STAR_SIZE) && pix_y <= (GROUND_Y-STAR_Y12+STAR_SIZE))) ||
                        ((pix_y == (GROUND_Y-STAR_Y12)) && (pix_x >= (STAR_X12-STAR_SIZE) && pix_x <= (STAR_X12+STAR_SIZE))));
wire is_star_plus_13 = (((pix_x == STAR_X13) && (pix_y >= (GROUND_Y-STAR_Y13-STAR_SIZE) && pix_y <= (GROUND_Y-STAR_Y13+STAR_SIZE))) ||
                        ((pix_y == (GROUND_Y-STAR_Y13)) && (pix_x >= (STAR_X13-STAR_SIZE) && pix_x <= (STAR_X13+STAR_SIZE))));
wire is_star_plus_14 = (((pix_x == STAR_X14) && (pix_y >= (GROUND_Y-STAR_Y14-STAR_SIZE) && pix_y <= (GROUND_Y-STAR_Y14+STAR_SIZE))) ||
                        ((pix_y == (GROUND_Y-STAR_Y14)) && (pix_x >= (STAR_X14-STAR_SIZE) && pix_x <= (STAR_X14+STAR_SIZE))));
wire is_star_plus_15 = (((pix_x == STAR_X15) && (pix_y >= (GROUND_Y-STAR_Y15-STAR_SIZE) && pix_y <= (GROUND_Y-STAR_Y15+STAR_SIZE))) ||
                        ((pix_y == (GROUND_Y-STAR_Y15)) && (pix_x >= (STAR_X15-STAR_SIZE) && pix_x <= (STAR_X15+STAR_SIZE))));

wire is_star_plus = is_star_plus_0  || is_star_plus_1  || is_star_plus_2  || is_star_plus_3 ||
                    is_star_plus_4  || is_star_plus_5  || is_star_plus_6  || is_star_plus_7 ||
                    is_star_plus_8  || is_star_plus_9  || is_star_plus_10 || is_star_plus_11 ||
                    is_star_plus_12 || is_star_plus_13 || is_star_plus_14 || is_star_plus_15 ;

// --- Star 'Cross' Logic ---

wire is_star_cross_0  = (((pix_x-STAR_X0 ) == (pix_y-(GROUND_Y-STAR_Y0 )) && (pix_x >= STAR_X0 -STAR_SIZE && pix_x <= STAR_X0 +STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y0 )-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y0 )+STAR_SIZE)) ||
                        ((pix_x-STAR_X0 ) ==-(pix_y-(GROUND_Y-STAR_Y0 )) && (pix_x >= STAR_X0 -STAR_SIZE && pix_x <= STAR_X0 +STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y0 )-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y0 )+STAR_SIZE)));
wire is_star_cross_1  = (((pix_x-STAR_X1 ) == (pix_y-(GROUND_Y-STAR_Y1 )) && (pix_x >= STAR_X1 -STAR_SIZE && pix_x <= STAR_X1 +STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y1 )-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y1 )+STAR_SIZE)) ||
                        ((pix_x-STAR_X1 ) ==-(pix_y-(GROUND_Y-STAR_Y1 )) && (pix_x >= STAR_X1 -STAR_SIZE && pix_x <= STAR_X1 +STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y1 )-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y1 )+STAR_SIZE)));
wire is_star_cross_2  = (((pix_x-STAR_X2 ) == (pix_y-(GROUND_Y-STAR_Y2 )) && (pix_x >= STAR_X2 -STAR_SIZE && pix_x <= STAR_X2 +STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y2 )-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y2 )+STAR_SIZE)) ||
                        ((pix_x-STAR_X2 ) ==-(pix_y-(GROUND_Y-STAR_Y2 )) && (pix_x >= STAR_X2 -STAR_SIZE && pix_x <= STAR_X2 +STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y2 )-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y2 )+STAR_SIZE)));
wire is_star_cross_3  = (((pix_x-STAR_X3 ) == (pix_y-(GROUND_Y-STAR_Y3 )) && (pix_x >= STAR_X3 -STAR_SIZE && pix_x <= STAR_X3 +STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y3 )-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y3 )+STAR_SIZE)) ||
                        ((pix_x-STAR_X3 ) ==-(pix_y-(GROUND_Y-STAR_Y3 )) && (pix_x >= STAR_X3 -STAR_SIZE && pix_x <= STAR_X3 +STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y3 )-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y3 )+STAR_SIZE)));
wire is_star_cross_4  = (((pix_x-STAR_X4 ) == (pix_y-(GROUND_Y-STAR_Y4 )) && (pix_x >= STAR_X4 -STAR_SIZE && pix_x <= STAR_X4 +STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y4 )-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y4 )+STAR_SIZE)) ||
                        ((pix_x-STAR_X4 ) ==-(pix_y-(GROUND_Y-STAR_Y4 )) && (pix_x >= STAR_X4 -STAR_SIZE && pix_x <= STAR_X4 +STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y4 )-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y4 )+STAR_SIZE)));
wire is_star_cross_5  = (((pix_x-STAR_X5 ) == (pix_y-(GROUND_Y-STAR_Y5 )) && (pix_x >= STAR_X5 -STAR_SIZE && pix_x <= STAR_X5 +STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y5 )-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y5 )+STAR_SIZE)) ||
                        ((pix_x-STAR_X5 ) ==-(pix_y-(GROUND_Y-STAR_Y5 )) && (pix_x >= STAR_X5 -STAR_SIZE && pix_x <= STAR_X5 +STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y5 )-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y5 )+STAR_SIZE)));
wire is_star_cross_6  = (((pix_x-STAR_X6 ) == (pix_y-(GROUND_Y-STAR_Y6 )) && (pix_x >= STAR_X6 -STAR_SIZE && pix_x <= STAR_X6 +STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y6 )-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y6 )+STAR_SIZE)) ||
                        ((pix_x-STAR_X6 ) ==-(pix_y-(GROUND_Y-STAR_Y6 )) && (pix_x >= STAR_X6 -STAR_SIZE && pix_x <= STAR_X6 +STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y6 )-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y6 )+STAR_SIZE)));
wire is_star_cross_7  = (((pix_x-STAR_X7 ) == (pix_y-(GROUND_Y-STAR_Y7 )) && (pix_x >= STAR_X7 -STAR_SIZE && pix_x <= STAR_X7 +STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y7 )-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y7 )+STAR_SIZE)) ||
                        ((pix_x-STAR_X7 ) ==-(pix_y-(GROUND_Y-STAR_Y7 )) && (pix_x >= STAR_X7 -STAR_SIZE && pix_x <= STAR_X7 +STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y7 )-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y7 )+STAR_SIZE)));
wire is_star_cross_8  = (((pix_x-STAR_X8 ) == (pix_y-(GROUND_Y-STAR_Y8 )) && (pix_x >= STAR_X8 -STAR_SIZE && pix_x <= STAR_X8 +STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y8 )-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y8 )+STAR_SIZE)) ||
                        ((pix_x-STAR_X8 ) ==-(pix_y-(GROUND_Y-STAR_Y8 )) && (pix_x >= STAR_X8 -STAR_SIZE && pix_x <= STAR_X8 +STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y8 )-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y8 )+STAR_SIZE)));
wire is_star_cross_9  = (((pix_x-STAR_X9 ) == (pix_y-(GROUND_Y-STAR_Y9 )) && (pix_x >= STAR_X9 -STAR_SIZE && pix_x <= STAR_X9 +STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y9 )-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y9 )+STAR_SIZE)) ||
                        ((pix_x-STAR_X9 ) ==-(pix_y-(GROUND_Y-STAR_Y9 )) && (pix_x >= STAR_X9 -STAR_SIZE && pix_x <= STAR_X9 +STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y9 )-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y9 )+STAR_SIZE)));
wire is_star_cross_10 = (((pix_x-STAR_X10) == (pix_y-(GROUND_Y-STAR_Y10)) && (pix_x >= STAR_X10-STAR_SIZE && pix_x <= STAR_X10+STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y10)-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y10)+STAR_SIZE)) ||
                        ((pix_x-STAR_X10) ==-(pix_y-(GROUND_Y-STAR_Y10)) && (pix_x >= STAR_X10-STAR_SIZE && pix_x <= STAR_X10+STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y10)-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y10)+STAR_SIZE)));
wire is_star_cross_11 = (((pix_x-STAR_X11) == (pix_y-(GROUND_Y-STAR_Y11)) && (pix_x >= STAR_X11-STAR_SIZE && pix_x <= STAR_X11+STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y11)-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y11)+STAR_SIZE)) ||
                        ((pix_x-STAR_X11) ==-(pix_y-(GROUND_Y-STAR_Y11)) && (pix_x >= STAR_X11-STAR_SIZE && pix_x <= STAR_X11+STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y11)-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y11)+STAR_SIZE)));
wire is_star_cross_12 = (((pix_x-STAR_X12) == (pix_y-(GROUND_Y-STAR_Y12)) && (pix_x >= STAR_X12-STAR_SIZE && pix_x <= STAR_X12+STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y12)-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y12)+STAR_SIZE)) ||
                        ((pix_x-STAR_X12) ==-(pix_y-(GROUND_Y-STAR_Y12)) && (pix_x >= STAR_X12-STAR_SIZE && pix_x <= STAR_X12+STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y12)-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y12)+STAR_SIZE)));
wire is_star_cross_13 = (((pix_x-STAR_X13) == (pix_y-(GROUND_Y-STAR_Y13)) && (pix_x >= STAR_X13-STAR_SIZE && pix_x <= STAR_X13+STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y13)-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y13)+STAR_SIZE)) ||
                        ((pix_x-STAR_X13) ==-(pix_y-(GROUND_Y-STAR_Y13)) && (pix_x >= STAR_X13-STAR_SIZE && pix_x <= STAR_X13+STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y13)-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y13)+STAR_SIZE)));
wire is_star_cross_14 = (((pix_x-STAR_X14) == (pix_y-(GROUND_Y-STAR_Y14)) && (pix_x >= STAR_X14-STAR_SIZE && pix_x <= STAR_X14+STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y14)-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y14)+STAR_SIZE)) ||
                        ((pix_x-STAR_X14) ==-(pix_y-(GROUND_Y-STAR_Y14)) && (pix_x >= STAR_X14-STAR_SIZE && pix_x <= STAR_X14+STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y14)-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y14)+STAR_SIZE)));
wire is_star_cross_15 = (((pix_x-STAR_X15) == (pix_y-(GROUND_Y-STAR_Y15)) && (pix_x >= STAR_X15-STAR_SIZE && pix_x <= STAR_X15+STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y15)-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y15)+STAR_SIZE)) ||
                        ((pix_x-STAR_X15) ==-(pix_y-(GROUND_Y-STAR_Y15)) && (pix_x >= STAR_X15-STAR_SIZE && pix_x <= STAR_X15+STAR_SIZE) && (pix_y >= (GROUND_Y-STAR_Y15)-STAR_SIZE && pix_y <= (GROUND_Y-STAR_Y15)+STAR_SIZE)));

wire is_star_cross = is_star_cross_0  || is_star_cross_1  || is_star_cross_2  || is_star_cross_3  ||
                     is_star_cross_4  || is_star_cross_5  || is_star_cross_6  || is_star_cross_7  ||
                     is_star_cross_8  || is_star_cross_9  || is_star_cross_10 || is_star_cross_11 ||
                     is_star_cross_12 || is_star_cross_13 || is_star_cross_14 || is_star_cross_15 ;

wire is_star = star_toggle ? is_star_plus : is_star_cross;


//---------------------- Final Output ------------------------------
assign R = (!video_active)                ? 2'b00 :
            (is_ground_line  && bg_en)     ? 2'b11 :
            (is_ground_dot   && bg_en)     ? 2'b11 :
            (is_cloud        && bg_en)     ? 2'b11 :
            (is_star         && bg_en)     ? 2'b11 :
            2'b00;
assign G = R;
assign B = R;

endmodule
