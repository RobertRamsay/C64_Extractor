/// @desc Draw all panels (GUI layer, scaled for high-DPI screens)

draw_set_halign(fa_left);
draw_set_valign(fa_top);

if (map_dirty || !surface_exists(map_surf)) {
    scr_ext_build_map();
    gfx_dirty = true;
}

// ---- Background and toolbar ----
draw_set_colour(col_bg);
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_colour(col_panel);
draw_rectangle(0, 0, gui_w, top_h, false);
draw_set_colour(col_text);
draw_text(ui_pad, 12, "C64 EXTRACTOR");

for (var _i = 0; _i < array_length(buttons); _i++) {
    scr_ext_draw_button(buttons[_i], false);
}
draw_set_colour(col_dim);
draw_text(970, 12, "J: next VIC clue   Shift+drag: select   W: region   B/E: sel begin/end   Esc: clear   1-6: modes   F: follow   G: grid");

// ---- Memory map ----
var _map_size = 256 * map_scale;
scr_ext_panel(map_x, map_y, _map_size, _map_size, "MEMORY MAP   one row = one page ($100 bytes)");
draw_surface_ext(map_surf, map_x, map_y, map_scale, map_scale, 0, c_white, 1);

// Tick marks every $1000
draw_set_colour(col_dim);
for (var _pg = 0; _pg < 16; _pg++) {
    var _ly = map_y + _pg * 16 * map_scale;
    draw_line(map_x - 6, _ly, map_x - 1, _ly);
}

// Hex view range bracket (left) and graphics viewer range bracket (right)
var _hy1 = map_y + (hex_top >> 8) * map_scale;
var _hy2 = map_y + (((hex_top + hex_rows * 8 - 1) & 0xFFFF) >> 8) * map_scale + map_scale;
draw_set_colour(col_dim);
draw_rectangle(map_x - 12, _hy1, map_x - 9, _hy2, false);

var _g1 = gfx_addr;
var _g2 = gfx_addr + gfx_screen_bytes - 1;
if (_g2 > 0xFFFF) {
    _g2 = 0xFFFF;
}
draw_set_colour(col_gfx_range);
draw_rectangle(map_x + _map_size + 3, map_y + (_g1 >> 8) * map_scale, map_x + _map_size + 6, map_y + (_g2 >> 8) * map_scale + map_scale, false);

// Selection overlay
if (sel_active) {
    draw_set_alpha(0.45);
    draw_set_colour(c_white);
    var _p1 = sel_start >> 8;
    var _p2 = sel_end >> 8;
    for (var _pg2 = _p1; _pg2 <= _p2; _pg2++) {
        var _x1 = 0;
        var _x2 = 255;
        if (_pg2 == _p1) {
            _x1 = sel_start & 0xFF;
        }
        if (_pg2 == _p2) {
            _x2 = sel_end & 0xFF;
        }
        draw_rectangle(map_x + _x1 * map_scale, map_y + _pg2 * map_scale, map_x + (_x2 + 1) * map_scale - 1, map_y + (_pg2 + 1) * map_scale - 1, false);
    }
    draw_set_alpha(1);
}

// Cursor marker
var _cx = map_x + (cursor_addr & 0xFF) * map_scale;
var _cy = map_y + (cursor_addr >> 8) * map_scale;
draw_set_colour(c_white);
draw_rectangle(_cx - 2, _cy - 2, _cx + map_scale + 1, _cy + map_scale + 1, true);

// ---- Graphics viewer ----
scr_ext_gfx_draw();

// ---- Hex view ----
scr_ext_panel(hex_x, hex_y, hex_w, hex_h, "HEX");
for (var _r = 0; _r < hex_rows; _r++) {
    var _base = (hex_top + _r * 8) & 0xFFFF;
    var _ly2 = hex_y + _r * line_h;
    draw_set_colour(col_dim);
    draw_text(hex_x + 2, _ly2, scr_ext_hex(_base, 4));
    var _ascii = "";
    for (var _j = 0; _j < 8; _j++) {
        var _a = (_base + _j) & 0xFFFF;
        var _c = buffer_peek(cls_buf, _a, buffer_u8);
        var _bx = hex_x + 52 + _j * 26;
        if (sel_active && _a >= sel_start && _a <= sel_end) {
            draw_set_colour(col_sel);
            draw_rectangle(_bx - 3, _ly2, _bx + 22, _ly2 + line_h - 1, false);
        }
        if (_a == cursor_addr) {
            draw_set_colour(col_cursor);
            draw_rectangle(_bx - 3, _ly2, _bx + 19, _ly2 + line_h - 1, false);
        }
        if (_c == EXT_CLS_NONE) {
            draw_set_colour(col_border);
            draw_text(_bx, _ly2, "--");
            _ascii += " ";
        }
        else {
            var _v = buffer_peek(mem_buf, _a, buffer_u8);
            draw_set_colour(scr_ext_cls_colour(_c));
            draw_text(_bx, _ly2, scr_ext_hex(_v, 2));
            _ascii += scr_ext_petscii_char(_v);
        }
    }
    draw_set_colour(col_text);
    draw_text(hex_x + 52 + 8 * 26 + 10, _ly2, _ascii);
}
sb_hex.value = hex_top div 8;
scr_ext_sb_draw(sb_hex);

// ---- Disassembly view ----
scr_ext_panel(dis_x, dis_y, dis_w, dis_h, "DISASSEMBLY");
var _da = dis_top;
for (var _r = 0; _r < dis_rows; _r++) {
    var _line = scr_ext_disasm_line(_da);
    dis_line_addrs[_r] = _da;
    var _dy = dis_y + _r * line_h;
    if (sel_active && _da >= sel_start && _da <= sel_end) {
        draw_set_colour(col_sel);
        draw_rectangle(dis_x - 4, _dy, dis_x + dis_w - EXT_SB_W - 6, _dy + line_h - 1, false);
    }
    if (cursor_addr >= _da && cursor_addr < _da + _line.size) {
        draw_set_colour(col_cursor);
        draw_rectangle(dis_x - 4, _dy, dis_x + dis_w - EXT_SB_W - 6, _dy + line_h - 1, false);
    }
    if (_line.entry) {
        draw_set_colour(col_entry);
        draw_text(dis_x, _dy, ">");
    }
    draw_set_colour(col_dim);
    draw_text(dis_x + 12, _dy, scr_ext_hex(_da, 4));
    draw_text(dis_x + 60, _dy, _line.bytes);
    if (_line.cls == EXT_CLS_NONE) {
        draw_set_colour(col_dim);
    }
    else {
        draw_set_colour(scr_ext_cls_colour(_line.cls));
    }
    draw_text(dis_x + 150, _dy, _line.text);
    _da = (_da + _line.size) & 0xFFFF;
}
sb_dis.value = dis_top;
scr_ext_sb_draw(sb_dis);

// ---- D64 directory ----
scr_ext_panel(dir_x, dir_y, dir_w, dir_h, "D64 DIRECTORY   click = load, Shift+click = overlay");
draw_set_colour(col_text);
if (buffer_exists(d64_buf)) {
    draw_text(dir_x + 4, dir_y, "\"" + d64_disk_name + "\"   " + string(array_length(d64_files)) + " files");
}
else {
    draw_set_colour(col_dim);
    draw_text(dir_x + 4, dir_y, "No D64 open");
}
for (var _r = 0; _r < dir_rows; _r++) {
    var _idx = d64_scroll + _r;
    if (_idx >= array_length(d64_files)) {
        break;
    }
    var _f = d64_files[_idx];
    var _fy = dir_y + (_r + 1) * line_h;
    if (_idx == d64_selected) {
        draw_set_colour(col_cursor);
        draw_rectangle(dir_x, _fy, dir_x + dir_w - EXT_SB_W - 6, _fy + line_h - 1, false);
    }
    if (_f.type == 2) {
        draw_set_colour(col_text);
    }
    else {
        draw_set_colour(col_dim);
    }
    draw_text(dir_x + 4, _fy, string(_f.blocks));
    draw_text(dir_x + 40, _fy, "\"" + _f.name + "\"");
    draw_text(dir_x + 196, _fy, _f.typename);
    if (_f.load >= 0) {
        draw_text(dir_x + 236, _fy, "$" + scr_ext_hex(_f.load, 4) + "-$" + scr_ext_hex(_f.finish, 4));
    }
    if (_f.sys >= 0) {
        draw_set_colour(scr_ext_cls_colour(EXT_CLS_SURE));
        draw_text(dir_x + 346, _fy, "SYS" + string(_f.sys));
    }
    if (_f.packed) {
        draw_set_colour(scr_ext_cls_colour(EXT_CLS_PACKED));
        draw_text(dir_x + 420, _fy, "PACKED");
    }
}
scr_ext_sb_draw(sb_dir);

// ---- Info panel ----
scr_ext_panel(info_x, info_y, info_w, info_h, "INFO");

var _legend_w = 230;
var _tw = info_w - _legend_w - 24;     // text column width; long lines wrap inside it
var _iy = info_y;

draw_set_colour(col_text);
draw_text_ext(info_x, _iy, status_text, line_h, _tw);
_iy += string_height_ext(status_text, line_h, _tw);

if (verdict_text != "") {
    draw_set_colour(scr_ext_cls_colour(EXT_CLS_LIKELY));
    draw_text_ext(info_x, _iy, verdict_text, line_h, _tw);
    _iy += string_height_ext(verdict_text, line_h, _tw);
}

draw_set_colour(col_dim);
if (file_name != "") {
    var _file_text = file_name + "   [" + file_kind + "]";
    draw_text_ext(info_x, _iy, _file_text, line_h, _tw);
    _iy += string_height_ext(_file_text, line_h, _tw);
}

var _seg_text = "Loaded:";
var _seg_n = array_length(segments);
for (var _s = 0; _s < _seg_n && _s < 3; _s++) {
    var _seg = segments[_s];
    _seg_text += "  $" + scr_ext_hex(_seg.start, 4) + "-$" + scr_ext_hex(_seg.finish, 4);
}
if (_seg_n > 3) {
    _seg_text += "  (+" + string(_seg_n - 3) + " more)";
}
draw_text_ext(info_x, _iy, _seg_text, line_h, _tw);
_iy += string_height_ext(_seg_text, line_h, _tw);

var _ent_text = "Entries:";
var _ent_n = array_length(entries);
for (var _e = 0; _e < _ent_n && _e < 3; _e++) {
    var _en = entries[_e];
    _ent_text += "  $" + scr_ext_hex(_en.addr, 4) + " (" + _en.why + ")";
}
if (_ent_n > 3) {
    _ent_text += "  (+" + string(_ent_n - 3) + " more)";
}
if (_ent_n == 0) {
    _ent_text += "  none - put the cursor on code and press C";
}
draw_text_ext(info_x, _iy, _ent_text, line_h, _tw);
_iy += string_height_ext(_ent_text, line_h, _tw);

if (sel_active) {
    var _sel_text = "Selection $" + scr_ext_hex(sel_start, 4) + "-$" + scr_ext_hex(sel_end, 4) + "  (" + string(sel_end - sel_start + 1) + " bytes)   X = export";
    draw_set_colour(col_text);
    draw_text_ext(info_x, _iy, _sel_text, line_h, _tw);
    _iy += string_height_ext(_sel_text, line_h, _tw);
}

draw_set_colour(col_text);
draw_text(info_x, _iy, "Cursor $" + scr_ext_hex(cursor_addr, 4) + "  value $" + scr_ext_hex(buffer_peek(mem_buf, cursor_addr, buffer_u8), 2) + "  " + scr_ext_cls_name(buffer_peek(cls_buf, cursor_addr, buffer_u8)));
_iy += line_h;
if (hover_addr >= 0) {
    draw_set_colour(col_dim);
    draw_text(info_x, _iy, "Hover  $" + scr_ext_hex(hover_addr, 4) + "  value $" + scr_ext_hex(buffer_peek(mem_buf, hover_addr, buffer_u8), 2) + "  " + scr_ext_cls_name(buffer_peek(cls_buf, hover_addr, buffer_u8)));
}

// Legend with byte counts, on the right of the info panel
var _lx = info_x + info_w - _legend_w;
for (var _c2 = 0; _c2 < EXT_CLS_COUNT; _c2++) {
    var _row_y = info_y + _c2 * line_h;
    draw_set_colour(scr_ext_cls_colour(_c2));
    draw_rectangle(_lx, _row_y + 3, _lx + 9, _row_y + 12, false);
    draw_set_colour(col_dim);
    draw_text(_lx + 16, _row_y, scr_ext_cls_name(_c2));
    draw_text(_lx + 160, _row_y, string(cls_counts[_c2]));
}

draw_set_colour(c_white);
