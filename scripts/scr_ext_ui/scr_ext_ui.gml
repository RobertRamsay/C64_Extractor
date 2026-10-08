/// @desc scr_ext_update_window()
/// Watches the window size; on change sets the GUI scale and rebuilds the layout.
/// 4K and other high-DPI displays get a 2x GUI scale so text stays readable.
function scr_ext_update_window() {
    var _ww = window_get_width();
    var _wh = window_get_height();
    if (_ww <= 0 || _wh <= 0) {
        return;
    }
    if (_ww == last_win_w && _wh == last_win_h) {
        return;
    }
    last_win_w = _ww;
    last_win_h = _wh;

    ui_scale = 1;
    if (_wh >= 1700) {
        ui_scale = 2;
    }
    gui_w = floor(_ww / ui_scale);
    gui_h = floor(_wh / ui_scale);
    display_set_gui_size(gui_w, gui_h);
    scr_ext_layout();
}

/// @desc scr_ext_layout()
/// Positions every panel from gui_w / gui_h.
///
///  +-------------------------------------------------------------+
///  | toolbar                                                     |
///  +-----------+---------------------------+---------------------+
///  | memory    | graphics viewer           | hex                 |
///  | map       |                           |                     |
///  |           |                           +---------------------+
///  +-----------+                           | disassembly         |
///  | D64 dir   +---------------------------+                     |
///  |           | info / legend             |                     |
///  +-----------+---------------------------+---------------------+
function scr_ext_layout() {
    var _pad = ui_pad;
    var _title_h = line_h + 6;
    var _top = top_h + _pad + _title_h;

    // ---- Memory map: biggest whole scale that leaves room for the D64 list ----
    var _by_h = floor((gui_h - _top - 240) / 256);
    var _by_w = floor((gui_w * 0.36) / 256);
    map_scale = _by_h;
    if (_by_w < map_scale) {
        map_scale = _by_w;
    }
    if (map_scale < 1) {
        map_scale = 1;
    }
    var _map_size = 256 * map_scale;
    map_x = _pad + 8;
    map_y = _top;

    // ---- D64 directory under the map ----
    dir_x = map_x;
    dir_y = map_y + _map_size + _pad + _title_h;
    dir_w = _map_size;
    dir_h = gui_h - dir_y - _pad;
    dir_rows = floor(dir_h / line_h) - 1;
    if (dir_rows < 1) {
        dir_rows = 1;
    }

    // ---- Right column: hex on top, disassembly below ----
    var _col2_x = map_x + _map_size + _pad * 2 + 8;
    var _rc_w = floor((gui_w - _col2_x - _pad * 2) * 0.42);
    if (_rc_w < 470) {
        _rc_w = 470;
    }
    var _rc_x = gui_w - _pad - _rc_w;
    var _col_h = gui_h - _top - _pad;

    hex_x = _rc_x;
    hex_y = _top;
    hex_w = _rc_w;
    hex_h = floor(_col_h * 0.38);
    hex_rows = floor((hex_h - 8) / line_h);
    if (hex_rows < 4) {
        hex_rows = 4;
    }

    dis_x = _rc_x;
    dis_y = hex_y + hex_h + _pad + _title_h;
    dis_w = _rc_w;
    dis_h = gui_h - dis_y - _pad;
    dis_rows = floor((dis_h - 8) / line_h);
    if (dis_rows < 4) {
        dis_rows = 4;
    }
    dis_line_addrs = array_create(dis_rows, 0);

    // ---- Middle column: graphics viewer on top, info below ----
    gfx_x = _col2_x;
    gfx_y = _top;
    gfx_w = _rc_x - _pad - _col2_x;
    gfx_h = gui_h - _top - _pad - info_h - _pad - _title_h;

    info_x = gfx_x;
    info_y = gfx_y + gfx_h + _pad + _title_h;
    info_w = gfx_w;

    // Top toolbar: buttons sized to their labels
    draw_set_font(-1);
    var _tbx = 150;
    for (var _i = 0; _i < array_length(buttons); _i++) {
        buttons[_i].bw = string_width(buttons[_i].label) + 18;
        buttons[_i].bx = _tbx;
        _tbx += buttons[_i].bw + 6;
    }
    toolbar_help_x = _tbx + 14;

    // Disassembly: the text column starts after the widest byte column (4 bytes)
    dis_text_off = 64 + string_width("00 00 00 00 ") + 12;

    scr_ext_gfx_build_buttons();
    scr_ext_gfx_setup();

    // ---- Scroll bars ----
    sb_hex.x = hex_x + hex_w - EXT_SB_W - 2;
    sb_hex.y = hex_y + 2;
    sb_hex.h = hex_h - 4;

    sb_dis.x = dis_x + dis_w - EXT_SB_W - 2;
    sb_dis.y = dis_y + 2;
    sb_dis.h = dis_h - 4;

    sb_dir.x = dir_x + dir_w - EXT_SB_W - 2;
    sb_dir.y = dir_y + line_h + 2;
    sb_dir.h = dir_h - line_h - 4;

    sb_gfx.x = gfx_x + gfx_w - EXT_SB_W - 2;
    sb_gfx.y = gfx_canvas_y;
    sb_gfx.h = gfx_canvas_h;

    // Hex top must stay inside memory with the new row count
    scr_ext_clamp_hex_top();
    map_dirty = true;
}

/// @desc scr_ext_clamp_hex_top()
function scr_ext_clamp_hex_top() {
    var _hmax = 65536 - hex_rows * 8;
    if (hex_top > _hmax) {
        hex_top = _hmax;
    }
    if (hex_top < 0) {
        hex_top = 0;
    }
    hex_top = hex_top - (hex_top mod 8);
}

/// @desc scr_ext_sb_create()
/// Vertical scroll bar. value runs 0..max_value, page = visible amount.
function scr_ext_sb_create() {
    return {
        x         : 0,
        y         : 0,
        w         : EXT_SB_W,
        h         : 100,
        value     : 0,
        max_value : 0,
        page      : 1,
        dragging  : false,
        grab      : 0
    };
}

/// @desc scr_ext_sb_thumb(sb) - returns [thumb_y, thumb_h]
function scr_ext_sb_thumb(_sb) {
    var _th = _sb.h;
    if (_sb.max_value > 0) {
        _th = floor(_sb.h * _sb.page / (_sb.max_value + _sb.page));
    }
    if (_th < 20) {
        _th = 20;
    }
    if (_th > _sb.h) {
        _th = _sb.h;
    }
    var _ty = _sb.y;
    if (_sb.max_value > 0) {
        _ty = _sb.y + floor((_sb.h - _th) * (_sb.value / _sb.max_value));
    }
    return [_ty, _th];
}

/// @desc scr_ext_sb_step(sb, mx, my, pressed, held)
/// Returns true if the value changed. Sets sb.dragging while the thumb is held.
function scr_ext_sb_step(_sb, _mx, _my, _pressed, _held) {
    if (!_held) {
        _sb.dragging = false;
    }
    var _t = scr_ext_sb_thumb(_sb);
    var _ty = _t[0];
    var _th = _t[1];

    if (_pressed) {
        if (point_in_rectangle(_mx, _my, _sb.x, _sb.y, _sb.x + _sb.w, _sb.y + _sb.h)) {
            if (_my >= _ty && _my < _ty + _th) {
                _sb.dragging = true;
                _sb.grab = _my - _ty;
                return false;
            }
            // Click in the track: page up / down
            var _v = _sb.value;
            if (_my < _ty) {
                _v -= _sb.page;
            }
            else {
                _v += _sb.page;
            }
            if (_v < 0) {
                _v = 0;
            }
            if (_v > _sb.max_value) {
                _v = _sb.max_value;
            }
            _sb.value = _v;
            return true;
        }
    }

    if (_sb.dragging) {
        var _range = _sb.h - _th;
        var _nv = 0;
        if (_range > 0) {
            _nv = round(((_my - _sb.grab) - _sb.y) / _range * _sb.max_value);
        }
        if (_nv < 0) {
            _nv = 0;
        }
        if (_nv > _sb.max_value) {
            _nv = _sb.max_value;
        }
        if (_nv != _sb.value) {
            _sb.value = _nv;
            return true;
        }
    }
    return false;
}

/// @desc scr_ext_sb_hit(sb, mx, my) - true if the point is over the bar
function scr_ext_sb_hit(_sb, _mx, _my) {
    return point_in_rectangle(_mx, _my, _sb.x, _sb.y, _sb.x + _sb.w, _sb.y + _sb.h);
}

/// @desc scr_ext_sb_draw(sb)
function scr_ext_sb_draw(_sb) {
    draw_set_colour(col_sb_track);
    draw_rectangle(_sb.x, _sb.y, _sb.x + _sb.w, _sb.y + _sb.h, false);
    var _t = scr_ext_sb_thumb(_sb);
    if (_sb.dragging) {
        draw_set_colour(col_button_hi);
    }
    else {
        draw_set_colour(col_sb_thumb);
    }
    draw_rectangle(_sb.x + 2, _t[0], _sb.x + _sb.w - 2, _t[0] + _t[1], false);
}

/// @desc scr_ext_draw_button(button, active)
function scr_ext_draw_button(_b, _active) {
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);
    var _over = point_in_rectangle(_mx, _my, _b.bx, _b.by, _b.bx + _b.bw, _b.by + _b.bh);
    if (_active) {
        draw_set_colour(col_button_on);
    }
    else if (_over) {
        draw_set_colour(col_button_hi);
    }
    else {
        draw_set_colour(col_button);
    }
    draw_rectangle(_b.bx, _b.by, _b.bx + _b.bw, _b.by + _b.bh, false);
    draw_set_colour(col_border);
    draw_rectangle(_b.bx, _b.by, _b.bx + _b.bw, _b.by + _b.bh, true);
    draw_set_colour(col_text);
    draw_set_halign(fa_center);
    draw_text(_b.bx + _b.bw / 2, _b.by + 5, _b.label);
    draw_set_halign(fa_left);
}

/// @desc scr_ext_panel(x, y, w, h, title)
/// Draws a panel background with an optional title strip above it.
function scr_ext_panel(_x, _y, _w, _h, _title) {
    draw_set_colour(col_panel);
    draw_rectangle(_x - 6, _y - 6, _x + _w, _y + _h, false);
    draw_set_colour(col_border);
    draw_rectangle(_x - 6, _y - 6, _x + _w, _y + _h, true);
    if (_title != "") {
        draw_set_colour(col_title);
        draw_text(_x, _y - 6 - line_h - 2, _title);
    }
}
