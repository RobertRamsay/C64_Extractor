/// @desc Input

// Size the window a couple of frames after start-up, once it exists
if (full_window_delay > 0) {
    full_window_delay -= 1;
    if (full_window_delay == 0) {
        scr_ext_set_full_window(full_window);
    }
}
scr_ext_update_window();

var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);
var _shift = keyboard_check(vk_shift);
var _lmb_pressed = mouse_check_button_pressed(mb_left);
var _lmb_held = mouse_check_button(mb_left);
var _wheel = 0;
if (mouse_wheel_up()) {
    _wheel = -1;
}
if (mouse_wheel_down()) {
    _wheel = 1;
}

// ---- Scroll bars (take priority over the panels underneath) ----
var _n_files = array_length(d64_files);

sb_hex.max_value = 8192 - hex_rows;
sb_hex.page = hex_rows;
sb_hex.value = hex_top div 8;
if (scr_ext_sb_step(sb_hex, _mx, _my, _lmb_pressed, _lmb_held)) {
    hex_top = sb_hex.value * 8;
    scr_ext_clamp_hex_top();
}

sb_dis.max_value = 65535;
sb_dis.page = dis_rows * 2;
sb_dis.value = dis_top;
if (scr_ext_sb_step(sb_dis, _mx, _my, _lmb_pressed, _lmb_held)) {
    dis_top = scr_ext_align_to_instr(sb_dis.value);
}

sb_dir.max_value = _n_files - dir_rows;
if (sb_dir.max_value < 0) {
    sb_dir.max_value = 0;
}
sb_dir.page = dir_rows;
sb_dir.value = d64_scroll;
if (scr_ext_sb_step(sb_dir, _mx, _my, _lmb_pressed, _lmb_held)) {
    d64_scroll = sb_dir.value;
}

sb_gfx.value = gfx_addr;
if (scr_ext_sb_step(sb_gfx, _mx, _my, _lmb_pressed, _lmb_held)) {
    gfx_addr = scr_ext_gfx_snap(sb_gfx.value);
    gfx_dirty = true;
}

var _sb_busy = false;
if (sb_hex.dragging || sb_dis.dragging || sb_dir.dragging || sb_gfx.dragging) {
    _sb_busy = true;
}
if (_lmb_pressed) {
    if (scr_ext_sb_hit(sb_hex, _mx, _my) || scr_ext_sb_hit(sb_dis, _mx, _my) || scr_ext_sb_hit(sb_dir, _mx, _my) || scr_ext_sb_hit(sb_gfx, _mx, _my)) {
        _lmb_pressed = false;
        _sb_busy = true;
    }
}

// ---- Shift+press over map / viewer / hex / disassembly starts a selection at the cursor ----
if (_lmb_pressed && _shift && !_sb_busy) {
    if (scr_ext_in_select_panel(_mx, _my)) {
        sel_dragging = true;
        sel_anchor = cursor_addr;
        _lmb_pressed = false;
    }
}

// ---- Toolbar ----
if (_lmb_pressed) {
    for (var _i = 0; _i < array_length(buttons); _i++) {
        var _b = buttons[_i];
        if (point_in_rectangle(_mx, _my, _b.bx, _b.by, _b.bx + _b.bw, _b.by + _b.bh)) {
            scr_ext_do_action(_b.action, _shift);
            _lmb_pressed = false;
            break;
        }
    }
}

// ---- Graphics viewer toolbar and swatches ----
if (_lmb_pressed) {
    for (var _i = 0; _i < array_length(gfx_buttons); _i++) {
        var _gb = gfx_buttons[_i];
        if (point_in_rectangle(_mx, _my, _gb.bx, _gb.by, _gb.bx + _gb.bw, _gb.by + _gb.bh)) {
            scr_ext_gfx_do_button(_gb, _shift);
            _lmb_pressed = false;
            break;
        }
    }
}
if (_lmb_pressed) {
    var _sw = scr_ext_gfx_swatch_hit(_mx, _my);
    if (_sw >= 0) {
        if (_shift) {
            gfx_col[_sw] = (gfx_col[_sw] + 15) mod 16;
        }
        else {
            gfx_col[_sw] = (gfx_col[_sw] + 1) mod 16;
        }
        gfx_dirty = true;
        _lmb_pressed = false;
    }
}

// ---- Hotkeys ----
if (keyboard_check_pressed(ord("O"))) {
    scr_ext_do_action("open", _shift);
}
if (keyboard_check_pressed(ord("C"))) {
    scr_ext_do_action("trace", false);
}
if (keyboard_check_pressed(ord("R"))) {
    scr_ext_do_action("analyse", false);
}
if (keyboard_check_pressed(ord("V"))) {
    scr_ext_do_action("shade", false);
}
if (keyboard_check_pressed(vk_f11)) {
    scr_ext_do_action("fullscreen", false);
}
if (keyboard_check_pressed(ord("F"))) {
    scr_ext_gfx_do_button({ action : "gfollow", arg : 0 }, false);
}
if (keyboard_check_pressed(ord("G"))) {
    scr_ext_gfx_do_button({ action : "ggrid", arg : 0 }, false);
}
for (var _k = 0; _k < EXT_GFX_MODE_COUNT; _k++) {
    if (keyboard_check_pressed(ord(string(_k + 1)))) {
        scr_ext_gfx_do_button({ action : "gmode", arg : _k }, false);
    }
}
if (keyboard_check_pressed(ord("X"))) {
    scr_ext_do_action("export", false);
}
if (keyboard_check_pressed(ord("W"))) {
    scr_ext_sel_region();
}
if (keyboard_check_pressed(vk_escape)) {
    sel_active = false;
    sel_dragging = false;
}
if (keyboard_check_pressed(ord("B"))) {
    if (sel_active) {
        scr_ext_sel_set(cursor_addr, sel_end);
    }
    else {
        scr_ext_sel_set(cursor_addr, cursor_addr);
    }
}
if (keyboard_check_pressed(ord("E"))) {
    if (sel_active) {
        scr_ext_sel_set(sel_start, cursor_addr);
    }
    else {
        scr_ext_sel_set(cursor_addr, cursor_addr);
    }
}
if (keyboard_check_pressed(vk_left)) {
    scr_ext_set_cursor(cursor_addr - 1, false);
}
if (keyboard_check_pressed(vk_right)) {
    scr_ext_set_cursor(cursor_addr + 1, false);
}
if (keyboard_check_pressed(vk_down)) {
    dis_top = (dis_top + scr_ext_disasm_line(dis_top).size) & 0xFFFF;
}
if (keyboard_check_pressed(vk_up)) {
    dis_top = scr_ext_prev_line_start(dis_top);
}
if (keyboard_check_pressed(vk_pagedown)) {
    repeat (dis_rows - 1) {
        dis_top = (dis_top + scr_ext_disasm_line(dis_top).size) & 0xFFFF;
    }
}
if (keyboard_check_pressed(vk_pageup)) {
    repeat (dis_rows - 1) {
        dis_top = scr_ext_prev_line_start(dis_top);
    }
}

hover_addr = -1;

// ---- Memory map: hover, click / drag to move the cursor ----
var _map_size = 256 * map_scale;
if (point_in_rectangle(_mx, _my, map_x, map_y, map_x + _map_size - 1, map_y + _map_size - 1)) {
    var _cx = floor((_mx - map_x) / map_scale);
    var _cy = floor((_my - map_y) / map_scale);
    hover_addr = _cy * 256 + _cx;
    if (_lmb_held && !_sb_busy && !sel_dragging) {
        scr_ext_set_cursor(hover_addr, true);
    }
    if (_wheel != 0) {
        scr_ext_set_cursor(cursor_addr + _wheel * 256, true);
    }
}

// ---- Graphics viewer canvas ----
if (point_in_rectangle(_mx, _my, gfx_canvas_x, gfx_canvas_y, gfx_canvas_x + gfx_canvas_w, gfx_canvas_y + gfx_canvas_h)) {
    var _ga = scr_ext_gfx_addr_at(_mx, _my);
    if (_ga >= 0) {
        hover_addr = _ga;
        if (_lmb_pressed) {
            cursor_addr = _ga;
            scr_ext_views_to(_ga);
        }
    }
    if (_wheel != 0) {
        // Wheel = one row of cells, Shift+wheel = one byte (to find alignment)
        if (_shift) {
            gfx_addr = (gfx_addr + _wheel) & 0xFFFF;
            gfx_phase = gfx_addr mod gfx_row_bytes;
        }
        else {
            gfx_addr = (gfx_addr + _wheel * gfx_row_cols * gfx_cell_bytes) & 0xFFFF;
        }
        gfx_dirty = true;
    }
}

// ---- Hex view ----
var _hex_text_w = hex_w - EXT_SB_W - 6;
if (point_in_rectangle(_mx, _my, hex_x, hex_y, hex_x + _hex_text_w, hex_y + hex_rows * line_h - 1)) {
    var _row = floor((_my - hex_y) / line_h);
    var _col = floor((_mx - (hex_x + 52)) / 26);
    if (_col >= 0 && _col < 8) {
        hover_addr = (hex_top + _row * 8 + _col) & 0xFFFF;
        if (_lmb_pressed) {
            scr_ext_set_cursor(hover_addr, false);
            dis_top = scr_ext_align_to_instr(hover_addr);
            if (gfx_follow) {
                scr_ext_gfx_follow();
            }
        }
    }
    if (_wheel != 0) {
        hex_top += _wheel * 24;
        scr_ext_clamp_hex_top();
    }
}

// ---- Disassembly view ----
var _dis_text_w = dis_w - EXT_SB_W - 6;
if (point_in_rectangle(_mx, _my, dis_x, dis_y, dis_x + _dis_text_w, dis_y + dis_rows * line_h - 1)) {
    var _drow = floor((_my - dis_y) / line_h);
    if (_drow >= 0 && _drow < dis_rows) {
        hover_addr = dis_line_addrs[_drow];
        if (_lmb_pressed) {
            scr_ext_set_cursor(hover_addr, false);
            hex_top = (hover_addr & 0xFFF8) - 8 * 8;
            scr_ext_clamp_hex_top();
            if (gfx_follow) {
                scr_ext_gfx_follow();
            }
        }
    }
    if (_wheel > 0) {
        repeat (3) {
            dis_top = (dis_top + scr_ext_disasm_line(dis_top).size) & 0xFFFF;
        }
    }
    if (_wheel < 0) {
        repeat (3) {
            dis_top = scr_ext_prev_line_start(dis_top);
        }
    }
}

// ---- D64 directory ----
if (point_in_rectangle(_mx, _my, dir_x, dir_y, dir_x + dir_w - EXT_SB_W - 4, dir_y + dir_h)) {
    if (_wheel != 0) {
        d64_scroll += _wheel;
        if (d64_scroll > _n_files - dir_rows) {
            d64_scroll = _n_files - dir_rows;
        }
        if (d64_scroll < 0) {
            d64_scroll = 0;
        }
    }
    if (_lmb_pressed) {
        var _frow = floor((_my - (dir_y + line_h)) / line_h);
        var _idx = d64_scroll + _frow;
        if (_frow >= 0 && _frow < dir_rows && _idx < _n_files) {
            scr_ext_d64_load_entry(_idx, _shift);
        }
    }
}

// ---- Selection drag: extend from the anchor to whatever is under the mouse ----
if (sel_dragging) {
    if (_lmb_held) {
        if (hover_addr >= 0) {
            scr_ext_sel_set(sel_anchor, hover_addr);
        }
    }
    else {
        sel_dragging = false;
    }
}
