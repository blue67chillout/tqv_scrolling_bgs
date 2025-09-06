/// add mario background here

module bg_pixel_mario(
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

    //1024x768 (XGA)

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

    //----------------------------- Clouds ------------------------------
    localparam CLOUD_W = 20, CLOUD_H = 8, CLOUD_SCALE = 4;

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

    localparam C1_Y_OFFSET = 400;
    localparam C2_Y_OFFSET = 448;
    localparam C1_X_BASE   = 280;
    localparam C2_X_BASE   = 640;

    localparam C1_Y = GROUND_Y - C1_Y_OFFSET;
    localparam C2_Y = GROUND_Y - C2_Y_OFFSET;
    wire [10:0] temp_c1_x = C1_X_BASE + H_RES - (scroll_counter >> 1);
    wire [9:0]  c1_x = (temp_c1_x >= H_RES) ? (temp_c1_x - H_RES) : temp_c1_x;
    wire [10:0] temp_c2_x = C2_X_BASE + H_RES - (scroll_counter >> 1);
    wire [9:0]  c2_x = (temp_c2_x >= H_RES) ? (temp_c2_x - H_RES) : temp_c2_x;

    wire in_cloud1_box = (pix_x >= c1_x) && (pix_x < c1_x + CLOUD_W*CLOUD_SCALE) &&
                        (pix_y >= C1_Y) && (pix_y < C1_Y + CLOUD_H*CLOUD_SCALE);
    wire in_cloud2_box = (pix_x >= c2_x) && (pix_x < c2_x + CLOUD_W*CLOUD_SCALE) &&
                        (pix_y >= C2_Y) && (pix_y < C2_Y + CLOUD_H*CLOUD_SCALE);

    wire [9:0] c1_local_x = pix_x - c1_x;
    wire [9:0] c1_local_y = pix_y - C1_Y;
    wire [9:0] c2_local_x = pix_x - c2_x;
    wire [9:0] c2_local_y = pix_y - C2_Y;

    wire [4:0] c1_sprite_x = c1_local_x >> 2; // CLOUD_SCALE = 4
    wire [2:0] c1_sprite_y = c1_local_y >> 2;
    wire [4:0] c2_sprite_x = c2_local_x >> 2;
    wire [2:0] c2_sprite_y = c2_local_y >> 2;

    wire [CLOUD_W-1:0] cloud_sprite_line  = get_cloud_sprite_line(c1_sprite_y);
    wire [CLOUD_W-1:0] cloud_sprite_line2 = get_cloud_sprite_line(c2_sprite_y);

    wire is_cloud1 = in_cloud1_box && cloud_sprite_line[CLOUD_W-1-c1_sprite_x];
    wire is_cloud2 = in_cloud2_box && cloud_sprite_line2[CLOUD_W-1-c2_sprite_x];
    wire is_cloud  = is_cloud1 || is_cloud2;


    //----------------------------- Brick --------------------------------
    localparam BRICK_W = 8, BRICK_H = 8, BRICK_SCALE = 4;

    function [7:0] get_brick_sprite_line;
        input [2:0] row;
        begin
            case (row)
                3'd0: get_brick_sprite_line = 8'b11111010;
                3'd1: get_brick_sprite_line = 8'b11111010;
                3'd2: get_brick_sprite_line = 8'b11111000;
                3'd3: get_brick_sprite_line = 8'b11111010;
                3'd4: get_brick_sprite_line = 8'b00110010;
                3'd5: get_brick_sprite_line = 8'b10000110;
                3'd6: get_brick_sprite_line = 8'b11101110;
                3'd7: get_brick_sprite_line = 8'b00000000;
                default: get_brick_sprite_line = 8'b11111111;
            endcase
        end
    endfunction

    localparam TILE_W = BRICK_W * BRICK_SCALE;
    localparam TILE_H = BRICK_H * BRICK_SCALE;

    wire in_ground = (pix_y >= GROUND_Y);

    wire [9:0] local_x = (pix_x % TILE_W) / BRICK_SCALE;
    wire [9:0] local_y = ((pix_y - GROUND_Y) % TILE_H) / BRICK_SCALE;

    wire [BRICK_W-1:0] brick_line = get_brick_sprite_line(local_y[2:0]);
    wire is_brick_pixel = in_ground && brick_line[BRICK_W-1 - local_x[2:0]];

    // ------------------------Floating Brick ----------------------------
    localparam FBRICK_W = BRICK_W;
    localparam FBRICK_H = BRICK_H;
    localparam FBRICK_SCALE = BRICK_SCALE;

    localparam FBRICK_X = 240;

    localparam FBRICK_Y_OFFSET = 192;

    localparam FBRICK_Y = GROUND_Y - FBRICK_Y_OFFSET;

    wire in_fbrick_area = (pix_x >= FBRICK_X) &&
                          (pix_x < FBRICK_X + 5*FBRICK_W*FBRICK_SCALE) && 
                          (pix_y >= FBRICK_Y) &&
                          (pix_y < FBRICK_Y + FBRICK_H*FBRICK_SCALE);

    wire [9:0] fbrick_local_x = (pix_x - FBRICK_X) / FBRICK_SCALE;
    wire [9:0] fbrick_local_y = (pix_y - FBRICK_Y) / FBRICK_SCALE;

    wire [FBRICK_W-1:0] fbrick_line = get_brick_sprite_line(fbrick_local_y[2:0]);

    wire is_floating_brick = in_fbrick_area &&
                            fbrick_line[FBRICK_W-1 - (fbrick_local_x % FBRICK_W)];

    // ------------------------ Bush-------------------------------
    localparam BUSH_W     = 16;
    localparam BUSH_H     = 4;
    localparam BUSH_SCALE = 8;

    localparam BUSH_X = 384;
    localparam BUSH_Y = GROUND_Y - (BUSH_H * BUSH_SCALE);

    function [BUSH_W-1:0] get_bush_sprite_line;
        input [1:0] row;
        begin
            case (row)
                2'd0: get_bush_sprite_line = 16'b0000001111000000;
                2'd1: get_bush_sprite_line = 16'b0000011111100000;
                2'd2: get_bush_sprite_line = 16'b0000111111110000;
                2'd3: get_bush_sprite_line = 16'b0001111111111000;
                default: get_bush_sprite_line = 16'b0;
            endcase
        end
    endfunction

    wire in_bush_box = (pix_x >= BUSH_X) && (pix_x < BUSH_X + BUSH_W*BUSH_SCALE) &&
                      (pix_y >= BUSH_Y) && (pix_y < BUSH_Y + BUSH_H*BUSH_SCALE);
    wire [9:0] bush_x_full = pix_x - BUSH_X;
    wire [9:0] bush_y_full = pix_y - BUSH_Y;

    wire [4:0] bush_sprite_x  = bush_x_full / BUSH_SCALE;
    wire [1:0] bush_sprite_y  = (bush_y_full / BUSH_SCALE);
    wire [BUSH_W-1:0] bush_line_cur = get_bush_sprite_line(bush_sprite_y);
    wire bush_px  = in_bush_box && bush_line_cur[BUSH_W-1 - bush_sprite_x[3:0]];

    wire is_bush_fill   = bush_px;

    // ------------------------- Pipe ------------------------------
    localparam PIPE_X      = 832;

    localparam PIPE_Y_OFFSET = 104;
    localparam PIPE_Y      = GROUND_Y - PIPE_Y_OFFSET;

    localparam PIPE_W      = 64;
    localparam PIPE_H      = 64;
    localparam PIPE_CAP_H  = 12;
    localparam PIPE_CAP_W  = PIPE_W + 12;

    localparam PIPE_CAP_X  = PIPE_X - ((PIPE_CAP_W - PIPE_W) / 2);
    localparam PIPE_CAP_Y  = PIPE_Y - PIPE_CAP_H;

    wire in_pipe_stem = (pix_x >= PIPE_X) && (pix_x < PIPE_X + PIPE_W) &&
                        (pix_y >= PIPE_Y) && (pix_y < PIPE_Y + PIPE_H);

    wire in_pipe_cap = (pix_x >= PIPE_CAP_X) && (pix_x < PIPE_CAP_X + PIPE_CAP_W) &&
                      (pix_y >= PIPE_CAP_Y) && (pix_y < PIPE_Y);

    // wire stem_border_side = ((pix_x == PIPE_X) || (pix_x == PIPE_X + PIPE_W - 1)) &&
    //                         (pix_y >= PIPE_Y) && (pix_y < PIPE_Y + PIPE_H);

    // wire stem_border_top  = (pix_y == PIPE_Y) &&
    //                         (pix_x >= PIPE_X) && (pix_x < PIPE_X + PIPE_W);

    // wire cap_border_side  = ((pix_x == PIPE_CAP_X) || (pix_x == PIPE_CAP_X + PIPE_CAP_W - 1)) &&
    //                         (pix_y >= PIPE_CAP_Y) && (pix_y < PIPE_Y);

    // wire cap_border_top   = (pix_y == PIPE_CAP_Y) &&
    //                         (pix_x >= PIPE_CAP_X) && (pix_x < PIPE_CAP_X + PIPE_CAP_W);

    // wire is_pipe_border = stem_border_side || stem_border_top || cap_border_side || cap_border_top;
    wire is_pipe_fill = in_pipe_stem || in_pipe_cap;

    //------------------------------- Sun --------------------------------
    localparam SUN_X_OFFSET = 160;
    localparam SUN_X = H_RES - SUN_X_OFFSET;

    localparam SUN_Y_OFFSET = 128;
    localparam SUN_Y = SUN_Y_OFFSET;

    localparam SUN_R = 48;

    wire signed [11:0] dx = pix_x - SUN_X;
    wire signed [11:0] dy = pix_y - SUN_Y;
    wire [23:0] dist2 = dx*dx + dy*dy;
    wire [23:0] r2    = SUN_R * SUN_R;

    wire is_sun = (dist2 <= r2);

    //-------------------------------Brick bg ----------------------------

    // wire groud_brick_bg = (pix_y >= GROUND_Y);

    // localparam FLOAT_BRICK_Y_OFFSET = 5; 
    // localparam FLOAT_BRICK_X_OFFSET = 5; 

    // wire floating_brick_bg = ((pix_y >= FBRICK_Y) && (pix_y <= FBRICK_Y + 4*FBRICK_H - FLOAT_BRICK_Y_OFFSET) 
    //                         && (pix_x >= FBRICK_X) && (pix_x <= FBRICK_X - FLOAT_BRICK_X_OFFSET + 20*FBRICK_W));

    // wire brick_bg_black = groud_brick_bg || floating_brick_bg;

    //------------------------- Final Output -----------------------------
    assign R = (!video_active)      ? 2'b00 :
                is_pipe_fill        ? 2'b11 :
                is_bush_fill        ? 2'b11 :
                is_brick_pixel      ? 2'b11 :
                is_floating_brick   ? 2'b11 :
                is_cloud            ? 2'b11 :
                is_sun              ? 2'b11 :
                2'b00;

    assign G = R;

    assign B = R;

endmodule
