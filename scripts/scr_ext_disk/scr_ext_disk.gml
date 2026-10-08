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

/// @desc scr_ext_disk_scan_start()
function scr_ext_disk_scan_start() {
    if (!buffer_exists(d64_buf)) {
        status_text = "Scan disk needs a D64 - open one first.";
        return;
    }
    if (cpu_active) {
        status_text = "Wait for the current unpack to finish first.";
        return;
    }
    disk_results = [];
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
        }
        var _still_packed = false;
        var _loaded = 65536 - cls_counts[EXT_CLS_NONE];
        if (_loaded > 0 && cls_counts[EXT_CLS_PACKED] * 10 >= _loaded * 3) {
            _still_packed = true;
            disk_skipped += 1;
        }
        for (var _k = 0; _k < array_length(findings); _k++) {
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
        var _type = d64_files[disk_scan_index].type;
        if (_type != 0 && _type != 4) {
            break;
        }
        disk_scan_index += 1;
    }
    if (disk_scan_index >= _n) {
        scr_ext_disk_scan_finish();
        return;
    }
    scr_ext_d64_load_entry(disk_scan_index, false, false);
    status_text = "Scanning disk: " + string(disk_scan_index + 1) + " / " + string(_n) + "  \"" + d64_files[disk_scan_index].name + "\"";
    if (cpu_active) {
        status_text += " - unpacking";
    }
    status_text += "   (Esc stops)";
    disk_scan_phase = 1;
}

/// @desc scr_ext_disk_scan_finish()
function scr_ext_disk_scan_finish() {
    disk_scan_active = false;

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

    // Keep the unpacked files: autosave the project, or offer to make one
    if (disk_scan_unpacked > 0) {
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

/// @desc scr_ext_disk_rect() - [x, y, w, h, list_y, rows]
function scr_ext_disk_rect() {
    var _w = gui_w - 160;
    if (_w > 1200) {
        _w = 1200;
    }
    var _h = gui_h - 120;
    var _x = floor((gui_w - _w) / 2);
    var _y = 60;
    var _list_y = _y + 80;
    var _rows = floor((_h - 80 - 30) / summary_row_h);
    return [_x, _y, _w, _h, _list_y, _rows];
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
                scr_ext_disk_scan_start();
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
    draw_text(_x + 14, _y + _h - 24, string(disk_scroll + 1) + "-" + string(_shown_to) + " of " + string(array_length(_list)) + "   " + status_text);
}

/// @desc scr_ext_disk_progress_draw() - progress bar while scanning
function scr_ext_disk_progress_draw() {
    var _w = 520;
    var _h = 70;
    var _x = floor((gui_w - _w) / 2);
    var _y = floor((gui_h - _h) / 2);
    draw_set_colour(col_panel);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_colour(col_title);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
    draw_text(_x + 14, _y + 10, status_text);
    var _n = array_length(d64_files);
    var _p = 0;
    if (_n > 0) {
        _p = disk_scan_index / _n;
    }
    draw_set_colour(col_sb_track);
    draw_rectangle(_x + 14, _y + 38, _x + _w - 14, _y + 54, false);
    draw_set_colour(col_gfx_range);
    draw_rectangle(_x + 14, _y + 38, _x + 14 + (_w - 28) * _p, _y + 54, false);
}
