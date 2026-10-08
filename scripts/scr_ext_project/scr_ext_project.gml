// ============================================================================
// Project files (.c64x): the 64K memory image exactly as it is now - including
// anything unpacked - plus the viewer, colour, selection and cursor settings.
// Loading a project skips the unpack; classification is simply re-run.
// ============================================================================

#macro EXT_PROJECT_VERSION 1

/// @desc scr_ext_project_save()
function scr_ext_project_save() {
    var _default = "project.c64x";
    if (file_name != "") {
        _default = filename_change_ext(file_name, ".c64x");
    }
    var _path = get_save_filename("Extractor project|*.c64x", _default);
    io_clear();
    last_win_w = 0;
    map_dirty = true;
    gfx_dirty = true;
    if (_path == "") {
        return;
    }
    if (string_lower(filename_ext(_path)) != ".c64x") {
        _path += ".c64x";
    }

    var _d64 = "";
    if (buffer_exists(d64_buf)) {
        _d64 = d64_path;
    }

    var _data = {
        version        : EXT_PROJECT_VERSION,
        file_name      : file_name,
        file_kind      : file_kind,
        is_dump        : is_dump,
        segments       : segments,
        manual_entries : manual_entries,
        mem            : buffer_base64_encode(mem_buf, 0, 65536),
        loaded         : buffer_base64_encode(loaded_buf, 0, 65536),
        d64_path       : _d64,
        d64_selected   : d64_selected,
        cursor_addr    : cursor_addr,
        hex_top        : hex_top,
        dis_top        : dis_top,
        map_shaded     : map_shaded,
        sel_active     : sel_active,
        sel_start      : sel_start,
        sel_end        : sel_end,
        gfx_mode       : gfx_mode,
        gfx_addr       : gfx_addr,
        gfx_char_cols  : gfx_char_cols,
        gfx_spr_cols   : gfx_spr_cols,
        gfx_follow     : gfx_follow,
        gfx_grid       : gfx_grid,
        gfx_col        : gfx_col,
        gfx_use_colour : gfx_use_colour,
        gfx_scr_addr   : gfx_scr_addr,
        gfx_col_addr   : gfx_col_addr,
        gfx_zoom_lock  : gfx_zoom_lock
    };
    var _json = json_stringify(_data);
    var _buf = buffer_create(string_byte_length(_json) + 1, buffer_fixed, 1);
    buffer_write(_buf, buffer_string, _json);
    buffer_save(_buf, _path);
    buffer_delete(_buf);
    status_text = "Project saved: " + filename_name(_path);
}

/// @desc scr_ext_project_load(path)
function scr_ext_project_load(_path) {
    var _buf = buffer_load(_path);
    if (!buffer_exists(_buf)) {
        status_text = "Couldn't read " + _path;
        return false;
    }
    var _json = buffer_read(_buf, buffer_string);
    buffer_delete(_buf);

    var _d = undefined;
    try {
        _d = json_parse(_json);
    }
    catch (_err) {
        status_text = filename_name(_path) + " isn't a valid project file.";
        return false;
    }
    if (!is_struct(_d)) {
        status_text = filename_name(_path) + " isn't a valid project file.";
        return false;
    }
    if (_d.version > EXT_PROJECT_VERSION) {
        status_text = filename_name(_path) + " was saved by a newer version.";
        return false;
    }

    cpu_active = false;
    scr_ext_reset_memory();

    // ---- Memory image ----
    var _mb = buffer_base64_decode(_d.mem);
    buffer_copy(_mb, 0, 65536, mem_buf, 0);
    buffer_delete(_mb);
    var _lb = buffer_base64_decode(_d.loaded);
    buffer_copy(_lb, 0, 65536, loaded_buf, 0);
    buffer_delete(_lb);

    segments = _d.segments;
    manual_entries = _d.manual_entries;
    is_dump = _d.is_dump;

    // ---- D64 listing (only if the disk image is still where it was) ----
    if (buffer_exists(d64_buf)) {
        buffer_delete(d64_buf);
    }
    d64_buf = -1;
    d64_files = [];
    d64_disk_name = "";
    d64_selected = -1;
    d64_scroll = 0;
    d64_path = "";
    if (_d.d64_path != "") {
        if (file_exists(_d.d64_path)) {
            var _img = buffer_load(_d.d64_path);
            if (buffer_exists(_img)) {
                d64_buf = _img;
                d64_path = _d.d64_path;
                if (scr_ext_d64_open(buffer_get_size(_img))) {
                    d64_selected = _d.d64_selected;
                }
                else {
                    buffer_delete(d64_buf);
                    d64_buf = -1;
                    d64_path = "";
                }
            }
        }
    }

    file_path = _path;
    file_name = _d.file_name;
    file_kind = _d.file_kind;

    scr_ext_analyse();

    // ---- Viewer and colour settings ----
    gfx_mode = _d.gfx_mode;
    gfx_char_cols = _d.gfx_char_cols;
    gfx_spr_cols = _d.gfx_spr_cols;
    gfx_follow = _d.gfx_follow;
    gfx_grid = _d.gfx_grid;
    gfx_col = _d.gfx_col;
    gfx_use_colour = _d.gfx_use_colour;
    gfx_scr_addr = _d.gfx_scr_addr;
    gfx_col_addr = _d.gfx_col_addr;
    gfx_zoom_lock = _d.gfx_zoom_lock;
    scr_ext_gfx_setup();
    gfx_addr = _d.gfx_addr;
    gfx_phase = gfx_addr mod gfx_row_bytes;
    gfx_dirty = true;

    // ---- Cursor, views, selection ----
    cursor_addr = _d.cursor_addr;
    hex_top = _d.hex_top;
    scr_ext_clamp_hex_top();
    dis_top = _d.dis_top;
    map_shaded = _d.map_shaded;
    sel_active = _d.sel_active;
    sel_start = _d.sel_start;
    sel_end = _d.sel_end;
    sel_dragging = false;
    map_dirty = true;

    status_text = "Project loaded: " + filename_name(_path);
    return true;
}
