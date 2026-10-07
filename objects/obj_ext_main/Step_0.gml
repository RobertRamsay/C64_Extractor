/// @desc Input

var _mx = mouse_x;
var _my = mouse_y;
var _shift = keyboard_check(vk_shift);
var _lmb_pressed = mouse_check_button_pressed(mb_left);
var _wheel = 0;
if (mouse_wheel_up()) {
    _wheel = -1;
}
if (mouse_wheel_down()) {
    _wheel = 1;
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
if (keyboard_check_pressed(vk_left)) {
    scr_ext_set_cursor(cursor_addr - 1, false);
}
if (keyboard_check_pressed(vk_right)) {
    scr_ext_set_cursor(cursor_addr + 1, false);
}
if (keyboard_check_pressed(vk_down)) {
    dis_top = (dis_top + scr_ext_disasm_line(dis_top).size) & $FFFF;
}
if (keyboard_check_pressed(vk_up)) {
    dis_top = scr_ext_prev_line_start(dis_top);
}
if (keyboard_check_pressed(vk_pagedown)) {
    repeat (dis_rows - 1) {
        dis_top = (dis_top + scr_ext_disasm_line(dis_top).size) & $FFFF;
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
    if (mouse_check_button(mb_left)) {
        scr_ext_set_cursor(hover_addr, true);
    }
    if (_wheel != 0) {
        scr_ext_set_cursor(cursor_addr + _wheel * 256, true);
    }
}

// ---- Hex view ----
var _hex_h = hex_rows * line_h;
if (point_in_rectangle(_mx, _my, hex_x, hex_y, hex_x + hex_w, hex_y + _hex_h - 1)) {
    var _row = floor((_my - hex_y) / line_h);
    var _col = floor((_mx - (hex_x + 48)) / 24);
    if (_col >= 0 && _col < 8) {
        hover_addr = (hex_top + _row * 8 + _col) & $FFFF;
        if (_lmb_pressed) {
            scr_ext_set_cursor(hover_addr, false);
            dis_top = scr_ext_align_to_instr(hover_addr);
        }
    }
    if (_wheel != 0) {
        var _ht = hex_top + _wheel * 24;
        var _hmax = 65536 - hex_rows * 8;
        if (_ht < 0) {
            _ht = 0;
        }
        if (_ht > _hmax) {
            _ht = _hmax;
        }
        hex_top = _ht;
    }
}

// ---- Disassembly view ----
var _dis_h = dis_rows * line_h;
if (point_in_rectangle(_mx, _my, dis_x, dis_y, dis_x + dis_w, dis_y + _dis_h - 1)) {
    var _drow = floor((_my - dis_y) / line_h);
    if (_drow >= 0 && _drow < dis_rows) {
        hover_addr = dis_line_addrs[_drow];
        if (_lmb_pressed) {
            scr_ext_set_cursor(hover_addr, false);
            var _ht2 = (hover_addr & $FFF8) - 8 * 8;
            if (_ht2 < 0) {
                _ht2 = 0;
            }
            if (_ht2 > 65536 - hex_rows * 8) {
                _ht2 = 65536 - hex_rows * 8;
            }
            hex_top = _ht2;
        }
    }
    if (_wheel > 0) {
        repeat (3) {
            dis_top = (dis_top + scr_ext_disasm_line(dis_top).size) & $FFFF;
        }
    }
    if (_wheel < 0) {
        repeat (3) {
            dis_top = scr_ext_prev_line_start(dis_top);
        }
    }
}

// ---- D64 directory ----
var _dir_h = (dir_rows + 1) * line_h;
if (point_in_rectangle(_mx, _my, dir_x, dir_y, dir_x + dir_w, dir_y + _dir_h)) {
    var _n = array_length(d64_files);
    if (_wheel != 0) {
        d64_scroll += _wheel;
        if (d64_scroll > _n - dir_rows) {
            d64_scroll = _n - dir_rows;
        }
        if (d64_scroll < 0) {
            d64_scroll = 0;
        }
    }
    if (_lmb_pressed) {
        var _frow = floor((_my - (dir_y + line_h)) / line_h);
        var _idx = d64_scroll + _frow;
        if (_frow >= 0 && _idx < _n) {
            scr_ext_d64_load_entry(_idx, _shift);
        }
    }
}
