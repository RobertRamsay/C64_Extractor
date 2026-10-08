/// @desc C64 Extractor - main controller

// ---- 6502 decode table ----
global.ext_ops = scr_ext_opcode_table();
global.ext_popcount = scr_ext_popcount_table();
scr_ext_cpu_tables();

// ---- Decrunch runner (bare 6502 over its own copy of RAM) ----
cpu_mem   = buffer_create(65536, buffer_fixed, 1);
cpu_w     = buffer_create(65536, buffer_fixed, 1);   // 1 = written by the unpacker
cpu_execd = buffer_create(65536, buffer_fixed, 1);   // 1 = executed since last written
cpu = scr_ext_cpu_new_state();
cpu_active = false;
cpu_entry = 0;
auto_unpack = true;

// ---- 64K C64 memory image and per-byte analysis buffers ----
mem_buf    = buffer_create(65536, buffer_fixed, 1);   // byte values
loaded_buf = buffer_create(65536, buffer_fixed, 1);   // 1 = byte came from a file
cls_buf    = buffer_create(65536, buffer_fixed, 1);   // EXT_CLS_* per byte
istart_buf = buffer_create(65536, buffer_fixed, 1);   // 1 = first byte of a decoded instruction
entry_buf  = buffer_create(65536, buffer_fixed, 1);   // 1 = entry point

// ---- File state ----
file_path = "";
file_name = "";
file_kind = "";
is_dump = false;
segments = [];          // { start, finish, name }
entries = [];           // { addr, strong, why }
manual_entries = [];    // addresses traced by hand with C
cls_counts = array_create(EXT_CLS_COUNT, 0);
vic_clues = [];          // { addr, len, kind, mode, why }
clue_index = -1;
verdict_text = "";

// ---- D64 state ----
d64_buf = -1;
d64_path = "";         // the open D64, remembered in project files
project_path = "";     // set by save / load: unpacks auto-save over it
autosave_timer = 0;    // frames left to show [autosaving]
d64_tracks = 35;
d64_disk_name = "";
d64_files = [];         // { name, type, typename, track, sector, blocks }
d64_selected = -1;
d64_scroll = 0;

// ---- Window / GUI scaling (set properly by scr_ext_update_window) ----
ui_scale = 1;
gui_w = 1366;
gui_h = 768;
last_win_w = 0;
last_win_h = 0;
full_window = true;       // borderless window covering the display
full_window_delay = 2;    // frames to wait before sizing the window
ui_pad = 14;
top_h = 40;
line_h = 15;
info_h = 180;
toolbar_help_x = 1240;
dis_text_off = 150;

// ---- Panel rectangles (filled in by scr_ext_layout) ----
map_x = 0;
map_y = 0;
map_scale = 2;
map_surf = -1;
map_dirty = true;
map_shaded = false;

hex_x = 0;
hex_y = 0;
hex_w = 0;
hex_h = 0;
hex_rows = 20;
hex_top = 0;

dis_x = 0;
dis_y = 0;
dis_w = 0;
dis_h = 0;
dis_rows = 20;
dis_top = 0;
dis_line_addrs = array_create(dis_rows, 0);

dir_x = 0;
dir_y = 0;
dir_w = 0;
dir_h = 0;
dir_rows = 8;

info_x = 0;
info_y = 0;
info_w = 0;

// ---- Graphics viewer ----
gfx_x = 0;
gfx_y = 0;
gfx_w = 0;
gfx_h = 0;
gfx_canvas_x = 0;
gfx_canvas_y = 0;
gfx_canvas_w = 256;
gfx_canvas_h = 256;
gfx_swatch_x = 0;
gfx_swatch_y = 0;
gfx_buttons = [];
gfx_mode = EXT_GFX_CHAR_HR;
gfx_addr = 0;
gfx_char_cols = 32;
gfx_spr_cols = 8;
gfx_follow = true;
gfx_grid = true;
gfx_col = [0, 11, 12, 1];     // BG, MC1, MC2, FG as C64 colour indices
gfx_cell_w = 8;
gfx_cell_h = 8;
gfx_cell_bytes = 8;
gfx_gap = 0;
gfx_align = 8;
gfx_row_bytes = 256;      // bytes per row of cells
gfx_phase = 0;            // gfx_addr mod gfx_row_bytes, only changed by Shift+wheel
gfx_row_cols = 32;
gfx_rows = 1;
gfx_zoom = 1;
gfx_img_w = 8;
gfx_img_h = 8;
gfx_screen_bytes = 8;
gfx_surf = -1;
gfx_buf = -1;
gfx_dirty = true;
gfx_zoom_lock = 0;
gfx_use_colour = false;     // bitmap modes: colours from screen RAM / colour data
gfx_scr_addr = -1;          // screen RAM (pairs 01/10, or HR ink/paper), -1 = none
gfx_col_addr = -1;          // colour RAM data (MC pair 11), -1 = none
gfx_colour_text_x = 0;
gfx_colour_text_y = 0;
gfx_nudge_text_x = 0;
gfx_nudge_text_y = 0;
gfx_repeat_index = -1;      // viewer button being held down (nudge auto-repeat)
gfx_repeat_timer = 0;
gfx_key_timer = 0;          // arrow-key auto-repeat over the viewer          // > 0 after the width handle is dragged
gfx_width_drag = false;
gfx_handle_hover = false;

c64_pal = scr_ext_c64_palette();
c64_pal_u32 = array_create(16, 0);
for (var _i = 0; _i < 16; _i++) {
    c64_pal_u32[_i] = scr_ext_rgba(c64_pal[_i][0], c64_pal[_i][1], c64_pal[_i][2]);
}
gfx_none_u32 = scr_ext_rgba(20, 20, 30);
gfx_gap_u32 = scr_ext_rgba(40, 40, 56);

// ---- Scroll bars ----
sb_hex = scr_ext_sb_create();
sb_dis = scr_ext_sb_create();
sb_dir = scr_ext_sb_create();
sb_gfx = scr_ext_sb_create();

// ---- Selection (inclusive range) ----
sel_active = false;
sel_dragging = false;
sel_anchor = 0;
sel_start = 0;
sel_end = 0;

cursor_addr = 0;
hover_addr = -1;
status_text = "Press O to open a PRG, D64 or 64K memory dump. Hold Shift to overlay onto memory.";

// ---- Toolbar ----
buttons = [
    { bx : 190, by : 8, bw : 96,  bh : 24, label : "Open [O]",         action : "open" },
    { bx : 292, by : 8, bw : 140, bh : 24, label : "Trace cursor [C]", action : "trace" },
    { bx : 438, by : 8, bw : 110, bh : 24, label : "Re-analyse [R]",   action : "analyse" },
    { bx : 554, by : 8, bw : 120, bh : 24, label : "Shade map [V]",    action : "shade" },
    { bx : 680, by : 8, bw : 130, bh : 24, label : "Fullscreen [F11]", action : "fullscreen" },
    { bx : 816, by : 8, bw : 140, bh : 24, label : "Export sel [X]",   action : "export" },
    { bx : 962, by : 8, bw : 110, bh : 24, label : "Unpack [U]",       action : "unpack" },
    { bx : 1078, by : 8, bw : 150, bh : 24, label : "Deselect [Ctrl+D]", action : "deselect" },
    { bx : 1234, by : 8, bw : 150, bh : 24, label : "Save project [Ctrl+S]", action : "saveproject" }
];

// ---- Colours ----
col_bg        = make_colour_rgb(10, 10, 14);
col_panel     = make_colour_rgb(24, 24, 32);
col_border    = make_colour_rgb(60, 60, 80);
col_text      = make_colour_rgb(210, 210, 220);
col_title     = make_colour_rgb(150, 160, 200);
col_dim       = make_colour_rgb(120, 120, 140);
col_cursor    = make_colour_rgb(60, 60, 110);
col_entry     = make_colour_rgb(255, 255, 255);
col_button    = make_colour_rgb(40, 40, 58);
col_button_hi = make_colour_rgb(64, 64, 96);
col_button_on = make_colour_rgb(50, 90, 150);
col_sb_track  = make_colour_rgb(16, 16, 22);
col_sb_thumb  = make_colour_rgb(80, 80, 110);
col_gfx_range = make_colour_rgb(60, 120, 230);
col_sel       = make_colour_rgb(70, 110, 70);

gpu_set_texfilter(false);
scr_ext_reset_memory();
scr_ext_update_window();
