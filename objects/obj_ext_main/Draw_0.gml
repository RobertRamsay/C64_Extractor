/// @desc Draw all panels

draw_set_halign(fa_left);
draw_set_valign(fa_top);

if (map_dirty || !surface_exists(map_surf)) {
    scr_ext_build_map();
}

// ---- Background and toolbar ----
draw_set_colour(col_bg);
draw_rectangle(0, 0, room_width, room_height, false);
draw_set_colour(col_panel);
draw_rectangle(0, 0, room_width, 36, false);
draw_set_colour(col_text);
draw_text(12, 11, "C64 EXTRACTOR");
draw_set_colour(col_dim);
draw_text(130, 11, "phase 1");

for (var _i = 0; _i < array_length(buttons); _i++) {
    var _b = buttons[_i];
    var _over = point_in_rectangle(mouse_x, mouse_y, _b.bx, _b.by, _b.bx + _b.bw, _b.by + _b.bh);
    if (_over) {
        draw_set_colour(col_button_hi);
    }
    else {
        draw_set_colour(col_button);
    }
    draw_rectangle(_b.bx, _b.by, _b.bx + _b.bw, _b.by + _b.bh, false);
    draw_set_colour(col_border);
    draw_rectangle(_b.bx, _b.by, _b.bx + _b.bw, _b.by + _b.bh, true);
    draw_set_colour(col_text);
    draw_text(_b.bx + 8, _b.by + 5, _b.label);
}
draw_set_colour(col_dim);
draw_text(800, 11, "Wheel scrolls panels   Up/Down/PgUp/PgDn: disassembly   Left/Right: cursor");

// ---- Memory map ----
var _map_size = 256 * map_scale;
draw_surface_ext(map_surf, map_x, map_y, map_scale, map_scale, 0, c_white, 1);
draw_set_colour(col_border);
draw_rectangle(map_x - 1, map_y - 1, map_x + _map_size, map_y + _map_size, true);

// Hex view range bracket on the left edge of the map
var _hy1 = map_y + (hex_top >> 8) * map_scale;
var _hy2 = map_y + (((hex_top + hex_rows * 8 - 1) & 0xFFFF) >> 8) * map_scale + map_scale;
draw_set_colour(col_dim);
draw_rectangle(map_x - 6, _hy1, map_x - 3, _hy2, false);

// Cursor marker
var _cx = map_x + (cursor_addr & 0xFF) * map_scale;
var _cy = map_y + (cursor_addr >> 8) * map_scale;
draw_set_colour(c_white);
draw_rectangle(_cx - 2, _cy - 2, _cx + map_scale + 1, _cy + map_scale + 1, true);

// ---- Hex view ----
draw_set_colour(col_panel);
draw_rectangle(hex_x - 6, hex_y - 6, hex_x + hex_w, hex_y + hex_rows * line_h + 2, false);
for (var _r = 0; _r < hex_rows; _r++) {
    var _base = (hex_top + _r * 8) & 0xFFFF;
    var _ly = hex_y + _r * line_h;
    draw_set_colour(col_dim);
    draw_text(hex_x, _ly, scr_ext_hex(_base, 4));
    var _ascii = "";
    for (var _j = 0; _j < 8; _j++) {
        var _a = (_base + _j) & 0xFFFF;
        var _c = buffer_peek(cls_buf, _a, buffer_u8);
        var _bx = hex_x + 48 + _j * 24;
        if (_a == cursor_addr) {
            draw_set_colour(col_cursor);
            draw_rectangle(_bx - 3, _ly, _bx + 18, _ly + line_h - 1, false);
        }
        if (_c == EXT_CLS_NONE) {
            draw_set_colour(col_border);
            draw_text(_bx, _ly, "--");
            _ascii += " ";
        }
        else {
            var _v = buffer_peek(mem_buf, _a, buffer_u8);
            draw_set_colour(scr_ext_cls_colour(_c));
            draw_text(_bx, _ly, scr_ext_hex(_v, 2));
            _ascii += scr_ext_petscii_char(_v);
        }
    }
    draw_set_colour(col_text);
    draw_text(hex_x + 48 + 8 * 24 + 8, _ly, _ascii);
}

// ---- Disassembly view ----
draw_set_colour(col_panel);
draw_rectangle(dis_x - 6, dis_y - 6, dis_x + dis_w, dis_y + dis_rows * line_h + 2, false);
var _da = dis_top;
for (var _r = 0; _r < dis_rows; _r++) {
    var _line = scr_ext_disasm_line(_da);
    dis_line_addrs[_r] = _da;
    var _dy = dis_y + _r * line_h;
    if (cursor_addr >= _da && cursor_addr < _da + _line.size) {
        draw_set_colour(col_cursor);
        draw_rectangle(dis_x - 4, _dy, dis_x + dis_w - 2, _dy + line_h - 1, false);
    }
    if (_line.entry) {
        draw_set_colour(col_entry);
        draw_text(dis_x, _dy, ">");
    }
    draw_set_colour(col_dim);
    draw_text(dis_x + 12, _dy, scr_ext_hex(_da, 4));
    draw_text(dis_x + 56, _dy, _line.bytes);
    if (_line.cls == EXT_CLS_NONE) {
        draw_set_colour(col_dim);
    }
    else {
        draw_set_colour(scr_ext_cls_colour(_line.cls));
    }
    draw_text(dis_x + 140, _dy, _line.text);
    _da = (_da + _line.size) & 0xFFFF;
}

// ---- D64 directory ----
var _dir_h = (dir_rows + 1) * line_h;
draw_set_colour(col_panel);
draw_rectangle(dir_x - 1, dir_y - 4, dir_x + dir_w, dir_y + _dir_h + 2, false);
draw_set_colour(col_text);
if (buffer_exists(d64_buf)) {
    draw_text(dir_x + 4, dir_y, "DISK \"" + d64_disk_name + "\"   " + string(array_length(d64_files)) + " files   (click = load, Shift+click = overlay)");
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
        draw_rectangle(dir_x, _fy, dir_x + dir_w - 1, _fy + line_h - 1, false);
    }
    if (_f.type == 2) {
        draw_set_colour(col_text);
    }
    else {
        draw_set_colour(col_dim);
    }
    draw_text(dir_x + 4, _fy, string(_f.blocks));
    draw_text(dir_x + 44, _fy, "\"" + _f.name + "\"");
    draw_text(dir_x + 220, _fy, _f.typename);
    draw_text(dir_x + 270, _fy, "T" + string(_f.track) + " S" + string(_f.sector));
}

// ---- Info panel ----
draw_set_colour(col_panel);
draw_rectangle(info_x - 6, info_y - 6, room_width - 10, room_height - 8, false);

var _iy = info_y;
draw_set_colour(col_text);
draw_text(info_x, _iy, status_text);
_iy += line_h;

draw_set_colour(col_dim);
if (file_name != "") {
    draw_text(info_x, _iy, file_name + "   [" + file_kind + "]");
}
_iy += line_h;

var _seg_text = "Loaded:";
var _seg_n = array_length(segments);
for (var _s = 0; _s < _seg_n && _s < 3; _s++) {
    var _seg = segments[_s];
    _seg_text += "  $" + scr_ext_hex(_seg.start, 4) + "-$" + scr_ext_hex(_seg.finish, 4);
}
if (_seg_n > 3) {
    _seg_text += "  (+" + string(_seg_n - 3) + " more)";
}
draw_text(info_x, _iy, _seg_text);
_iy += line_h;

var _ent_text = "Entries:";
var _ent_n = array_length(entries);
for (var _e = 0; _e < _ent_n && _e < 4; _e++) {
    var _en = entries[_e];
    _ent_text += "  $" + scr_ext_hex(_en.addr, 4) + " (" + _en.why + ")";
}
if (_ent_n > 4) {
    _ent_text += "  (+" + string(_ent_n - 4) + " more)";
}
if (_ent_n == 0) {
    _ent_text += "  none found - put the cursor on code and press C";
}
draw_text(info_x, _iy, _ent_text);
_iy += line_h * 2;

draw_set_colour(col_text);
draw_text(info_x, _iy, "Cursor $" + scr_ext_hex(cursor_addr, 4) + "  value $" + scr_ext_hex(buffer_peek(mem_buf, cursor_addr, buffer_u8), 2) + "  " + scr_ext_cls_name(buffer_peek(cls_buf, cursor_addr, buffer_u8)));
_iy += line_h;
if (hover_addr >= 0) {
    draw_set_colour(col_dim);
    draw_text(info_x, _iy, "Hover  $" + scr_ext_hex(hover_addr, 4) + "  value $" + scr_ext_hex(buffer_peek(mem_buf, hover_addr, buffer_u8), 2) + "  " + scr_ext_cls_name(buffer_peek(cls_buf, hover_addr, buffer_u8)));
}

// Legend with byte counts
var _lx = 1110;
var _ly2 = info_y;
for (var _c2 = 0; _c2 < EXT_CLS_COUNT; _c2++) {
    draw_set_colour(scr_ext_cls_colour(_c2));
    draw_rectangle(_lx, _ly2 + 3, _lx + 9, _ly2 + 12, false);
    draw_set_colour(col_dim);
    draw_text(_lx + 16, _ly2, scr_ext_cls_name(_c2));
    draw_text(_lx + 140, _ly2, string(cls_counts[_c2]));
    _ly2 += line_h;
}

draw_set_colour(c_white);
