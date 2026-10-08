// ============================================================================
// Whole-disk scan: opens every file on the D64 in turn (unpacking self-extracting
// ones on the way), analyses it, and gathers all graphics and SID findings into
// one list that can be filtered by category. One file is handled per frame.
// Every file's state is kept in d64_cache, so opening a result is instant.
// ============================================================================

#macro EXT_DISK_ALL      0
#macro EXT_DISK_BITMAP   1
#macro EXT_DISK_CHARSET  2
#macro EXT_DISK_SPRITE   3
#macro EXT_DISK_SID      4
#macro EXT_DISK_FILTERS  5

/// @desc scr_ext_disk_category(finding) - which filter a finding belongs to (0 = none)
function scr_ext_disk_category(_f) {
    if (string_pos("SID", _f.kind) == 1) {
        return EXT_DISK_SID;
    }
    if (_f.kind == "Bitmap" || _f.mode == EXT_GFX_BMP_HR || _f.mode == EXT_GFX_BMP_MC) {
        return EXT_DISK_BITMAP;
    }
    if (_f.kind == "Charset" || _f.kind == "Graphics (chars?)") {
        return EXT_DISK_CHARSET;
    }
    if (_f.kind == "Sprite" || _f.kind == "Graphics (sprites?)") {
        return EXT_DISK_SPRITE;
    }
    return 0;
}

/// @desc scr_ext_disk_filter_name(filter)
function scr_ext_disk_filter_name(_k) {
    switch (_k) {
        case EXT_DISK_ALL:     return "All";
        case EXT_DISK_BITMAP:  return "Bitmaps";
        case EXT_DISK_CHARSET: return "Charsets";
        case EXT_DISK_SPRITE:  return "Sprites";
        case EXT_DISK_SID:     return "SIDs";
    }
    return "?";
}

/// @desc scr_ext_disk_scan_start(mode)
/// mode 0 = scan: open every file, unpack what self-extracts, collect findings.
/// mode 1 = unpack all: only visit packed files and unpack them (no findings).
function scr_ext_disk_scan_start(_mode = 0) {
    if (!buffer_exists(d64_buf)) {
        status_text = "This needs a D64 - open one first.";
        return;
    }
    if (cpu_active) {
        status_text = "Wait for the current unpack to finish first.";
        return;
    }
    disk_scan_mode = _mode;
    if (_mode == 0) {
        disk_results = [];
    }
    disk_scan_new = 0;
    disk_file_ran_cpu = false;
    disk_skipped = 0;
    disk_scan_index = 0;
    disk_scan_phase = 0;
    disk_scan_return = d64_selected;
    disk_scan_unpacked = 0;
    disk_scan_active = true;
    disk_open = false;
}

/// @desc scr_ext_disk_scan_step()
/// Called each frame while scanning (and no unpack is running).
function scr_ext_disk_scan_step() {
    var _n = array_length(d64_files);

    // Phase 1: the file opened last frame (and any unpack) is done - collect it
    if (disk_scan_phase == 1) {
        var _i = disk_scan_index;
        if (string_pos("unpacked", file_kind) > 0) {
            disk_scan_unpacked += 1;
            if (disk_file_ran_cpu) {
                disk_scan_new += 1;
            }
        }
        var _still_packed = false;
        var _loaded = 65536 - cls_counts[EXT_CLS_NONE];
        if (_loaded > 0 && cls_counts[EXT_CLS_PACKED] * 10 >= _loaded * 3) {
            _still_packed = true;
            disk_skipped += 1;
        }
        var _collect = array_length(findings);
        if (disk_scan_mode == 1) {
            _collect = 0;       // unpack all: nothing to collect
        }
        for (var _k = 0; _k < _collect; _k++) {
            var _f = findings[_k];
            var _cat = scr_ext_disk_category(_f);
            if (_cat > 0) {
                array_push(disk_results, {
                    file  : _i,
                    fname : d64_files[_i].name,
                    cat   : _cat,
                    kind  : _f.kind,
                    addr  : _f.addr,
                    len   : _f.len,
                    mode  : _f.mode,
                    conf  : _f.conf,
                    why   : _f.why
                });
            }
        }
        disk_scan_index += 1;
        disk_scan_phase = 0;
        return;
    }

    // Phase 0: open the next file (restored from the cache if already done)
    while (disk_scan_index < _n) {
        var _df = d64_files[disk_scan_index];
        var _wanted = (_df.type != 0 && _df.type != 4);
        if (disk_scan_mode == 1 && _wanted) {
            // Unpack all: only packed files that aren't unpacked yet
            if (!_df.packed) {
                _wanted = false;
            }
            else if (scr_ext_cache_has(disk_scan_index)) {
                if (string_pos("unpacked", d64_cache[disk_scan_index].file_kind) > 0) {
                    _wanted = false;
                    disk_scan_unpacked += 1;
                }
            }
        }
        if (_wanted) {
            break;
        }
        disk_scan_index += 1;
    }
    if (disk_scan_index >= _n) {
        scr_ext_disk_scan_finish();
        return;
    }
    scr_ext_d64_load_entry(disk_scan_index, false, false);
    disk_file_ran_cpu = cpu_active;
    var _verb = "Scanning disk: ";
    if (disk_scan_mode == 1) {
        _verb = "Unpacking disk: ";
    }
    status_text = _verb + string(disk_scan_index + 1) + " / " + string(_n) + "  \"" + d64_files[disk_scan_index].name + "\"";
    if (cpu_active) {
        status_text += " - unpacking";
    }
    status_text += "   (Esc stops)";
    disk_scan_phase = 1;
}

/// @desc scr_ext_disk_scan_finish()
function scr_ext_disk_scan_finish() {
    disk_scan_active = false;

    // ---- Unpack all: report and keep, no findings window ----
    if (disk_scan_mode == 1) {
        if (disk_scan_return >= 0) {
            scr_ext_d64_load_entry(disk_scan_return, false, false);
        }
        status_text = "Unpack all: " + string(disk_scan_new) + " files unpacked now";
        if (disk_scan_unpacked > disk_scan_new) {
            status_text += ", " + string(disk_scan_unpacked - disk_scan_new) + " were already unpacked";
        }
        if (disk_skipped > 0) {
            status_text += ", " + string(disk_skipped) + " still packed (no SYS line - loaded by the game's own loader)";
        }
        status_text += ".  Next: 3. Scan disk.";
        if (disk_scan_new > 0) {
            scr_ext_keep_unpacked();
        }
        return;
    }

    // Best first
    array_sort(disk_results, function(_x, _y) {
        return _y.conf - _x.conf;
    });

    // Back to the file that was on screen before
    if (disk_scan_return >= 0) {
        scr_ext_d64_load_entry(disk_scan_return, false, false);
    }

    status_text = "Disk scan: " + string(array_length(disk_results)) + " graphics / SID findings";
    if (disk_scan_unpacked > 0) {
        status_text += ", " + string(disk_scan_unpacked) + " files unpacked";
    }
    if (disk_skipped > 0) {
        status_text += ", " + string(disk_skipped) + " still packed (no SYS line - loaded by the game's own loader)";
    }

    // Keep newly unpacked files: autosave the project, or offer to make one
    if (disk_scan_new > 0) {
        scr_ext_keep_unpacked();
    }
    disk_filter = EXT_DISK_ALL;
    disk_scroll = 0;
    disk_open = true;
}

/// @desc scr_ext_disk_filtered() - results for the current filter
function scr_ext_disk_filtered() {
    var _out = [];
    for (var _i = 0; _i < array_length(disk_results); _i++) {
        if (disk_filter == EXT_DISK_ALL || disk_results[_i].cat == disk_filter) {
            array_push(_out, disk_results[_i]);
        }
    }
    return _out;
}

/// @desc scr_ext_disk_count(filter)
function scr_ext_disk_count(_k) {
    var _c = 0;
    for (var _i = 0; _i < array_length(disk_results); _i++) {
        if (_k == EXT_DISK_ALL || disk_results[_i].cat == _k) {
            _c += 1;
        }
    }
    return _c;
}

/// @desc scr_ext_disk_rect() - [x, y, w, h, list_y, rows, preview_y, preview_h]
function scr_ext_disk_rect() {
    var _w = gui_w - 160;
    if (_w > 1200) {
        _w = 1200;
    }
    var _h = gui_h - 120;
    var _x = floor((gui_w - _w) / 2);
    var _y = 60;
    var _list_y = _y + 80;
    var _prev_h = floor(_h * 0.34);
    if (_prev_h > 260) {
        _prev_h = 260;
    }
    var _prev_y = _y + _h - _prev_h - 8;
    var _rows = floor((_prev_y - 30 - _list_y) / summary_row_h);
    if (_rows < 3) {
        _rows = 3;
    }
    return [_x, _y, _w, _h, _list_y, _rows, _prev_y, _prev_h];
}

/// @desc scr_ext_disk_button_rect(i) - [x, y, w, h] of filter button i (5 = Rescan)
function scr_ext_disk_button_rect(_i) {
    var _r = scr_ext_disk_rect();
    return [_r[0] + 14 + _i * 132, _r[1] + 38, 124, 26];
}

/// @desc scr_ext_disk_open_result(result)
/// Opens the result's file (instantly, from the cache) and jumps to the finding.
function scr_ext_disk_open_result(_res) {
    scr_ext_d64_load_entry(_res.file, false, false);
    for (var _i = 0; _i < array_length(findings); _i++) {
        if (findings[_i].addr == _res.addr && findings[_i].kind == _res.kind) {
            scr_ext_jump_finding(_i);
            return;
        }
    }
    // Not in this file's list any more: go to the address anyway
    if (_res.mode >= 0) {
        gfx_mode = _res.mode;
        gfx_zoom_lock = 0;
        scr_ext_gfx_setup();
    }
    gfx_addr = _res.addr;
    gfx_phase = gfx_addr mod gfx_row_bytes;
    gfx_dirty = true;
    cursor_addr = _res.addr;
    scr_ext_views_to(_res.addr);
}

/// @desc scr_ext_disk_input(mx, my, pressed, wheel)
/// Modal handling for the disk findings window.
function scr_ext_disk_input(_mx, _my, _pressed, _wheel) {
    var _r = scr_ext_disk_rect();
    var _list = scr_ext_disk_filtered();
    var _max = array_length(_list) - _r[5];
    if (_max < 0) {
        _max = 0;
    }
    if (_wheel != 0) {
        disk_scroll += _wheel * 3;
    }
    if (disk_scroll > _max) {
        disk_scroll = _max;
    }
    if (disk_scroll < 0) {
        disk_scroll = 0;
    }
    if (!_pressed) {
        return;
    }
    // Filter buttons and Rescan
    for (var _b = 0; _b <= EXT_DISK_FILTERS; _b++) {
        var _br = scr_ext_disk_button_rect(_b);
        if (point_in_rectangle(_mx, _my, _br[0], _br[1], _br[0] + _br[2], _br[1] + _br[3])) {
            if (_b == EXT_DISK_FILTERS) {
                scr_ext_disk_scan_start(0);
            }
            else {
                disk_filter = _b;
                disk_scroll = 0;
            }
            return;
        }
    }
    // A row
    for (var _i = 0; _i < _r[5]; _i++) {
        var _idx = disk_scroll + _i;
        if (_idx >= array_length(_list)) {
            break;
        }
        var _ry = _r[4] + _i * summary_row_h;
        if (point_in_rectangle(_mx, _my, _r[0] + 8, _ry, _r[0] + _r[2] - 8, _ry + summary_row_h - 1)) {
            disk_open = false;
            scr_ext_disk_open_result(_list[_idx]);
            return;
        }
    }
    // Outside the window closes it
    if (!point_in_rectangle(_mx, _my, _r[0], _r[1], _r[0] + _r[2], _r[1] + _r[3])) {
        disk_open = false;
    }
}

/// @desc scr_ext_disk_draw()
function scr_ext_disk_draw() {
    var _r = scr_ext_disk_rect();
    var _x = _r[0];
    var _y = _r[1];
    var _w = _r[2];
    var _h = _r[3];
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);

    draw_set_alpha(0.55);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, gui_w, gui_h, false);
    draw_set_alpha(1);
    draw_set_colour(col_panel);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_colour(col_title);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
    draw_text(_x + 14, _y + 10, "DISK FINDINGS  \"" + d64_disk_name + "\"   click a row to open it - wheel scrolls - Esc closes");

    // Filter buttons with counts, then Rescan
    for (var _b = 0; _b <= EXT_DISK_FILTERS; _b++) {
        var _br = scr_ext_disk_button_rect(_b);
        var _label = "Rescan disk";
        var _on = false;
        if (_b < EXT_DISK_FILTERS) {
            _label = scr_ext_disk_filter_name(_b) + " (" + string(scr_ext_disk_count(_b)) + ")";
            _on = (_b == disk_filter);
        }
        scr_ext_draw_button({ bx : _br[0], by : _br[1], bw : _br[2], bh : _br[3], label : _label, action : "", arg : 0 }, _on);
    }

    var _list = scr_ext_disk_filtered();
    if (array_length(_list) == 0) {
        draw_set_colour(col_text);
        draw_text(_x + 14, _r[4], "Nothing in this category.");
        return;
    }
    for (var _i = 0; _i < _r[5]; _i++) {
        var _idx = disk_scroll + _i;
        if (_idx >= array_length(_list)) {
            break;
        }
        var _f = _list[_idx];
        var _ry = _r[4] + _i * summary_row_h;
        if (point_in_rectangle(_mx, _my, _x + 8, _ry, _x + _w - 8, _ry + summary_row_h - 1)) {
            draw_set_colour(col_button_on);
            draw_rectangle(_x + 8, _ry, _x + _w - 8, _ry + summary_row_h - 1, false);
        }
        var _cc = EXT_CLS_DOUBT;
        if (_f.conf >= 85) {
            _cc = EXT_CLS_SURE;
        }
        else if (_f.conf >= 60) {
            _cc = EXT_CLS_LIKELY;
        }
        draw_set_colour(scr_ext_cls_colour(_cc));
        draw_set_halign(fa_right);
        draw_text(_x + 62, _ry + 3, string(_f.conf) + "%");
        draw_set_halign(fa_left);
        draw_set_colour(col_text);
        draw_text(_x + 76, _ry + 3, "\"" + _f.fname + "\"");
        draw_text(_x + 250, _ry + 3, _f.kind);
        draw_text(_x + 430, _ry + 3, "$" + scr_ext_hex(_f.addr, 4) + "-$" + scr_ext_hex(_f.addr + _f.len - 1, 4));
        draw_set_colour(col_dim);
        draw_text(_x + 570, _ry + 3, _f.why);
    }
    var _shown_to = disk_scroll + _r[5];
    if (_shown_to > array_length(_list)) {
        _shown_to = array_length(_list);
    }
    draw_set_colour(col_dim);
    draw_text(_x + 14, _r[6] - 24, string(disk_scroll + 1) + "-" + string(_shown_to) + " of " + string(array_length(_list)) + "   (hover a row to preview it below)");

    // ---- Preview strip ----
    var _hover = -1;
    for (var _i = 0; _i < _r[5]; _i++) {
        var _idx = disk_scroll + _i;
        if (_idx >= array_length(_list)) {
            break;
        }
        var _ry = _r[4] + _i * summary_row_h;
        if (point_in_rectangle(_mx, _my, _x + 8, _ry, _x + _w - 8, _ry + summary_row_h - 1)) {
            _hover = _idx;
        }
    }
    scr_ext_disk_preview_draw(_x + 8, _r[6], _w - 16, _r[7], _list, _hover);
}

/// @desc scr_ext_disk_progress_draw() - progress bar while scanning
function scr_ext_disk_progress_draw() {
    var _w = gui_w - 200;
    if (_w > 900) {
        _w = 900;
    }
    var _tw = _w - 28;
    var _th = string_height_ext(status_text, line_h, _tw);
    var _h = 10 + _th + 12 + 16 + 14;
    var _x = floor((gui_w - _w) / 2);
    var _y = floor((gui_h - _h) / 2);
    draw_set_colour(col_panel);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_colour(col_title);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
    draw_text_ext(_x + 14, _y + 10, status_text, line_h, _tw);
    var _n = array_length(d64_files);
    var _p = 0;
    if (_n > 0) {
        _p = disk_scan_index / _n;
    }
    var _by = _y + 10 + _th + 12;
    draw_set_colour(col_sb_track);
    draw_rectangle(_x + 14, _by, _x + _w - 14, _by + 16, false);
    draw_set_colour(col_gfx_range);
    draw_rectangle(_x + 14, _by, _x + 14 + (_w - 28) * _p, _by + 16, false);
}

// ---------------------------------------------------------------------------
// Hover preview in the disk findings window
// ---------------------------------------------------------------------------

/// @desc scr_ext_disk_preview_draw(x, y, w, h, list, hover)
function scr_ext_disk_preview_draw(_x, _y, _w, _h, _list, _hover) {
    draw_set_colour(col_sb_track);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_colour(col_border);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);

    if (_hover < 0) {
        draw_set_colour(col_dim);
        draw_text(_x + 10, _y + 8, "Preview");
        return;
    }
    var _f = _list[_hover];
    if (_f.cat == EXT_DISK_SID) {
        draw_set_colour(col_text);
        draw_text(_x + 10, _y + 8, "\"" + _f.fname + "\"  " + _f.kind + "  $" + scr_ext_hex(_f.addr, 4) + "   " + _f.why);
        draw_set_colour(col_dim);
        draw_text(_x + 10, _y + 8 + line_h, "Click the row to open the file - SID music starts playing (P stops it).");
        return;
    }

    // The file must be on screen or in the cache to be previewed
    if (_f.file != d64_selected && !scr_ext_cache_has(_f.file)) {
        draw_set_colour(col_dim);
        draw_text(_x + 10, _y + 8, "\"" + _f.fname + "\" isn't cached - click the row to open it.");
        return;
    }

    // Re-render only when the hovered result changes (or the surface was lost)
    var _key = string(_f.file) + ":" + string(_f.addr) + ":" + _f.kind;
    if (_key != preview_key || !surface_exists(preview_surf)) {
        var _src = mem_buf;
        if (_f.file != d64_selected && scr_ext_cache_has(_f.file)) {
            _src = d64_cache[_f.file].mem;
        }
        scr_ext_preview_build(_src, _f.mode, _f.addr, _f.len);
        preview_key = _key;
    }

    // Fit the picture into the strip under a one-line caption
    var _ah = _h - line_h - 16;
    var _aw = _w - 20;
    var _scale = floor(_aw / preview_w);
    var _sh = floor(_ah / preview_h);
    if (_sh < _scale) {
        _scale = _sh;
    }
    if (_scale < 1) {
        _scale = min(_aw / preview_w, _ah / preview_h);
    }
    if (_scale > 4) {
        _scale = 4;
    }
    draw_set_colour(col_text);
    var _mode_name = "";
    if (_f.mode >= 0) {
        _mode_name = "  " + scr_ext_gfx_mode_name(_f.mode);
    }
    draw_text(_x + 10, _y + 6, "\"" + _f.fname + "\"  " + _f.kind + "  $" + scr_ext_hex(_f.addr, 4) + "-$" + scr_ext_hex(_f.addr + _f.len - 1, 4) + _mode_name);
    draw_surface_ext(preview_surf, _x + 10, _y + line_h + 10, _scale, _scale, 0, c_white, 1);
}

/// @desc scr_ext_preview_build(source_buffer, mode, addr, length)
/// Renders a finding into preview_surf with the viewer's colours:
/// bitmaps 320 x 200, charsets / char graphics as 32 chars per row (up to 256),
/// sprites 8 per row (up to 16).
function scr_ext_preview_build(_src, _mode, _addr, _len) {
    var _mc = false;
    if (_mode == EXT_GFX_CHAR_MC || _mode == EXT_GFX_SPR_MC || _mode == EXT_GFX_BMP_MC) {
        _mc = true;
    }
    var _spr = false;
    if (_mode == EXT_GFX_SPR_HR || _mode == EXT_GFX_SPR_MC) {
        _spr = true;
    }
    var _cols = 0;
    var _rows = 0;
    var _cw = 8;
    var _ch = 8;
    var _cb = 8;
    var _gap = 0;
    if (_mode == EXT_GFX_BMP_HR || _mode == EXT_GFX_BMP_MC) {
        _cols = 40;
        _rows = 25;
    }
    else if (_spr) {
        var _ns = _len div 64;
        if (_ns < 1) {
            _ns = 1;
        }
        if (_ns > 16) {
            _ns = 16;
        }
        _cols = min(8, _ns);
        _rows = ceil(_ns / _cols);
        _cw = 24;
        _ch = 21;
        _cb = 64;
        _gap = 1;
    }
    else {
        var _nc = _len div 8;
        if (_nc < 1) {
            _nc = 1;
        }
        if (_nc > 256) {
            _nc = 256;
        }
        _cols = min(32, _nc);
        _rows = ceil(_nc / _cols);
    }
    var _pw = _cw + _gap;
    var _ph = _ch + _gap;
    preview_w = _cols * _pw;
    preview_h = _rows * _ph;

    var _size = preview_w * preview_h * 4;
    var _buf = buffer_create(_size, buffer_fixed, 1);
    buffer_fill(_buf, 0, buffer_u32, gfx_gap_u32, _size);
    var _pal = [c64_pal_u32[gfx_col[0]], c64_pal_u32[gfx_col[1]], c64_pal_u32[gfx_col[2]], c64_pal_u32[gfx_col[3]]];
    var _bpr = _cw div 8;
    for (var _cell = 0; _cell < _cols * _rows; _cell++) {
        var _ox = (_cell mod _cols) * _pw;
        var _oy = (_cell div _cols) * _ph;
        var _base = _addr + _cell * _cb;
        for (var _row = 0; _row < _ch; _row++) {
            for (var _bc = 0; _bc < _bpr; _bc++) {
                var _a = _base + _row;
                if (_spr) {
                    _a = _base + _row * 3 + _bc;
                }
                var _v = buffer_peek(_src, _a & 0xFFFF, buffer_u8);
                var _off = (((_oy + _row) * preview_w) + _ox + _bc * 8) * 4;
                if (_mc) {
                    for (var _p = 0; _p < 4; _p++) {
                        var _col = _pal[(_v >> (6 - _p * 2)) & 3];
                        buffer_poke(_buf, _off + _p * 8, buffer_u32, _col);
                        buffer_poke(_buf, _off + _p * 8 + 4, buffer_u32, _col);
                    }
                }
                else {
                    for (var _bit = 0; _bit < 8; _bit++) {
                        if (((_v >> (7 - _bit)) & 1) == 1) {
                            buffer_poke(_buf, _off + _bit * 4, buffer_u32, _pal[3]);
                        }
                        else {
                            buffer_poke(_buf, _off + _bit * 4, buffer_u32, _pal[0]);
                        }
                    }
                }
            }
        }
    }
    if (surface_exists(preview_surf)) {
        if (surface_get_width(preview_surf) != preview_w || surface_get_height(preview_surf) != preview_h) {
            surface_free(preview_surf);
            preview_surf = -1;
        }
    }
    if (!surface_exists(preview_surf)) {
        preview_surf = surface_create(preview_w, preview_h);
    }
    buffer_set_surface(_buf, preview_surf, 0);
    buffer_delete(_buf);
}
