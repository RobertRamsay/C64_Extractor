/// @desc scr_ext_reset_memory()
/// Clears the 64K image and everything derived from it.
function scr_ext_reset_memory() {
    buffer_fill(mem_buf,    0, buffer_u8, 0, 65536);
    buffer_fill(loaded_buf, 0, buffer_u8, 0, 65536);
    buffer_fill(cls_buf,    0, buffer_u8, 0, 65536);
    buffer_fill(istart_buf, 0, buffer_u8, 0, 65536);
    buffer_fill(entry_buf,  0, buffer_u8, 0, 65536);
    segments = [];
    entries = [];
    is_dump = false;
    cls_counts = array_create(EXT_CLS_COUNT, 0);
    map_dirty = true;
}

/// @desc scr_ext_load_path(path, overlay)
/// Loads a PRG, a D64 or a raw 64K memory dump.
/// overlay = true keeps what is already in memory (multi-load games).
function scr_ext_load_path(_path, _overlay) {
    if (!file_exists(_path)) {
        status_text = "File not found: " + _path;
        return false;
    }

    var _ext = string_lower(filename_ext(_path));
    if (_ext == ".crt" || _ext == ".tap" || _ext == ".t64") {
        status_text = string_upper(_ext) + " files aren't supported yet (later phase).";
        return false;
    }

    var _buf = buffer_load(_path);
    if (!buffer_exists(_buf)) {
        status_text = "Couldn't read " + _path;
        return false;
    }
    var _size = buffer_get_size(_buf);

    file_path = _path;
    file_name = filename_name(_path);

    // ---- D64: keep the image, list the directory, auto-load the first PRG ----
    if (_ext == ".d64") {
        if (buffer_exists(d64_buf)) {
            buffer_delete(d64_buf);
        }
        d64_buf = _buf;
        if (!scr_ext_d64_open(_size)) {
            buffer_delete(d64_buf);
            d64_buf = -1;
            return false;
        }
        var _first = -1;
        for (var _i = 0; _i < array_length(d64_files); _i++) {
            if (d64_files[_i].type == 2) {
                _first = _i;
                break;
            }
        }
        if (_first >= 0) {
            scr_ext_d64_load_entry(_first, _overlay);
        }
        else {
            if (!_overlay) {
                scr_ext_reset_memory();
                manual_entries = [];
            }
            status_text = "D64 opened, no PRG files found.";
        }
        return true;
    }

    // ---- Anything else replaces the D64 listing ----
    if (buffer_exists(d64_buf)) {
        buffer_delete(d64_buf);
    }
    d64_buf = -1;
    d64_files = [];
    d64_disk_name = "";
    d64_selected = -1;
    d64_scroll = 0;

    if (!_overlay) {
        scr_ext_reset_memory();
        manual_entries = [];
    }

    var _ok = false;
    if (_size == 65536) {
        // Raw memory dump, e.g. VICE monitor:  save "dump.bin" 0 0000 ffff
        buffer_copy(_buf, 0, 65536, mem_buf, 0);
        buffer_fill(loaded_buf, 0, buffer_u8, 1, 65536);
        is_dump = true;
        array_push(segments, { start : 0, finish : $FFFF, name : file_name });
        file_kind = "64K memory dump";
        _ok = true;
    }
    else {
        _ok = scr_ext_load_prg_bytes(_buf, 0, _size, file_name);
        file_kind = "PRG";
    }
    buffer_delete(_buf);

    if (_ok) {
        scr_ext_analyse();
        scr_ext_jump_to_start();
    }
    return _ok;
}

/// @desc scr_ext_load_prg_bytes(src_buffer, offset, length, name)
/// Copies PRG data (2-byte load address + payload) into C64 memory.
function scr_ext_load_prg_bytes(_src, _offset, _len, _name) {
    if (_len < 3) {
        status_text = _name + " is too short to be a PRG.";
        return false;
    }
    var _lo = buffer_peek(_src, _offset, buffer_u8);
    var _hi = buffer_peek(_src, _offset + 1, buffer_u8);
    var _load = _lo + (_hi << 8);
    var _count = _len - 2;
    if (_load + _count > 65536) {
        _count = 65536 - _load;
    }
    buffer_copy(_src, _offset + 2, _count, mem_buf, _load);
    buffer_fill(loaded_buf, _load, buffer_u8, 1, _count);
    array_push(segments, { start : _load, finish : _load + _count - 1, name : _name });
    status_text = "Loaded " + _name + " at $" + scr_ext_hex(_load, 4) + "-$" + scr_ext_hex(_load + _count - 1, 4);
    return true;
}

/// @desc scr_ext_jump_to_start()
/// Moves the cursor to the first entry point, or the start of the last loaded segment.
function scr_ext_jump_to_start() {
    if (array_length(entries) > 0) {
        scr_ext_set_cursor(entries[0].addr, true);
        return;
    }
    var _n = array_length(segments);
    if (_n > 0) {
        scr_ext_set_cursor(segments[_n - 1].start, true);
    }
}
