/// @desc scr_ext_hex(value, digits)
/// Upper-case hex string, zero padded to the given number of digits.
function scr_ext_hex(_value, _digits) {
    var _chars = "0123456789ABCDEF";
    var _out = "";
    var _v = floor(_value);
    for (var _i = 0; _i < _digits; _i++) {
        var _nib = _v & 0xF;
        _out = string_char_at(_chars, _nib + 1) + _out;
        _v = _v >> 4;
    }
    return _out;
}

/// @desc scr_ext_peek8(addr) - byte from C64 memory, address wraps at 64K.
function scr_ext_peek8(_addr) {
    return buffer_peek(mem_buf, _addr & 0xFFFF, buffer_u8);
}

/// @desc scr_ext_peek16(addr) - little-endian word from C64 memory.
function scr_ext_peek16(_addr) {
    var _lo = buffer_peek(mem_buf, _addr & 0xFFFF, buffer_u8);
    var _hi = buffer_peek(mem_buf, (_addr + 1) & 0xFFFF, buffer_u8);
    return _lo + (_hi << 8);
}

/// @desc scr_ext_is_loaded(addr)
function scr_ext_is_loaded(_addr) {
    return buffer_peek(loaded_buf, _addr & 0xFFFF, buffer_u8) == 1;
}

/// @desc scr_ext_petscii_char(value)
/// Printable character for the hex view's text column and D64 names.
function scr_ext_petscii_char(_v) {
    if (_v >= 0x20 && _v <= 0x5F) {
        return chr(_v);
    }
    if (_v >= 0xC1 && _v <= 0xDA) {
        return chr(_v - 0x80);
    }
    return ".";
}

/// @desc scr_ext_set_cursor(addr, move_views)
/// Sets the cursor; optionally scrolls the hex and disassembly views to it,
/// and moves the graphics viewer too when Follow is on.
function scr_ext_set_cursor(_addr, _move_views) {
    cursor_addr = _addr & 0xFFFF;
    if (_move_views) {
        scr_ext_views_to(cursor_addr);
        if (gfx_follow) {
            scr_ext_gfx_follow();
        }
    }
}

/// @desc scr_ext_views_to(addr)
/// Scrolls the hex and disassembly views to an address (the viewer stays put).
function scr_ext_views_to(_addr) {
    hex_top = (_addr & 0xFFF8) - 8 * 8;
    scr_ext_clamp_hex_top();
    dis_top = scr_ext_align_to_instr(_addr);
}

/// @desc scr_ext_do_action(action, overlay)
/// Shared handler for toolbar buttons and hotkeys.
function scr_ext_do_action(_action, _overlay) {
    switch (_action) {
        case "open":
            var _path = get_open_filename("C64 files and projects|*.prg;*.d64;*.bin;*.raw;*.dump;*.c64x;*.crt;*.tap;*.t64|Extractor project|*.c64x|All files|*.*", "");
            io_clear();
            // Force a full relayout / redraw after the modal dialog
            last_win_w = 0;
            map_dirty = true;
            gfx_dirty = true;
            if (_path != "") {
                scr_ext_load_path(_path, _overlay);
            }
            break;

        case "trace":
            if (scr_ext_is_loaded(cursor_addr)) {
                array_push(manual_entries, cursor_addr);
                scr_ext_analyse();
                status_text = "Traced code from $" + scr_ext_hex(cursor_addr, 4) + " (manual entry point).";
            }
            else {
                status_text = "Cursor is on memory that isn't loaded.";
            }
            break;

        case "analyse":
            scr_ext_analyse();
            break;

        case "fullscreen":
            if (full_window) {
                scr_ext_set_full_window(false);
            }
            else {
                scr_ext_set_full_window(true);
            }
            break;

        case "unpack":
            if (!cpu_active) {
                scr_ext_decrunch_start(scr_ext_unpack_entry());
            }
            break;

        case "saveproject":
            scr_ext_project_save(_overlay);
            break;

        case "saveprojectas":
            scr_ext_project_save(true);
            break;

        case "gexport":
        case "gexppng":
        case "gexpspr":
            scr_ext_gfx_do_button({ action : _action, arg : 0 }, false);
            break;

        case "exit":
            scr_ext_exit();
            break;

        case "deselect":
            sel_active = false;
            sel_dragging = false;
            status_text = "Selection cleared.";
            break;

        case "export":
            scr_ext_export_selection();
            break;

        case "shade":
            if (map_shaded) {
                map_shaded = false;
            }
            else {
                map_shaded = true;
            }
            map_dirty = true;
            break;
    }
}

/// @desc scr_ext_set_full_window(on)
/// on  = borderless window covering the whole display (no exclusive full screen,
///       so file dialogs can't blank the display)
/// off = bordered window at 75% of the display, centred
function scr_ext_set_full_window(_on) {
    full_window = _on;
    if (_on) {
        window_set_showborder(false);
        window_set_position(0, 0);
        window_set_size(display_get_width(), display_get_height());
    }
    else {
        window_set_showborder(true);
        window_set_size(floor(display_get_width() * 0.75), floor(display_get_height() * 0.75));
        window_center();
    }
    last_win_w = 0;
    map_dirty = true;
    gfx_dirty = true;
}

/// @desc scr_ext_sel_set(a, b)
/// Selects the inclusive range between two addresses (either order).
function scr_ext_sel_set(_a, _b) {
    var _x = _a & 0xFFFF;
    var _y = _b & 0xFFFF;
    sel_active = true;
    if (_x <= _y) {
        sel_start = _x;
        sel_end = _y;
    }
    else {
        sel_start = _y;
        sel_end = _x;
    }
}

/// @desc scr_ext_sel_region()
/// Selects the run of bytes around the cursor that share its classification
/// (e.g. one block of green code or one red data block).
function scr_ext_sel_region() {
    var _c = buffer_peek(cls_buf, cursor_addr, buffer_u8);
    var _a = cursor_addr;
    while (_a > 0) {
        if (buffer_peek(cls_buf, _a - 1, buffer_u8) != _c) {
            break;
        }
        _a -= 1;
    }
    var _b = cursor_addr;
    while (_b < 0xFFFF) {
        if (buffer_peek(cls_buf, _b + 1, buffer_u8) != _c) {
            break;
        }
        _b += 1;
    }
    scr_ext_sel_set(_a, _b);
}

/// @desc scr_ext_in_select_panel(mx, my)
/// True when the point is over a panel that supports Shift+drag selection.
function scr_ext_in_select_panel(_mx, _my) {
    var _map_size = 256 * map_scale;
    if (point_in_rectangle(_mx, _my, map_x, map_y, map_x + _map_size - 1, map_y + _map_size - 1)) {
        return true;
    }
    if (point_in_rectangle(_mx, _my, gfx_canvas_x, gfx_canvas_y, gfx_canvas_x + gfx_canvas_w, gfx_canvas_y + gfx_canvas_h)) {
        return true;
    }
    if (point_in_rectangle(_mx, _my, hex_x, hex_y, hex_x + hex_w - EXT_SB_W - 6, hex_y + hex_rows * line_h - 1)) {
        return true;
    }
    if (point_in_rectangle(_mx, _my, dis_x, dis_y, dis_x + dis_w - EXT_SB_W - 6, dis_y + dis_rows * line_h - 1)) {
        return true;
    }
    return false;
}

/// @desc scr_ext_export_selection()
/// Saves the selection as raw binary, or as a PRG (2-byte load address first)
/// when the chosen file name ends in .prg.
function scr_ext_export_selection() {
    if (!sel_active) {
        status_text = "Nothing selected - Shift+drag over memory, or press W to select a region.";
        return;
    }
    var _len = sel_end - sel_start + 1;
    var _default = "ext_" + scr_ext_hex(sel_start, 4) + "-" + scr_ext_hex(sel_end, 4) + ".bin";
    var _path = get_save_filename("Raw binary|*.bin|PRG with load address|*.prg|All files|*.*", _default);
    io_clear();
    last_win_w = 0;
    map_dirty = true;
    gfx_dirty = true;
    if (_path == "") {
        return;
    }

    var _prg = false;
    if (string_lower(filename_ext(_path)) == ".prg") {
        _prg = true;
    }
    var _hdr = 0;
    if (_prg) {
        _hdr = 2;
    }

    var _out = buffer_create(_len + _hdr, buffer_fixed, 1);
    if (_prg) {
        buffer_poke(_out, 0, buffer_u8, sel_start & 0xFF);
        buffer_poke(_out, 1, buffer_u8, sel_start >> 8);
    }
    buffer_copy(mem_buf, sel_start, _len, _out, _hdr);
    buffer_save(_out, _path);
    buffer_delete(_out);

    var _missing = 0;
    for (var _i = sel_start; _i <= sel_end; _i++) {
        if (buffer_peek(loaded_buf, _i, buffer_u8) == 0) {
            _missing += 1;
        }
    }
    status_text = "Exported " + string(_len) + " bytes to " + filename_name(_path);
    if (_prg) {
        status_text += " (PRG, load $" + scr_ext_hex(sel_start, 4) + ")";
    }
    if (_missing > 0) {
        status_text += " - " + string(_missing) + " bytes were not loaded (saved as $00)";
    }
}

/// @desc scr_ext_exit()
/// Quits. An open project is saved first; unsaved work gets one question.
function scr_ext_exit() {
    cpu_active = false;
    if (project_path != "") {
        scr_ext_project_write(project_path);
        game_end();
        return;
    }
    if (array_length(segments) > 0) {
        var _quit = show_question("Exit without saving a project?\n\nChoose No to save one first.");
        io_clear();
        last_win_w = 0;
        if (_quit == false || _quit == 0) {
            scr_ext_project_save(true);
            if (project_path == "") {
                return;     // save cancelled: stay open
            }
        }
    }
    game_end();
}

/// @desc scr_ext_menu_hit(mx, my) - index of the menu item under the mouse, or -1
function scr_ext_menu_hit(_mx, _my) {
    for (var _i = 0; _i < array_length(menu_items); _i++) {
        var _iy = menu_y + 4 + _i * menu_item_h;
        if (point_in_rectangle(_mx, _my, menu_x, _iy, menu_x + menu_w, _iy + menu_item_h - 1)) {
            if (menu_items[_i].action != "") {
                return _i;
            }
            return -1;
        }
    }
    return -1;
}

/// @desc scr_ext_menu_draw()
function scr_ext_menu_draw() {
    var _h = array_length(menu_items) * menu_item_h + 8;
    draw_set_colour(col_panel);
    draw_rectangle(menu_x, menu_y, menu_x + menu_w, menu_y + _h, false);
    draw_set_colour(col_title);
    draw_rectangle(menu_x, menu_y, menu_x + menu_w, menu_y + _h, true);

    var _hover = scr_ext_menu_hit(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0));
    for (var _i = 0; _i < array_length(menu_items); _i++) {
        var _it = menu_items[_i];
        var _iy = menu_y + 4 + _i * menu_item_h;
        if (_it.label == "-") {
            draw_set_colour(col_border);
            draw_line(menu_x + 8, _iy + menu_item_h / 2, menu_x + menu_w - 8, _iy + menu_item_h / 2);
            continue;
        }
        if (_i == _hover) {
            draw_set_colour(col_button_on);
            draw_rectangle(menu_x + 2, _iy, menu_x + menu_w - 2, _iy + menu_item_h - 1, false);
        }
        draw_set_colour(col_text);
        draw_text(menu_x + 12, _iy + 5, _it.label);
        draw_set_colour(col_dim);
        draw_set_halign(fa_right);
        draw_text(menu_x + menu_w - 12, _iy + 5, _it.key);
        draw_set_halign(fa_left);
    }
}
