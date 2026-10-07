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
            var _path = get_open_filename("C64 files|*.prg;*.d64;*.bin;*.raw;*.dump;*.crt;*.tap;*.t64|All files|*.*", "");
            io_clear();
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
            if (window_get_fullscreen()) {
                window_set_fullscreen(false);
            }
            else {
                window_set_fullscreen(true);
            }
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
