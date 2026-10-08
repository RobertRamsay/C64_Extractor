// ============================================================================
// Project files (.c64x)
//   - the 64K memory image exactly as it is now (including anything unpacked)
//   - viewer, colour, selection and cursor settings
//   - version 2: a copy of the D64 itself, plus the saved state of every file
//     opened from it (unpacked memory + its own view settings)
// Loading a project skips every unpack; classification is simply re-run.
// ============================================================================

#macro EXT_PROJECT_VERSION 3

/// @desc scr_ext_project_save(save_as)
/// Saves over the current project when there is one (unless save_as),
/// otherwise asks for a file name.
function scr_ext_project_save(_save_as) {
    if (project_path != "" && !_save_as) {
        if (scr_ext_project_write(project_path)) {
            autosave_timer = 120;
            status_text = "[autosaving] Project saved over " + filename_name(project_path);
        }
        return;
    }
    var _default = "project.c64x";
    if (project_path != "") {
        _default = filename_name(project_path);
    }
    else if (file_name != "") {
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
    if (scr_ext_project_write(_path)) {
        project_path = _path;
        status_text = "Project saved: " + filename_name(_path);
    }
}

/// @desc scr_ext_keep_unpacked()
/// Called when an unpack finishes so it never has to run again:
/// saves over the open project, or offers to create one.
function scr_ext_keep_unpacked() {
    if (project_path != "") {
        if (scr_ext_project_write(project_path)) {
            autosave_timer = 120;
            status_text += "  [autosaving] -> " + filename_name(project_path);
        }
        return;
    }
    var _yes = show_question("Unpacked successfully.\n\nSave a project now so it opens already unpacked next time?");
    io_clear();
    last_win_w = 0;
    map_dirty = true;
    gfx_dirty = true;
    if (_yes == true || _yes == 1) {
        scr_ext_project_save(true);
    }
}

/// @desc scr_ext_project_write(path) - writes the project file, returns success
function scr_ext_project_write(_path) {
    // The file on screen goes into the cache first, so its latest state is kept
    scr_ext_cache_store(d64_selected);

    var _d64_image = "";
    var _cache_out = [];
    if (buffer_exists(d64_buf)) {
        _d64_image = buffer_base64_encode(d64_buf, 0, buffer_get_size(d64_buf));
        for (var _i = 0; _i < array_length(d64_cache); _i++) {
            var _e = d64_cache[_i];
            if (is_struct(_e)) {
                array_push(_cache_out, {
                    mem            : buffer_base64_encode(_e.mem, 0, 65536),
                    loaded         : buffer_base64_encode(_e.loaded, 0, 65536),
                    segments       : _e.segments,
                    manual_entries : _e.manual_entries,
                    file_name      : _e.file_name,
                    file_kind      : _e.file_kind,
                    is_dump        : _e.is_dump,
                    view           : _e.view
                });
            }
            else {
                array_push(_cache_out, 0);
            }
        }
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
        map_shaded     : map_shaded,
        auto_unpack    : auto_unpack,
        d64_scroll     : d64_scroll,
        view           : scr_ext_view_capture(),
        d64_image      : _d64_image,
        d64_path       : d64_path,
        d64_selected   : d64_selected,
        d64_cache      : _cache_out
    };
    var _json = json_stringify(_data);
    var _buf = buffer_create(string_byte_length(_json) + 1, buffer_fixed, 1);
    buffer_write(_buf, buffer_string, _json);
    buffer_save(_buf, _path);
    buffer_delete(_buf);
    return file_exists(_path);
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

    // ---- D64 ----
    if (buffer_exists(d64_buf)) {
        buffer_delete(d64_buf);
    }
    d64_buf = -1;
    d64_files = [];
    scr_ext_cache_clear();
    d64_disk_name = "";
    d64_selected = -1;
    d64_scroll = 0;
    d64_path = "";
    if (_d.version >= 2) {
        // The project carries its own copy of the disk and every opened file's state
        if (_d.d64_image != "") {
            d64_buf = buffer_base64_decode(_d.d64_image);
            d64_path = _d.d64_path;
            if (scr_ext_d64_open(buffer_get_size(d64_buf))) {
                d64_selected = _d.d64_selected;
                var _n = array_length(_d.d64_cache);
                if (_n > array_length(d64_cache)) {
                    _n = array_length(d64_cache);
                }
                for (var _i = 0; _i < _n; _i++) {
                    var _e = _d.d64_cache[_i];
                    if (is_struct(_e)) {
                        d64_cache[_i] = {
                            mem            : buffer_base64_decode(_e.mem),
                            loaded         : buffer_base64_decode(_e.loaded),
                            segments       : _e.segments,
                            manual_entries : _e.manual_entries,
                            file_name      : _e.file_name,
                            file_kind      : _e.file_kind,
                            is_dump        : _e.is_dump,
                            view           : _e.view
                        };
                    }
                }
            }
            else {
                buffer_delete(d64_buf);
                d64_buf = -1;
            }
        }
    }
    else {
        // Version 1 only remembered where the D64 was
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
    }

    file_path = _path;
    file_name = _d.file_name;
    file_kind = _d.file_kind;

    scr_ext_analyse();

    // ---- Viewer, colours, cursor, selection ----
    if (_d.version >= 2) {
        scr_ext_view_apply(_d.view);
    }
    else {
        scr_ext_view_apply({
            gfx_mode       : _d.gfx_mode,
            gfx_addr       : _d.gfx_addr,
            gfx_char_cols  : _d.gfx_char_cols,
            gfx_spr_cols   : _d.gfx_spr_cols,
            gfx_follow     : _d.gfx_follow,
            gfx_grid       : _d.gfx_grid,
            gfx_col        : _d.gfx_col,
            gfx_use_colour : _d.gfx_use_colour,
            gfx_scr_addr   : _d.gfx_scr_addr,
            gfx_col_addr   : _d.gfx_col_addr,
            gfx_zoom_lock  : _d.gfx_zoom_lock,
            cursor_addr    : _d.cursor_addr,
            hex_top        : _d.hex_top,
            dis_top        : _d.dis_top,
            sel_active     : _d.sel_active,
            sel_start      : _d.sel_start,
            sel_end        : _d.sel_end
        });
    }
    // ---- Project-wide display settings ----
    map_shaded = _d.map_shaded;
    if (_d.version >= 3) {
        auto_unpack = _d.auto_unpack;
        d64_scroll = _d.d64_scroll;
        var _max_scroll = array_length(d64_files) - dir_rows;
        if (d64_scroll > _max_scroll) {
            d64_scroll = _max_scroll;
        }
        if (d64_scroll < 0) {
            d64_scroll = 0;
        }
    }
    map_dirty = true;

    project_path = _path;
    status_text = "Project loaded: " + filename_name(_path);
    return true;
}

// ---------------------------------------------------------------------------
// View state (what a file looks like on screen) and the per-file cache
// ---------------------------------------------------------------------------

/// @desc scr_ext_view_capture() - viewer, colours, cursor and selection as a struct
function scr_ext_view_capture() {
    return {
        gfx_mode       : gfx_mode,
        gfx_addr       : gfx_addr,
        gfx_char_cols  : gfx_char_cols,
        gfx_spr_cols   : gfx_spr_cols,
        gfx_follow     : gfx_follow,
        gfx_grid       : gfx_grid,
        gfx_col        : [gfx_col[0], gfx_col[1], gfx_col[2], gfx_col[3]],
        gfx_use_colour : gfx_use_colour,
        gfx_scr_addr   : gfx_scr_addr,
        gfx_col_addr   : gfx_col_addr,
        gfx_zoom_lock  : gfx_zoom_lock,
        cursor_addr    : cursor_addr,
        hex_top        : hex_top,
        dis_top        : dis_top,
        sel_active     : sel_active,
        sel_start      : sel_start,
        sel_end        : sel_end
    };
}

/// @desc scr_ext_view_apply(view)
function scr_ext_view_apply(_v) {
    gfx_mode = _v.gfx_mode;
    gfx_char_cols = _v.gfx_char_cols;
    gfx_spr_cols = _v.gfx_spr_cols;
    gfx_follow = _v.gfx_follow;
    gfx_grid = _v.gfx_grid;
    gfx_col = [_v.gfx_col[0], _v.gfx_col[1], _v.gfx_col[2], _v.gfx_col[3]];
    gfx_use_colour = _v.gfx_use_colour;
    gfx_scr_addr = _v.gfx_scr_addr;
    gfx_col_addr = _v.gfx_col_addr;
    gfx_zoom_lock = _v.gfx_zoom_lock;
    scr_ext_gfx_setup();
    gfx_addr = _v.gfx_addr;
    gfx_phase = gfx_addr mod gfx_row_bytes;
    gfx_dirty = true;

    cursor_addr = _v.cursor_addr;
    hex_top = _v.hex_top;
    scr_ext_clamp_hex_top();
    dis_top = _v.dis_top;
    sel_active = _v.sel_active;
    sel_start = _v.sel_start;
    sel_end = _v.sel_end;
    sel_dragging = false;
}

/// @desc scr_ext_cache_has(index)
function scr_ext_cache_has(_index) {
    if (_index < 0 || _index >= array_length(d64_cache)) {
        return false;
    }
    return is_struct(d64_cache[_index]);
}

/// @desc scr_ext_cache_drop(index) - forgets one file's saved state
function scr_ext_cache_drop(_index) {
    if (!scr_ext_cache_has(_index)) {
        return;
    }
    var _e = d64_cache[_index];
    buffer_delete(_e.mem);
    buffer_delete(_e.loaded);
    d64_cache[_index] = -1;
}

/// @desc scr_ext_cache_clear() - forgets every file's saved state
function scr_ext_cache_clear() {
    for (var _i = 0; _i < array_length(d64_cache); _i++) {
        scr_ext_cache_drop(_i);
    }
    d64_cache = [];
}

/// @desc scr_ext_cache_store(index)
/// Saves what is in memory now as the state of D64 entry 'index'.
function scr_ext_cache_store(_index) {
    if (!buffer_exists(d64_buf)) {
        return;
    }
    if (_index < 0 || _index >= array_length(d64_cache)) {
        return;
    }
    if (cpu_active) {
        return;     // half-unpacked: not worth keeping
    }
    if (array_length(segments) == 0) {
        return;
    }
    scr_ext_cache_drop(_index);
    var _mem = buffer_create(65536, buffer_fixed, 1);
    var _loaded = buffer_create(65536, buffer_fixed, 1);
    buffer_copy(mem_buf, 0, 65536, _mem, 0);
    buffer_copy(loaded_buf, 0, 65536, _loaded, 0);
    d64_cache[_index] = {
        mem            : _mem,
        loaded         : _loaded,
        segments       : variable_clone(segments),
        manual_entries : variable_clone(manual_entries),
        file_name      : file_name,
        file_kind      : file_kind,
        is_dump        : is_dump,
        view           : scr_ext_view_capture()
    };
}

/// @desc scr_ext_cache_restore(index)
/// Puts a saved file back on screen: memory, entry points, view - no unpacking.
function scr_ext_cache_restore(_index) {
    var _e = d64_cache[_index];
    scr_ext_reset_memory();
    buffer_copy(_e.mem, 0, 65536, mem_buf, 0);
    buffer_copy(_e.loaded, 0, 65536, loaded_buf, 0);
    segments = variable_clone(_e.segments);
    manual_entries = variable_clone(_e.manual_entries);
    file_name = _e.file_name;
    file_kind = _e.file_kind;
    is_dump = _e.is_dump;
    scr_ext_analyse();
    scr_ext_view_apply(_e.view);
    map_dirty = true;
}
