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
    array_push(gfx_buttons, { bx : _bx, by : _by, bw : 60, bh : 22, label : "Cols -", action : "gcols", arg : -1 });
    _bx += 64;
    array_push(gfx_buttons, { bx : _bx, by : _by, bw : 60, bh : 22, label : "Cols +", action : "gcols", arg : 1 });
    _bx += 64;
    array_push(gfx_buttons, { bx : _bx, by : _by, bw : 80, bh : 22, label : "Follow [F]", action : "gfollow", arg : 0 });
    _bx += 84;
    array_push(gfx_buttons, { bx : _bx, by : _by, bw : 70, bh : 22, label : "Grid [G]", action : "ggrid", arg : 0 });
    _bx += 84;

    // Colour swatches: BG, MC1, MC2, FG
    gfx_swatch_x = _bx;
    gfx_swatch_y = _by;

    gfx_canvas_x = gfx_x;
    gfx_canvas_y = gfx_y + 56;
    gfx_canvas_w = gfx_w - EXT_SB_W - 8;
    gfx_canvas_h = gfx_h - 56;
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

    sb_gfx.max_value = 65535;
    sb_gfx.page = gfx_screen_bytes;
    gfx_dirty = true;
}

/// @desc scr_ext_gfx_follow()
/// Moves the viewer to the cursor, aligned to the mode's natural boundary.
function scr_ext_gfx_follow() {
    gfx_addr = cursor_addr - (cursor_addr mod gfx_align);
    gfx_dirty = true;
}

/// @desc scr_ext_gfx_do_button(button, shift)
function scr_ext_gfx_do_button(_b, _shift) {
    switch (_b.action) {
        case "gmode":
            gfx_mode = _b.arg;
            scr_ext_gfx_setup();
            if (gfx_follow) {
                scr_ext_gfx_follow();
            }
            else {
                gfx_addr = gfx_addr - (gfx_addr mod gfx_align);
            }
            break;

        case "gcols":
            if (scr_ext_gfx_is_sprite()) {
                gfx_spr_cols += _b.arg;
                if (gfx_spr_cols < 1) {
                    gfx_spr_cols = 1;
                }
                if (gfx_spr_cols > 16) {
                    gfx_spr_cols = 16;
                }
            }
            else if (!scr_ext_gfx_is_bitmap()) {
                gfx_char_cols += _b.arg;
                if (gfx_char_cols < 1) {
                    gfx_char_cols = 1;
                }
                if (gfx_char_cols > 64) {
                    gfx_char_cols = 64;
                }
            }
            scr_ext_gfx_setup();
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

    for (var _cell = 0; _cell < _cells; _cell++) {
        var _ox = (_cell mod gfx_row_cols) * _pitch_w;
        var _oy = (_cell div gfx_row_cols) * _pitch_h;
        var _cell_base = gfx_addr + _cell * gfx_cell_bytes;

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
                            var _col = _pal4[(_v >> (6 - _pair * 2)) & 3];
                            buffer_poke(gfx_buf, _off + _pair * 8, buffer_u32, _col);
                            buffer_poke(gfx_buf, _off + _pair * 8 + 4, buffer_u32, _col);
                        }
                    }
                    else {
                        for (var _bit = 0; _bit < 8; _bit++) {
                            if (((_v >> (7 - _bit)) & 1) == 1) {
                                buffer_poke(gfx_buf, _off + _bit * 4, buffer_u32, _fg);
                            }
                            else {
                                buffer_poke(gfx_buf, _off + _bit * 4, buffer_u32, _bg);
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
    var _title = "GRAPHICS  " + scr_ext_gfx_mode_name(gfx_mode) + "   $" + scr_ext_hex(gfx_addr, 4) + "-$" + scr_ext_hex(gfx_addr + gfx_screen_bytes - 1, 4) + "   zoom x" + string(gfx_zoom);
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
