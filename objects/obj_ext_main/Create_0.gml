/// @desc C64 Extractor - main controller

// ---- 6502 decode table ----
global.ext_ops = scr_ext_opcode_table();

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

// ---- D64 state ----
d64_buf = -1;
d64_tracks = 35;
d64_disk_name = "";
d64_files = [];         // { name, type, typename, track, sector, blocks }
d64_selected = -1;
d64_scroll = 0;

// ---- Layout (room is 1366 x 768) ----
line_h = 14;

map_x = 12;
map_y = 48;
map_scale = 2;
map_surf = -1;
map_dirty = true;
map_shaded = false;

hex_x = 540;
hex_y = 48;
hex_w = 320;
hex_rows = 40;
hex_top = 0;

dis_x = 876;
dis_y = 48;
dis_w = 480;
dis_rows = 40;
dis_top = 0;
dis_line_addrs = array_create(dis_rows, 0);

dir_x = 12;
dir_y = 572;
dir_w = 512;
dir_rows = 12;

info_x = 540;
info_y = 626;

cursor_addr = 0;
hover_addr = -1;
status_text = "Press O to open a PRG, D64 or 64K memory dump. Hold Shift to overlay onto memory.";

// ---- Toolbar ----
buttons = [
    { bx : 300, by : 6, bw : 96,  bh : 24, label : "Open [O]",      action : "open" },
    { bx : 402, by : 6, bw : 150, bh : 24, label : "Trace cursor [C]", action : "trace" },
    { bx : 558, by : 6, bw : 110, bh : 24, label : "Analyse [R]",   action : "analyse" },
    { bx : 674, by : 6, bw : 110, bh : 24, label : "Shade map [V]", action : "shade" }
];

// ---- Colours ----
col_bg      = make_colour_rgb(10, 10, 14);
col_panel   = make_colour_rgb(24, 24, 32);
col_border  = make_colour_rgb(60, 60, 80);
col_text    = make_colour_rgb(210, 210, 220);
col_dim     = make_colour_rgb(120, 120, 140);
col_cursor  = make_colour_rgb(60, 60, 110);
col_entry   = make_colour_rgb(255, 255, 255);
col_button  = make_colour_rgb(40, 40, 58);
col_button_hi = make_colour_rgb(64, 64, 96);

scr_ext_reset_memory();
