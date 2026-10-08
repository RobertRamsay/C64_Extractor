/// @desc scr_ext_c64_palette()
/// The 16 C64 colours (VICE "Pepto" style) as [r, g, b].
function scr_ext_c64_palette() {
    return [
        [0x00, 0x00, 0x00], [0xFF, 0xFF, 0xFF], [0x68, 0x37, 0x2B], [0x70, 0xA4, 0xB2],
        [0x6F, 0x3D, 0x86], [0x58, 0x8D, 0x43], [0x35, 0x28, 0x79], [0xB8, 0xC7, 0x6F],
        [0x6F, 0x4F, 0x25], [0x43, 0x39, 0x00], [0x9A, 0x67, 0x59], [0x44, 0x44, 0x44],
        [0x6C, 0x6C, 0x6C], [0x9A, 0xD2, 0x84], [0x6C, 0x5E, 0xB5], [0x95, 0x95, 0x95]
    ];
}

/// @desc scr_ext_rgba(r, g, b) - u32 that pokes as R,G,B,A bytes into a surface buffer
function scr_ext_rgba(_r, _g, _b) {
    return (0xFF << 24) | (_b << 16) | (_g << 8) | _r;
}

/// @desc scr_ext_gfx_mode_name(mode)
function scr_ext_gfx_mode_name(_m) {
    switch (_m) {
        case EXT_GFX_CHAR_HR: return "HR Char";
        case EXT_GFX_CHAR_MC: return "MC Char";
        case EXT_GFX_SPR_HR:  return "HR Sprite";
        case EXT_GFX_SPR_MC:  return "MC Sprite";
        case EXT_GFX_BMP_HR:  return "HR Bitmap";
        case EXT_GFX_BMP_MC:  return "MC Bitmap";
    }
    return "?";
}

/// @desc scr_ext_gfx_is_mc() - true for the multicolour modes
function scr_ext_gfx_is_mc() {
    if (gfx_mode == EXT_GFX_CHAR_MC || gfx_mode == EXT_GFX_SPR_MC || gfx_mode == EXT_GFX_BMP_MC) {
        return true;
    }
    return false;
}

/// @desc scr_ext_gfx_is_sprite()
function scr_ext_gfx_is_sprite() {
    if (gfx_mode == EXT_GFX_SPR_HR || gfx_mode == EXT_GFX_SPR_MC) {
        return true;
    }
    return false;
}

/// @desc scr_ext_gfx_is_bitmap()
function scr_ext_gfx_is_bitmap() {
    if (gfx_mode == EXT_GFX_BMP_HR || gfx_mode == EXT_GFX_BMP_MC) {
        return true;
    }
    return false;
}

/// @desc scr_ext_gfx_build_buttons()
/// Viewer toolbar: row 1 = modes, row 2 = columns / follow / grid / colour swatches.
function scr_ext_gfx_build_buttons() {
    gfx_buttons = [];
    var _bx = gfx_x;
    var _by = gfx_y;
    var _bw = floor((gfx_w - 5 * 4) / EXT_GFX_MODE_COUNT);
    if (_bw > 100) {
        _bw = 100;
    }
    for (var _m = 0; _m < EXT_GFX_MODE_COUNT; _m++) {
        array_push(gfx_buttons, { bx : _bx, by : _by, bw : _bw, bh : 22, label : scr_ext_gfx_mode_name(_m), action : "gmode", arg : _m });
        _bx += _bw + 4;
    }

    _bx = gfx_x;
    _by = gfx_y + 28;
    var _labels  = ["Cols -", "Cols +", "Follow [F]", "Grid [G]", "Select view"];
    var _actions = ["gcols",  "gcols",  "gfollow",    "ggrid",    "gselview"];
    var _args    = [-1,       1,        0,            0,          0];
    draw_set_font(-1);
    for (var _i = 0; _i < array_length(_labels); _i++) {
        var _w = string_width(_labels[_i]) + 18;
        array_push(gfx_buttons, { bx : _bx, by : _by, bw : _w, bh : 22, label : _labels[_i], action : _actions[_i], arg : _args[_i] });
        _bx += _w + 4;
    }
    _bx += 10;

    // Colour swatches: BG, MC1, MC2, FG
    gfx_swatch_x = _bx;
    gfx_swatch_y = _by;

    // Row 3: bitmap colours (screen RAM / colour data)
    _bx = gfx_x;
    _by = gfx_y + 56;
    var _labels3  = ["Colours [K]", "Find colours [M]", "Koala", "Scr = cursor", "Col = cursor", "Export picture"];
    var _actions3 = ["gcolour",     "gfindcol",         "gkoala", "gscr",        "gcol",         "gexport"];
    for (var _i = 0; _i < array_length(_labels3); _i++) {
        var _w3 = string_width(_labels3[_i]) + 18;
        array_push(gfx_buttons, { bx : _bx, by : _by, bw : _w3, bh : 22, label : _labels3[_i], action : _actions3[_i], arg : 0 });
        _bx += _w3 + 4;
    }
    gfx_colour_text_x = _bx + 8;
    gfx_colour_text_y = _by + 4;

    // Row 4: nudge the start address (hold to repeat) and auto-align
    _bx = gfx_x;
    _by = gfx_y + 84;
    var _labels4  = ["-1 cell", "-1 byte", "+1 byte", "+1 cell", "Align [L]", "Export sprites", "Export PNG"];
    var _actions4 = ["gnudge",  "gnudge",  "gnudge",  "gnudge",  "galign",    "gexpspr",        "gexppng"];
    var _args4    = [-2,        -1,        1,         2,         0,           0,                0];
    for (var _i = 0; _i < array_length(_labels4); _i++) {
        var _w4 = string_width(_labels4[_i]) + 18;
        array_push(gfx_buttons, { bx : _bx, by : _by, bw : _w4, bh : 22, label : _labels4[_i], action : _actions4[_i], arg : _args4[_i] });
        _bx += _w4 + 4;
    }
    gfx_nudge_text_x = _bx + 8;
    gfx_nudge_text_y = _by + 4;

    gfx_canvas_x = gfx_x;
    gfx_canvas_y = gfx_y + 112;
    gfx_canvas_w = gfx_w - EXT_SB_W - 8;
    gfx_canvas_h = gfx_h - 112;
    if (gfx_canvas_h < 32) {
        gfx_canvas_h = 32;
    }
}

/// @desc scr_ext_gfx_setup()
/// Works out cell size, columns, rows, zoom and image size for the current mode.
function scr_ext_gfx_setup() {
    var _cols = gfx_char_cols;
    gfx_cell_w = 8;
    gfx_cell_h = 8;
    gfx_cell_bytes = 8;
    gfx_gap = 0;
    gfx_align = 8;

    if (scr_ext_gfx_is_sprite()) {
        _cols = gfx_spr_cols;
        gfx_cell_w = 24;
        gfx_cell_h = 21;
        gfx_cell_bytes = 64;
        gfx_gap = 1;
        gfx_align = 64;
    }
    if (scr_ext_gfx_is_bitmap()) {
        _cols = 40;
    }
    gfx_row_cols = _cols;

    var _pitch_w = gfx_cell_w + gfx_gap;
    var _pitch_h = gfx_cell_h + gfx_gap;

    gfx_zoom = floor(gfx_canvas_w / (_cols * _pitch_w));
    if (scr_ext_gfx_is_bitmap()) {
        var _zh = floor(gfx_canvas_h / (25 * _pitch_h));
        if (_zh < gfx_zoom) {
            gfx_zoom = _zh;
        }
    }
    if (gfx_zoom > 8) {
        gfx_zoom = 8;
    }
    if (gfx_zoom < 1) {
        gfx_zoom = 1;
    }
    // After the width handle has been dragged, keep that zoom (unless it no longer fits)
    if (gfx_zoom_lock > 0) {
        if (gfx_zoom_lock <= gfx_zoom) {
            gfx_zoom = gfx_zoom_lock;
        }
    }

    if (scr_ext_gfx_is_bitmap()) {
        gfx_rows = 25;
    }
    else {
        gfx_rows = floor(gfx_canvas_h / (_pitch_h * gfx_zoom));
        if (gfx_rows < 1) {
            gfx_rows = 1;
        }
    }

    gfx_img_w = _cols * _pitch_w;
    gfx_img_h = gfx_rows * _pitch_h;
    gfx_screen_bytes = _cols * gfx_rows * gfx_cell_bytes;
    gfx_row_bytes = _cols * gfx_cell_bytes;
    gfx_phase = gfx_phase mod gfx_row_bytes;

    sb_gfx.max_value = 65535;
    sb_gfx.page = gfx_screen_bytes;
    gfx_dirty = true;
}

/// @desc scr_ext_gfx_snap(addr)
/// Snaps an address to a whole row of cells, keeping the fine offset (gfx_phase).
/// Every scroll moves the picture vertically only, so cells never slide sideways.
function scr_ext_gfx_snap(_addr) {
    var _rows = floor((_addr - gfx_phase) / gfx_row_bytes);
    return (gfx_phase + _rows * gfx_row_bytes) & 0xFFFF;
}

/// @desc scr_ext_gfx_follow()
/// Keeps the cursor visible in the viewer. Does nothing while the cursor is
/// already on screen; otherwise scrolls whole rows so the cursor's row is at the top.
function scr_ext_gfx_follow() {
    var _rel = (cursor_addr - gfx_addr + 65536) mod 65536;
    if (_rel < gfx_screen_bytes) {
        return;
    }
    gfx_addr = scr_ext_gfx_snap(cursor_addr);
    gfx_dirty = true;
}

/// @desc scr_ext_gfx_do_button(button, shift)
function scr_ext_gfx_do_button(_b, _shift) {
    switch (_b.action) {
        case "gmode":
            gfx_mode = _b.arg;
            gfx_zoom_lock = 0;
            scr_ext_gfx_setup();
            // Stay exactly where we are in memory; future scrolling keeps this offset
            gfx_phase = gfx_addr mod gfx_row_bytes;
            break;

        case "gcols":
            if (scr_ext_gfx_is_sprite()) {
                gfx_spr_cols += _b.arg;
                if (gfx_spr_cols < 1) {
                    gfx_spr_cols = 1;
                }
                if (gfx_spr_cols > 32) {
                    gfx_spr_cols = 32;
                }
            }
            else if (!scr_ext_gfx_is_bitmap()) {
                gfx_char_cols += _b.arg;
                if (gfx_char_cols < 1) {
                    gfx_char_cols = 1;
                }
                if (gfx_char_cols > 128) {
                    gfx_char_cols = 128;
                }
            }
            scr_ext_gfx_setup();
            gfx_phase = gfx_addr mod gfx_row_bytes;
            break;

        case "gfollow":
            if (gfx_follow) {
                gfx_follow = false;
            }
            else {
                gfx_follow = true;
                scr_ext_gfx_follow();
            }
            break;

        case "gselview":
            var _end = gfx_addr + gfx_screen_bytes - 1;
            if (_end > 0xFFFF) {
                _end = 0xFFFF;
            }
            scr_ext_sel_set(gfx_addr, _end);
            break;

        case "gcolour":
            if (gfx_use_colour) {
                gfx_use_colour = false;
            }
            else {
                gfx_use_colour = true;
            }
            gfx_dirty = true;
            break;

        case "gkoala":
            // Koala Painter layout: bitmap, +8000 screen RAM, +9000 colour RAM, +10000 background
            gfx_scr_addr = (gfx_addr + 8000) & 0xFFFF;
            gfx_col_addr = (gfx_addr + 9000) & 0xFFFF;
            gfx_col[0] = buffer_peek(mem_buf, (gfx_addr + 10000) & 0xFFFF, buffer_u8) & 15;
            gfx_use_colour = true;
            gfx_dirty = true;
            status_text = "Koala layout: screen $" + scr_ext_hex(gfx_scr_addr, 4) + ", colour $" + scr_ext_hex(gfx_col_addr, 4) + ", background " + string(gfx_col[0]);
            break;

        case "gscr":
            gfx_scr_addr = cursor_addr;
            gfx_use_colour = true;
            gfx_dirty = true;
            status_text = "Screen RAM (colour pairs 01/10) taken from $" + scr_ext_hex(gfx_scr_addr, 4);
            break;

        case "gcol":
            gfx_col_addr = cursor_addr;
            gfx_use_colour = true;
            gfx_dirty = true;
            status_text = "Colour RAM data (pair 11) taken from $" + scr_ext_hex(gfx_col_addr, 4);
            break;

        case "galign":
            scr_ext_gfx_auto_align();
            break;

        case "gnudge":
            // arg: +/-1 = one byte, +/-2 = one cell
            if (_b.arg == -2) {
                scr_ext_gfx_nudge(-gfx_cell_bytes);
            }
            else if (_b.arg == 2) {
                scr_ext_gfx_nudge(gfx_cell_bytes);
            }
            else {
                scr_ext_gfx_nudge(_b.arg);
            }
            break;

        case "gfindcol":
            scr_ext_gfx_find_colours();
            break;

        case "gexport":
            scr_ext_gfx_export_picture();
            break;

        case "gexpspr":
            scr_ext_gfx_export_sprites();
            break;

        case "gexppng":
            scr_ext_gfx_export_png();
            break;

        case "ggrid":
            if (gfx_grid) {
                gfx_grid = false;
            }
            else {
                gfx_grid = true;
            }
            break;
    }
}

/// @desc scr_ext_gfx_swatch_hit(mx, my) - swatch index 0..3 under the mouse, or -1
function scr_ext_gfx_swatch_hit(_mx, _my) {
    for (var _i = 0; _i < 4; _i++) {
        var _sx = gfx_swatch_x + _i * 46;
        if (point_in_rectangle(_mx, _my, _sx, gfx_swatch_y, _sx + 40, gfx_swatch_y + 22)) {
            return _i;
        }
    }
    return -1;
}

/// @desc scr_ext_gfx_render()
/// Renders the current view of memory into gfx_surf via a pixel buffer.
function scr_ext_gfx_render() {
    var _size = gfx_img_w * gfx_img_h * 4;
    if (buffer_exists(gfx_buf)) {
        if (buffer_get_size(gfx_buf) != _size) {
            buffer_delete(gfx_buf);
            gfx_buf = -1;
        }
    }
    if (!buffer_exists(gfx_buf)) {
        gfx_buf = buffer_create(_size, buffer_fixed, 1);
    }
    if (surface_exists(gfx_surf)) {
        if (surface_get_width(gfx_surf) != gfx_img_w || surface_get_height(gfx_surf) != gfx_img_h) {
            surface_free(gfx_surf);
            gfx_surf = -1;
        }
    }
    if (!surface_exists(gfx_surf)) {
        gfx_surf = surface_create(gfx_img_w, gfx_img_h);
    }

    buffer_fill(gfx_buf, 0, buffer_u32, gfx_gap_u32, _size);

    var _pal4 = [
        c64_pal_u32[gfx_col[0]],
        c64_pal_u32[gfx_col[1]],
        c64_pal_u32[gfx_col[2]],
        c64_pal_u32[gfx_col[3]]
    ];
    var _bg = _pal4[0];
    var _fg = _pal4[3];
    var _none = gfx_none_u32;
    var _mc = scr_ext_gfx_is_mc();
    var _spr = scr_ext_gfx_is_sprite();

    var _pitch_w = gfx_cell_w + gfx_gap;
    var _pitch_h = gfx_cell_h + gfx_gap;
    var _bytes_per_row = gfx_cell_w div 8;
    var _cells = gfx_row_cols * gfx_rows;
    var _img_w = gfx_img_w;

    // Bitmap colours: screen RAM gives pairs 01/10 (MC) or ink/paper (HR),
    // colour RAM data gives pair 11 (MC)
    var _colour_on = false;
    if (scr_ext_gfx_is_bitmap() && gfx_use_colour) {
        _colour_on = true;
    }
    var _cell_pal = [_pal4[0], _pal4[1], _pal4[2], _pal4[3]];

    for (var _cell = 0; _cell < _cells; _cell++) {
        var _ox = (_cell mod gfx_row_cols) * _pitch_w;
        var _oy = (_cell div gfx_row_cols) * _pitch_h;
        var _cell_base = gfx_addr + _cell * gfx_cell_bytes;

        var _cp = _pal4;
        if (_colour_on) {
            _cell_pal[0] = _pal4[0];
            _cell_pal[1] = _pal4[1];
            _cell_pal[2] = _pal4[2];
            _cell_pal[3] = _pal4[3];
            if (gfx_scr_addr >= 0) {
                var _sv = buffer_peek(mem_buf, (gfx_scr_addr + _cell) & 0xFFFF, buffer_u8);
                if (_mc) {
                    _cell_pal[1] = c64_pal_u32[_sv >> 4];
                    _cell_pal[2] = c64_pal_u32[_sv & 15];
                }
                else {
                    _cell_pal[3] = c64_pal_u32[_sv >> 4];
                    _cell_pal[0] = c64_pal_u32[_sv & 15];
                }
            }
            if (_mc && gfx_col_addr >= 0) {
                _cell_pal[3] = c64_pal_u32[buffer_peek(mem_buf, (gfx_col_addr + _cell) & 0xFFFF, buffer_u8) & 15];
            }
            _cp = _cell_pal;
        }

        for (var _row = 0; _row < gfx_cell_h; _row++) {
            for (var _bc = 0; _bc < _bytes_per_row; _bc++) {
                var _a = _cell_base + _row;
                if (_spr) {
                    _a = _cell_base + _row * 3 + _bc;
                }
                _a = _a & 0xFFFF;
                var _off = (((_oy + _row) * _img_w) + _ox + _bc * 8) * 4;

                if (buffer_peek(loaded_buf, _a, buffer_u8) == 0) {
                    for (var _p = 0; _p < 8; _p++) {
                        buffer_poke(gfx_buf, _off + _p * 4, buffer_u32, _none);
                    }
                }
                else {
                    var _v = buffer_peek(mem_buf, _a, buffer_u8);
                    if (_mc) {
                        for (var _pair = 0; _pair < 4; _pair++) {
                            var _col = _cp[(_v >> (6 - _pair * 2)) & 3];
                            buffer_poke(gfx_buf, _off + _pair * 8, buffer_u32, _col);
                            buffer_poke(gfx_buf, _off + _pair * 8 + 4, buffer_u32, _col);
                        }
                    }
                    else {
                        for (var _bit = 0; _bit < 8; _bit++) {
                            if (((_v >> (7 - _bit)) & 1) == 1) {
                                buffer_poke(gfx_buf, _off + _bit * 4, buffer_u32, _cp[3]);
                            }
                            else {
                                buffer_poke(gfx_buf, _off + _bit * 4, buffer_u32, _cp[0]);
                            }
                        }
                    }
                }
            }
        }
    }

    buffer_set_surface(gfx_buf, gfx_surf, 0);
    gfx_dirty = false;
}

/// @desc scr_ext_gfx_addr_at(mx, my)
/// C64 address of the byte under a GUI point in the viewer canvas, or -1.
function scr_ext_gfx_addr_at(_mx, _my) {
    var _ix = floor((_mx - gfx_canvas_x) / gfx_zoom);
    var _iy = floor((_my - gfx_canvas_y) / gfx_zoom);
    if (_ix < 0 || _iy < 0 || _ix >= gfx_img_w || _iy >= gfx_img_h) {
        return -1;
    }
    var _pitch_w = gfx_cell_w + gfx_gap;
    var _pitch_h = gfx_cell_h + gfx_gap;
    var _cx = _ix div _pitch_w;
    var _cy = _iy div _pitch_h;
    var _px = _ix mod _pitch_w;
    var _py = _iy mod _pitch_h;
    if (_px >= gfx_cell_w || _py >= gfx_cell_h) {
        return -1;
    }
    var _cell = _cy * gfx_row_cols + _cx;
    var _a = gfx_addr + _cell * gfx_cell_bytes;
    if (scr_ext_gfx_is_sprite()) {
        _a += _py * 3 + (_px div 8);
    }
    else {
        _a += _py;
    }
    return _a & 0xFFFF;
}

/// @desc scr_ext_gfx_draw()
/// Draws the viewer: toolbar, swatches, canvas, grid, cursor cell and scroll bar.
function scr_ext_gfx_draw() {
    var _title = "GRAPHICS  " + scr_ext_gfx_mode_name(gfx_mode) + "   $" + scr_ext_hex(gfx_addr, 4) + "-$" + scr_ext_hex(gfx_addr + gfx_screen_bytes - 1, 4) + "   " + string(gfx_row_cols) + " cols   zoom x" + string(gfx_zoom);
    if (scr_ext_gfx_is_bitmap()) {
        if (gfx_use_colour) {
            _title += "   colours: SCR ";
            if (gfx_scr_addr >= 0) {
                _title += "$" + scr_ext_hex(gfx_scr_addr, 4);
            }
            else {
                _title += "-";
            }
            _title += "  COL ";
            if (gfx_col_addr >= 0) {
                _title += "$" + scr_ext_hex(gfx_col_addr, 4);
            }
            else {
                _title += "-";
            }
        }
        else {
            _title += "   colours off";
        }
    }
    scr_ext_panel(gfx_x, gfx_y, gfx_w, gfx_h, _title);

    for (var _i = 0; _i < array_length(gfx_buttons); _i++) {
        var _b = gfx_buttons[_i];
        var _active = false;
        if (_b.action == "gmode" && _b.arg == gfx_mode) {
            _active = true;
        }
        if (_b.action == "gfollow" && gfx_follow) {
            _active = true;
        }
        if (_b.action == "ggrid" && gfx_grid) {
            _active = true;
        }
        scr_ext_draw_button(_b, _active);
    }

    // Swatches
    var _sw_names = ["BG", "M1", "M2", "FG"];
    for (var _s = 0; _s < 4; _s++) {
        var _sx = gfx_swatch_x + _s * 46;
        var _rgb = c64_pal[gfx_col[_s]];
        draw_set_colour(make_colour_rgb(_rgb[0], _rgb[1], _rgb[2]));
        draw_rectangle(_sx, gfx_swatch_y, _sx + 40, gfx_swatch_y + 22, false);
        draw_set_colour(col_border);
        draw_rectangle(_sx, gfx_swatch_y, _sx + 40, gfx_swatch_y + 22, true);
        draw_set_colour(c_black);
        draw_text(_sx + 4, gfx_swatch_y + 5, _sw_names[_s]);
        draw_set_colour(c_white);
        draw_text(_sx + 3, gfx_swatch_y + 4, _sw_names[_s]);
    }

    draw_set_colour(col_dim);
    draw_text(gfx_nudge_text_x, gfx_nudge_text_y, "start $" + scr_ext_hex(gfx_addr, 4));

    if (gfx_dirty || !surface_exists(gfx_surf)) {
        scr_ext_gfx_render();
    }
    draw_surface_ext(gfx_surf, gfx_canvas_x, gfx_canvas_y, gfx_zoom, gfx_zoom, 0, c_white, 1);

    var _pitch_w = (gfx_cell_w + gfx_gap) * gfx_zoom;
    var _pitch_h = (gfx_cell_h + gfx_gap) * gfx_zoom;
    var _iw = gfx_img_w * gfx_zoom;
    var _ih = gfx_img_h * gfx_zoom;

    // Cell grid (characters and bitmaps; sprites already have a gap)
    if (gfx_grid && gfx_gap == 0 && gfx_zoom >= 2) {
        draw_set_alpha(0.25);
        draw_set_colour(col_border);
        for (var _gx = 1; _gx < gfx_row_cols; _gx++) {
            var _lx = gfx_canvas_x + _gx * _pitch_w;
            draw_line(_lx, gfx_canvas_y, _lx, gfx_canvas_y + _ih);
        }
        for (var _gy = 1; _gy < gfx_rows; _gy++) {
            var _ly = gfx_canvas_y + _gy * _pitch_h;
            draw_line(gfx_canvas_x, _ly, gfx_canvas_x + _iw, _ly);
        }
        draw_set_alpha(1);
    }

    // Width handle on the right edge of the image (not in bitmap modes)
    if (!scr_ext_gfx_is_bitmap()) {
        var _hx = gfx_canvas_x + _iw;
        if (gfx_handle_hover || gfx_width_drag) {
            draw_set_colour(col_gfx_range);
        }
        else {
            draw_set_colour(col_border);
        }
        draw_rectangle(_hx + 1, gfx_canvas_y, _hx + 5, gfx_canvas_y + _ih, false);
        var _mid = gfx_canvas_y + _ih / 2;
        draw_set_colour(col_text);
        draw_line(_hx + 3, _mid - 8, _hx + 3, _mid + 8);
    }

    // Selection overlay on the cells it touches
    if (sel_active) {
        draw_set_alpha(0.35);
        draw_set_colour(c_white);
        var _cells = gfx_row_cols * gfx_rows;
        for (var _sc = 0; _sc < _cells; _sc++) {
            var _c1 = gfx_addr + _sc * gfx_cell_bytes;
            var _c2 = _c1 + gfx_cell_bytes - 1;
            if (_c1 <= 0xFFFF && _c2 >= sel_start && _c1 <= sel_end) {
                var _sx1 = gfx_canvas_x + (_sc mod gfx_row_cols) * _pitch_w;
                var _sy1 = gfx_canvas_y + (_sc div gfx_row_cols) * _pitch_h;
                draw_rectangle(_sx1, _sy1, _sx1 + gfx_cell_w * gfx_zoom - 1, _sy1 + gfx_cell_h * gfx_zoom - 1, false);
            }
        }
        draw_set_alpha(1);
    }

    // Cursor cell
    var _rel = (cursor_addr - gfx_addr + 65536) mod 65536;
    if (_rel < gfx_screen_bytes) {
        var _cell = _rel div gfx_cell_bytes;
        var _cx = gfx_canvas_x + (_cell mod gfx_row_cols) * _pitch_w;
        var _cy = gfx_canvas_y + (_cell div gfx_row_cols) * _pitch_h;
        draw_set_colour(c_white);
        draw_rectangle(_cx - 1, _cy - 1, _cx + gfx_cell_w * gfx_zoom, _cy + gfx_cell_h * gfx_zoom, true);
    }

    sb_gfx.value = gfx_addr;
    scr_ext_sb_draw(sb_gfx);
}

/// @desc scr_ext_gfx_align_score(base, mc)
/// Lower = more natural picture. Counts pixel changes between vertically
/// neighbouring image rows, plus across each cell's left/right edge.
/// A wrong start offset leaves a seam where the row wraps, and a wrong byte
/// offset scrambles rows inside the cells - both push the score up.
function scr_ext_gfx_align_score(_base, _mc) {
    var _pc = global.ext_popcount;
    var _s = 0;
    var _ink = 0;
    for (var _y = 0; _y < 200; _y++) {
        var _r0 = _base + (_y div 8) * 320 + (_y mod 8);
        var _r1 = _base + ((_y + 1) div 8) * 320 + ((_y + 1) mod 8);
        var _prev = -1;
        for (var _cx = 0; _cx < 40; _cx++) {
            var _b0 = buffer_peek(mem_buf, (_r0 + _cx * 8) & 0xFFFF, buffer_u8);
            if (_b0 != 0) {
                _ink += 1;
            }
            if (_y < 199) {
                _s += _pc[_b0 ^ buffer_peek(mem_buf, (_r1 + _cx * 8) & 0xFFFF, buffer_u8)];
            }
            if (_prev >= 0) {
                if (_mc) {
                    if ((_prev & 3) != (_b0 >> 6)) {
                        _s += 2;
                    }
                }
                else {
                    if ((_prev & 1) != (_b0 >> 7)) {
                        _s += 1;
                    }
                }
            }
            _prev = _b0;
        }
    }
    if (_ink < 800) {
        return -1;      // mostly empty: not a candidate
    }
    return _s / _ink;
}

/// @desc scr_ext_gfx_auto_align()
/// Searches +/- one character row around the bitmap start, first in whole
/// cells then in single bytes, for the offset where the picture is smoothest.
function scr_ext_gfx_auto_align() {
    if (!scr_ext_gfx_is_bitmap()) {
        status_text = "Align works in the bitmap modes.";
        return;
    }
    var _mc = scr_ext_gfx_is_mc();
    var _best = gfx_addr;
    var _best_s = -1;
    for (var _o = -320; _o <= 320; _o += 8) {
        var _s = scr_ext_gfx_align_score((gfx_addr + _o) & 0xFFFF, _mc);
        if (_s >= 0) {
            if (_best_s < 0 || _s < _best_s) {
                _best_s = _s;
                _best = (gfx_addr + _o) & 0xFFFF;
            }
        }
    }
    // Pictures shown by the VIC sit on $2000 boundaries; stored copies often on $400 ones
    var _bank = gfx_addr - (gfx_addr mod 0x2000);
    for (var _k = -2; _k <= 2; _k++) {
        var _cand = _bank + _k * 0x2000;
        if (_cand >= 0 && _cand <= 0xFFFF) {
            var _sk = scr_ext_gfx_align_score(_cand, _mc);
            if (_sk >= 0) {
                if (_best_s < 0 || _sk < _best_s) {
                    _best_s = _sk;
                    _best = _cand;
                }
            }
        }
    }
    var _kb = gfx_addr - (gfx_addr mod 0x400);
    for (var _k = -4; _k <= 4; _k++) {
        var _cand2 = _kb + _k * 0x400;
        if (_cand2 >= 0 && _cand2 <= 0xFFFF) {
            var _sk2 = scr_ext_gfx_align_score(_cand2, _mc);
            if (_sk2 >= 0) {
                if (_best_s < 0 || _sk2 < _best_s) {
                    _best_s = _sk2;
                    _best = _cand2;
                }
            }
        }
    }

    var _coarse = _best;
    for (var _f = -7; _f <= 7; _f++) {
        var _sf = scr_ext_gfx_align_score((_coarse + _f) & 0xFFFF, _mc);
        if (_sf >= 0) {
            if (_best_s < 0 || _sf < _best_s) {
                _best_s = _sf;
                _best = (_coarse + _f) & 0xFFFF;
            }
        }
    }
    if (_best_s < 0) {
        status_text = "Align: not enough picture data around $" + scr_ext_hex(gfx_addr, 4) + ".";
        return;
    }
    gfx_addr = _best;
    gfx_phase = gfx_addr mod gfx_row_bytes;
    gfx_dirty = true;
    status_text = "Bitmap aligned to $" + scr_ext_hex(gfx_addr, 4) + " (ends $" + scr_ext_hex(gfx_addr + 7999, 4) + "). If it still looks shifted, nudge with the cell / byte buttons, then Find colours.";
}

/// @desc scr_ext_gfx_nudge(bytes) - moves the viewer start by a number of bytes
function scr_ext_gfx_nudge(_bytes) {
    gfx_addr = (gfx_addr + _bytes) & 0xFFFF;
    gfx_phase = gfx_addr mod gfx_row_bytes;
    gfx_dirty = true;
}

/// @desc scr_ext_gfx_colour_score(scr, col, bg, mc, edges)
/// How often neighbouring pixels across cell borders change colour (lower = better).
/// edges holds the bitmap's per-cell edge pixel indices (see scr_ext_gfx_find_colours).
/// Returns -1 when the screen block can't be screen RAM (unloaded / one value).
function scr_ext_gfx_colour_score(_scr, _col, _bg, _mc, _edges) {
    var _counts = array_create(256, 0);
    var _top = 0;
    for (var _c = 0; _c < 1000; _c++) {
        var _a = (_scr + _c) & 0xFFFF;
        if (buffer_peek(loaded_buf, _a, buffer_u8) == 0) {
            return -1;
        }
        var _v = buffer_peek(mem_buf, _a, buffer_u8);
        _counts[_v] += 1;
        if (_counts[_v] > _top) {
            _top = _counts[_v];
        }
    }
    if (_top > 900) {
        return -1;
    }

    // Colour of each pair index (0..3) per cell
    var _pal = array_create(4000, 0);
    for (var _c = 0; _c < 1000; _c++) {
        var _sv = buffer_peek(mem_buf, (_scr + _c) & 0xFFFF, buffer_u8);
        var _cv = gfx_col[3];
        if (_col >= 0) {
            _cv = buffer_peek(mem_buf, (_col + _c) & 0xFFFF, buffer_u8) & 15;
        }
        if (_mc) {
            _pal[_c * 4]     = _bg;
            _pal[_c * 4 + 1] = _sv >> 4;
            _pal[_c * 4 + 2] = _sv & 15;
            _pal[_c * 4 + 3] = _cv;
        }
        else {
            _pal[_c * 4]     = _sv & 15;
            _pal[_c * 4 + 1] = _sv >> 4;
        }
    }

    var _right = _edges[0];
    var _left = _edges[1];
    var _bottom = _edges[2];
    var _topr = _edges[3];
    var _per_h = _edges[4];
    var _mis = 0;
    var _n = 0;
    for (var _cy = 0; _cy < 25; _cy++) {
        for (var _cx = 0; _cx < 40; _cx++) {
            var _cell = _cy * 40 + _cx;
            if (_cx < 39) {
                for (var _r = 0; _r < 8; _r++) {
                    var _p1 = _pal[_cell * 4 + _right[_cell * 8 + _r]];
                    var _p2 = _pal[(_cell + 1) * 4 + _left[(_cell + 1) * 8 + _r]];
                    if (_p1 != _p2) {
                        _mis += 1;
                    }
                    _n += 1;
                }
            }
            if (_cy < 24) {
                for (var _h = 0; _h < _per_h; _h++) {
                    var _q1 = _pal[_cell * 4 + _bottom[_cell * _per_h + _h]];
                    var _q2 = _pal[(_cell + 40) * 4 + _topr[(_cell + 40) * _per_h + _h]];
                    if (_q1 != _q2) {
                        _mis += 1;
                    }
                    _n += 1;
                }
            }
        }
    }
    return _mis / _n;
}

/// @desc scr_ext_gfx_find_colours()
/// Tries the usual places for screen RAM and colour data around the bitmap
/// (Koala / Art Studio offsets, every $400 boundary nearby) and keeps the
/// combination where colours flow most smoothly across cell borders.
function scr_ext_gfx_find_colours() {
    if (!scr_ext_gfx_is_bitmap()) {
        status_text = "Find colours works in the bitmap modes.";
        return;
    }
    var _mc = scr_ext_gfx_is_mc();
    var _bmp = gfx_addr;

    // Edge pixel indices of every cell, read once
    var _per_h = 8;
    if (_mc) {
        _per_h = 4;
    }
    var _right = array_create(8000, 0);
    var _left = array_create(8000, 0);
    var _bottom = array_create(1000 * _per_h, 0);
    var _topr = array_create(1000 * _per_h, 0);
    for (var _c = 0; _c < 1000; _c++) {
        for (var _r = 0; _r < 8; _r++) {
            var _b = buffer_peek(mem_buf, (_bmp + _c * 8 + _r) & 0xFFFF, buffer_u8);
            if (_mc) {
                _right[_c * 8 + _r] = _b & 3;
                _left[_c * 8 + _r] = _b >> 6;
            }
            else {
                _right[_c * 8 + _r] = _b & 1;
                _left[_c * 8 + _r] = _b >> 7;
            }
        }
        var _b7 = buffer_peek(mem_buf, (_bmp + _c * 8 + 7) & 0xFFFF, buffer_u8);
        var _b0 = buffer_peek(mem_buf, (_bmp + _c * 8) & 0xFFFF, buffer_u8);
        for (var _h = 0; _h < _per_h; _h++) {
            if (_mc) {
                _bottom[_c * 4 + _h] = (_b7 >> (6 - _h * 2)) & 3;
                _topr[_c * 4 + _h] = (_b0 >> (6 - _h * 2)) & 3;
            }
            else {
                _bottom[_c * 8 + _h] = (_b7 >> (7 - _h)) & 1;
                _topr[_c * 8 + _h] = (_b0 >> (7 - _h)) & 1;
            }
        }
    }
    var _edges = [_right, _left, _bottom, _topr, _per_h];

    // Screen RAM candidates
    var _cands = [];
    array_push(_cands, _bmp + 8000);
    array_push(_cands, _bmp + 8192);
    array_push(_cands, _bmp - 1024);
    array_push(_cands, _bmp - 2048);
    var _kb = _bmp - (_bmp mod 0x400);
    for (var _k = -16; _k <= 32; _k++) {
        array_push(_cands, _kb + _k * 0x400);
    }

    var _bg = gfx_col[0];
    var _best_scr = -1;
    var _best_s = -1;
    for (var _i = 0; _i < array_length(_cands); _i++) {
        var _s = _cands[_i];
        if (_s < 0 || _s + 1000 > 0x10000) {
            continue;
        }
        // Skip the bitmap itself
        if (_s + 1000 > _bmp && _s < _bmp + 8000) {
            continue;
        }
        var _sc = scr_ext_gfx_colour_score(_s, -1, _bg, _mc, _edges);
        if (_sc >= 0) {
            if (_best_s < 0 || _sc < _best_s) {
                _best_s = _sc;
                _best_scr = _s;
            }
        }
    }
    if (_best_scr < 0) {
        status_text = "Find colours: no screen RAM candidate near $" + scr_ext_hex(_bmp, 4) + ".";
        return;
    }

    // Colour data (multicolour pair 11): usually right after the screen RAM
    var _best_col = -1;
    if (_mc) {
        var _ccands = [];
        array_push(_ccands, _best_scr + 1000);
        array_push(_ccands, _best_scr + 1024);
        array_push(_ccands, _bmp + 9000);
        array_push(_ccands, _bmp + 9216);
        var _ckb = _best_scr - (_best_scr mod 0x400);
        for (var _k = -16; _k <= 16; _k++) {
            array_push(_ccands, _ckb + _k * 0x400);
        }
        var _col_s = _best_s;
        for (var _i = 0; _i < array_length(_ccands); _i++) {
            var _cc = _ccands[_i];
            if (_cc < 0 || _cc + 1000 > 0x10000) {
                continue;
            }
            if (_cc + 1000 > _bmp && _cc < _bmp + 8000) {
                continue;
            }
            if (_cc + 1000 > _best_scr && _cc < _best_scr + 1000) {
                continue;
            }
            var _sc2 = scr_ext_gfx_colour_score(_best_scr, _cc, _bg, _mc, _edges);
            if (_sc2 >= 0 && _sc2 < _col_s) {
                _col_s = _sc2;
                _best_col = _cc;
            }
        }
        _best_s = _col_s;

        // Background: Koala keeps it after the colour data, otherwise try all 16
        var _best_bg = _bg;
        for (var _bgi = 0; _bgi < 16; _bgi++) {
            var _sc3 = scr_ext_gfx_colour_score(_best_scr, _best_col, _bgi, _mc, _edges);
            if (_sc3 >= 0 && _sc3 < _best_s) {
                _best_s = _sc3;
                _best_bg = _bgi;
            }
        }
        gfx_col[0] = _best_bg;
    }

    gfx_scr_addr = _best_scr & 0xFFFF;
    gfx_col_addr = _best_col;
    gfx_use_colour = true;
    gfx_dirty = true;
    var _msg = "Colours: screen RAM $" + scr_ext_hex(gfx_scr_addr, 4);
    if (_best_col >= 0) {
        _msg += ", colour data $" + scr_ext_hex(_best_col, 4);
    }
    else if (_mc) {
        _msg += ", no colour data found (pair 11 uses FG)";
    }
    if (_mc) {
        _msg += ", background " + string(gfx_col[0]);
    }
    status_text = _msg + ".";
}

/// @desc scr_ext_gfx_export_picture()
/// Saves the bitmap in the viewer with its current colours:
///   .kla / .koa  Koala Painter  (multicolour): $6000, bitmap, screen, colour, background
///   .art         Art Studio     (hires):       $2000, bitmap, screen, border (9009 bytes)
///   .png         the picture as you see it (320 x 200)
function scr_ext_gfx_export_picture() {
    if (!scr_ext_gfx_is_bitmap()) {
        status_text = "Export picture works in the bitmap modes - switch to HR or MC Bitmap.";
        return;
    }
    var _mc = scr_ext_gfx_is_mc();
    var _default = "picture_" + scr_ext_hex(gfx_addr, 4);
    var _filter = "";
    if (_mc) {
        _default += ".kla";
        _filter = "Koala Painter|*.kla;*.koa|PNG image|*.png";
    }
    else {
        _default += ".art";
        _filter = "Art Studio hires|*.art|PNG image|*.png";
    }
    var _path = get_save_filename(_filter, _default);
    io_clear();
    last_win_w = 0;
    map_dirty = true;
    gfx_dirty = true;
    if (_path == "") {
        return;
    }
    var _ext = string_lower(filename_ext(_path));

    // ---- PNG: exactly what the viewer shows ----
    if (_ext == ".png") {
        scr_ext_gfx_render();
        surface_save(gfx_surf, _path);
        status_text = "Saved " + filename_name(_path) + " (320 x 200).";
        return;
    }

    // ---- C64 picture file ----
    // Art Studio hires files are 9009 bytes: border byte plus 6 unused after the screen
    var _size = 2 + 8000 + 1000 + 7;
    if (_mc) {
        _size = 2 + 8000 + 1000 + 1000 + 1;
    }
    var _out = buffer_create(_size, buffer_fixed, 1);
    buffer_fill(_out, 0, buffer_u8, 0, _size);
    var _load = 0x2000;
    if (_mc) {
        _load = 0x6000;
    }
    buffer_poke(_out, 0, buffer_u8, _load & 0xFF);
    buffer_poke(_out, 1, buffer_u8, _load >> 8);

    for (var _i = 0; _i < 8000; _i++) {
        buffer_poke(_out, 2 + _i, buffer_u8, buffer_peek(mem_buf, (gfx_addr + _i) & 0xFFFF, buffer_u8));
    }
    // Screen RAM: from memory, else the swatch colours for every cell
    var _scr_fill = (gfx_col[3] << 4) | gfx_col[0];
    if (_mc) {
        _scr_fill = (gfx_col[1] << 4) | gfx_col[2];
    }
    for (var _i = 0; _i < 1000; _i++) {
        var _sv = _scr_fill;
        if (gfx_use_colour && gfx_scr_addr >= 0) {
            _sv = buffer_peek(mem_buf, (gfx_scr_addr + _i) & 0xFFFF, buffer_u8);
        }
        buffer_poke(_out, 8002 + _i, buffer_u8, _sv);
    }
    if (_mc) {
        for (var _i = 0; _i < 1000; _i++) {
            var _cv = gfx_col[3];
            if (gfx_use_colour && gfx_col_addr >= 0) {
                _cv = buffer_peek(mem_buf, (gfx_col_addr + _i) & 0xFFFF, buffer_u8) & 15;
            }
            buffer_poke(_out, 9002 + _i, buffer_u8, _cv);
        }
        buffer_poke(_out, 10002, buffer_u8, gfx_col[0]);
    }
    else {
        buffer_poke(_out, 9002, buffer_u8, gfx_col[0]);
    }
    buffer_save(_out, _path);
    buffer_delete(_out);

    if (_mc) {
        status_text = "Saved Koala picture " + filename_name(_path) + " (10003 bytes, load $6000) - ready for C64 Dev Machine's KLA import.";
    }
    else {
        status_text = "Saved Art Studio hires picture " + filename_name(_path) + " (9009 bytes, load $2000).";
    }
}

/// @desc scr_ext_gfx_export_sprites()
/// Exports sprites exactly as the viewer grid shows them: sprite k starts at
/// gfx_addr + k * 64, so a fine offset (e.g. $8613) is kept, not snapped to $xx00/$xx40.
/// Which sprites: every sprite cell the selection touches, or the whole view if
/// nothing is selected. Up to 64 (C64 Dev Machine's import limit).
///   .spd  SpritePad v3 layout read by SPRED64: 16-byte header ('SPD', 3, flags,
///         count, ..., BG/MC1/MC2 at [13]/[14]/[15]) then 64 bytes per sprite with
///         byte 63 = attribute (bit 7 multicolour, bits 0-3 sprite colour)
///   .bin  the same 64-byte sprites without the header
function scr_ext_gfx_export_sprites() {
    if (!scr_ext_gfx_is_sprite()) {
        status_text = "Export sprites works in the sprite modes - switch to HR or MC Sprite.";
        return;
    }

    // Sprite index range relative to the viewer start
    var _k1 = 0;
    var _k2 = (gfx_screen_bytes div 64) - 1;
    if (sel_active) {
        _k1 = floor((sel_start - gfx_addr) / 64);
        _k2 = floor((sel_end - gfx_addr) / 64);
    }
    var _count = _k2 - _k1 + 1;
    var _capped = false;
    if (_count > 64) {
        _count = 64;
        _capped = true;
    }
    if (_count < 1) {
        status_text = "No sprites to export.";
        return;
    }
    var _first = (gfx_addr + _k1 * 64) & 0xFFFF;

    var _default = "sprites_" + scr_ext_hex(_first, 4) + ".spd";
    var _path = get_save_filename("SpritePad (C64 Dev Machine / SPRED64)|*.spd|Raw 64-byte sprites|*.bin", _default);
    io_clear();
    last_win_w = 0;
    map_dirty = true;
    gfx_dirty = true;
    if (_path == "") {
        return;
    }
    var _spd = true;
    if (string_lower(filename_ext(_path)) == ".bin") {
        _spd = false;
    }

    // Viewer colours -> C64 sprite registers.
    // MC render uses pair 01 = M1, 10 = M2, 11 = FG, which on the C64 are
    // $D025 (MC0), the sprite's own colour, and $D026 (MC1).
    var _mc = scr_ext_gfx_is_mc();
    var _sprite_col = gfx_col[3];
    var _d025 = gfx_col[1];
    var _d026 = gfx_col[2];
    var _attr = gfx_col[3] & 15;
    if (_mc) {
        _sprite_col = gfx_col[2];
        _d026 = gfx_col[3];
        _attr = 0x80 | (_sprite_col & 15);
    }

    var _hdr = 0;
    if (_spd) {
        _hdr = 16;
    }
    var _size = _hdr + _count * 64;
    var _out = buffer_create(_size, buffer_fixed, 1);
    buffer_fill(_out, 0, buffer_u8, 0, _size);
    if (_spd) {
        buffer_poke(_out, 0, buffer_u8, 83);        // 'S'
        buffer_poke(_out, 1, buffer_u8, 80);        // 'P'
        buffer_poke(_out, 2, buffer_u8, 68);        // 'D'
        buffer_poke(_out, 3, buffer_u8, 3);         // version 3 header (16 bytes)
        buffer_poke(_out, 4, buffer_u8, 0);
        buffer_poke(_out, 5, buffer_u8, _count & 0xFF);
        buffer_poke(_out, 6, buffer_u8, (_count >> 8) & 0xFF);
        buffer_poke(_out, 13, buffer_u8, gfx_col[0] & 15);   // BG    ($D021)
        buffer_poke(_out, 14, buffer_u8, _d025 & 15);        // MC1   ($D025)
        buffer_poke(_out, 15, buffer_u8, _d026 & 15);        // MC2   ($D026)
    }
    for (var _k = 0; _k < _count; _k++) {
        var _src = _first + _k * 64;
        var _dst = _hdr + _k * 64;
        for (var _i = 0; _i < 63; _i++) {
            buffer_poke(_out, _dst + _i, buffer_u8, buffer_peek(mem_buf, (_src + _i) & 0xFFFF, buffer_u8));
        }
        buffer_poke(_out, _dst + 63, buffer_u8, _attr);
    }
    buffer_save(_out, _path);
    buffer_delete(_out);

    status_text = "Exported " + string(_count) + " sprites from $" + scr_ext_hex(_first, 4) + " (64-byte steps, offset kept) to " + filename_name(_path);
    if (_capped) {
        status_text += " - capped at 64, the import limit";
    }
}

/// @desc scr_ext_gfx_export_png()
/// Saves exactly what the viewer shows as a PNG, in any mode: a bitmap comes out
/// at 320 x 200 with its colours, chars and sprites as the current grid.
function scr_ext_gfx_export_png() {
    var _default = "view_" + scr_ext_hex(gfx_addr, 4) + ".png";
    if (scr_ext_gfx_is_bitmap()) {
        _default = "bitmap_" + scr_ext_hex(gfx_addr, 4) + ".png";
    }
    var _path = get_save_filename("PNG image|*.png", _default);
    io_clear();
    last_win_w = 0;
    map_dirty = true;
    gfx_dirty = true;
    if (_path == "") {
        return;
    }
    if (string_lower(filename_ext(_path)) != ".png") {
        _path += ".png";
    }
    scr_ext_gfx_render();
    surface_save(gfx_surf, _path);
    status_text = "Saved " + filename_name(_path) + " (" + string(gfx_img_w) + " x " + string(gfx_img_h) + ").";
}

// ---------------------------------------------------------------------------
// Colour picker modal
// ---------------------------------------------------------------------------

/// @desc scr_ext_picker_open(swatch) - opens the 16-colour picker under a swatch
function scr_ext_picker_open(_target) {
    picker_target = _target;
    var _w = picker_cell * 4 + 24;
    var _h = picker_cell * 4 + 60;
    picker_x = gfx_swatch_x + _target * 46;
    picker_y = gfx_swatch_y + 28;
    if (picker_x + _w > gui_w - 8) {
        picker_x = gui_w - 8 - _w;
    }
    if (picker_y + _h > gui_h - 8) {
        picker_y = gui_h - 8 - _h;
    }
    picker_active = true;
}

/// @desc scr_ext_picker_hit(mx, my) - C64 colour under the mouse, or -1
function scr_ext_picker_hit(_mx, _my) {
    var _gx = picker_x + 12;
    var _gy = picker_y + 30;
    for (var _i = 0; _i < 16; _i++) {
        var _cx = _gx + (_i mod 4) * picker_cell;
        var _cy = _gy + (_i div 4) * picker_cell;
        if (point_in_rectangle(_mx, _my, _cx, _cy, _cx + picker_cell - 4, _cy + picker_cell - 4)) {
            return _i;
        }
    }
    return -1;
}

/// @desc scr_ext_picker_draw()
function scr_ext_picker_draw() {
    var _w = picker_cell * 4 + 24;
    var _h = picker_cell * 4 + 60;

    // Dim everything behind it
    draw_set_alpha(0.55);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, gui_w, gui_h, false);
    draw_set_alpha(1);

    draw_set_colour(col_panel);
    draw_rectangle(picker_x, picker_y, picker_x + _w, picker_y + _h, false);
    draw_set_colour(col_title);
    draw_rectangle(picker_x, picker_y, picker_x + _w, picker_y + _h, true);
    var _names = ["BG", "M1", "M2", "FG"];
    draw_text(picker_x + 12, picker_y + 8, "Pick " + _names[picker_target] + " colour   (Esc cancels)");

    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);
    var _hover = scr_ext_picker_hit(_mx, _my);
    var _gx = picker_x + 12;
    var _gy = picker_y + 30;
    for (var _i = 0; _i < 16; _i++) {
        var _cx = _gx + (_i mod 4) * picker_cell;
        var _cy = _gy + (_i div 4) * picker_cell;
        var _rgb = c64_pal[_i];
        draw_set_colour(make_colour_rgb(_rgb[0], _rgb[1], _rgb[2]));
        draw_rectangle(_cx, _cy, _cx + picker_cell - 4, _cy + picker_cell - 4, false);
        draw_set_colour(col_border);
        draw_rectangle(_cx, _cy, _cx + picker_cell - 4, _cy + picker_cell - 4, true);
        if (_i == gfx_col[picker_target]) {
            draw_set_colour(c_white);
            draw_rectangle(_cx - 2, _cy - 2, _cx + picker_cell - 2, _cy + picker_cell - 2, true);
        }
        if (_i == _hover) {
            draw_set_colour(col_gfx_range);
            draw_rectangle(_cx - 3, _cy - 3, _cx + picker_cell - 1, _cy + picker_cell - 1, true);
            draw_rectangle(_cx - 2, _cy - 2, _cx + picker_cell - 2, _cy + picker_cell - 2, true);
        }
        // Index number, in black or white depending on the colour behind it
        var _lum = _rgb[0] * 0.3 + _rgb[1] * 0.59 + _rgb[2] * 0.11;
        if (_lum > 110) {
            draw_set_colour(c_black);
        }
        else {
            draw_set_colour(c_white);
        }
        draw_text(_cx + 4, _cy + 3, string(_i));
    }

    draw_set_colour(col_text);
    var _label = "";
    if (_hover >= 0) {
        _label = string(_hover) + "  " + picker_names[_hover];
    }
    else {
        _label = "current: " + string(gfx_col[picker_target]) + "  " + picker_names[gfx_col[picker_target]];
    }
    draw_text(picker_x + 12, _gy + picker_cell * 4 + 4, _label);
}
