module video_controller (
    clk,
    reset,
    enable,
    polarity,   // 0: negative syncs (VGA), 1: positive syncs (XGA/general)
    hsync,
    vsync,
    visible,
    pix_x,
    pix_y
);
  input clk;
  input reset;
  input enable;
  input polarity;
  output reg hsync, vsync;
  output visible;
  output reg [10:0] pix_x;
  output reg [10:0] pix_y;

// --- 1024x768 xGA Standard Parameters @ 65MHz ---
    parameter H_DISPLAY = 1024;   // visible area
    parameter H_FRONT   = 24;     // front porch
    parameter H_SYNC    = 136;    // sync pulse
    parameter H_BACK    = 160;    // back porch

    parameter V_DISPLAY = 768;    // visible area
    parameter V_FRONT   = 3;      // front porch
    parameter V_SYNC    = 6;      // sync pulse
    parameter V_BACK    = 29;     // back porch

  parameter H_SYNC_START = H_DISPLAY + H_FRONT;
  parameter H_SYNC_END   = H_DISPLAY + H_FRONT + H_SYNC - 1;
  parameter H_MAX        = H_DISPLAY + H_FRONT + H_SYNC + H_BACK - 1;

  parameter V_SYNC_START = V_DISPLAY + V_FRONT;
  parameter V_SYNC_END   = V_DISPLAY + V_FRONT + V_SYNC - 1;
  parameter V_MAX        = V_DISPLAY + V_FRONT + V_SYNC + V_BACK - 1;

  wire hmaxxed = (pix_x == H_MAX) || reset;
  wire vmaxxed = (pix_y == V_MAX) || reset;

  always @(posedge clk) begin
    if (!enable || reset) begin
      pix_x <= 0;
      hsync <= polarity ? 0 : 1;
    end
    else begin
      hsync <= polarity ?
                (pix_x >= H_SYNC_START && pix_x <= H_SYNC_END) :
                ~(pix_x >= H_SYNC_START && pix_x <= H_SYNC_END);
      if (hmaxxed) pix_x <= 0;
      else         pix_x <= pix_x + 1;
    end
  end

  always @(posedge clk) begin
    if (!enable || reset) begin
      pix_y <= 0;
      vsync <= polarity ? 0 : 1;
    end
    else begin
      vsync <= polarity ?
                (pix_y >= V_SYNC_START && pix_y <= V_SYNC_END) :
                ~(pix_y >= V_SYNC_START && pix_y <= V_SYNC_END);
      if (hmaxxed) begin
        if (vmaxxed)
          pix_y <= 0;
        else
          pix_y <= pix_y + 1;
      end
    end
  end

  assign visible = enable && (pix_x < H_DISPLAY) && (pix_y < V_DISPLAY);

endmodule


