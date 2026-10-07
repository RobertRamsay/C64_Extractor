/// @desc scr_ext_d64_spt(track) - sectors per track on a 1541 disk.
function scr_ext_d64_spt(_track) {
    if (_track <= 17) {
        return 21;
    }
    if (_track <= 24) {
        return 19;
    }
    if (_track <= 30) {
        return 18;
    }
    return 17;
}

/// @desc scr_ext_d64_offset(track, sector)
/// Byte offset of a sector in the D64 image, or -1 if the T/S is invalid.
function scr_ext_d64_offset(_track, _sector) {
    if (_track < 1 || _track > d64_tracks) {
        return -1;
    }
    if (_sector < 0 || _sector >= scr_ext_d64_spt(_track)) {
        return -1;
    }
    var _o = 0;
    for (var _t = 1; _t < _track; _t++) {
        _o += scr_ext_d64_spt(_t);
    }
    return (_o + _sector) * 256;
}

/// @desc scr_ext_d64_name(offset, max_len)
/// Reads a $A0-padded PETSCII name from the image.
function scr_ext_d64_name(_offset, _max) {
    var _s = "";
    for (var _i = 0; _i < _max; _i++) {
        var _b = buffer_peek(d64_buf, _offset + _i, buffer_u8);
        if (_b == $A0) {
            break;
        }
        _s += scr_ext_petscii_char(_b);
    }
    return _s;
}

/// @desc scr_ext_d64_open(image_size)
/// Validates the image size and reads the directory into d64_files.
function scr_ext_d64_open(_size) {
    d64_files = [];
    d64_disk_name = "";
    d64_selected = -1;
    d64_scroll = 0;

    if (_size == 174848 || _size == 175531) {
        d64_tracks = 35;
    }
    else if (_size == 196608 || _size == 197376) {
        d64_tracks = 40;
    }
    else {
        status_text = "Not a recognised D64 size (" + string(_size) + " bytes).";
        return false;
    }

    var _bam = scr_ext_d64_offset(18, 0);
    d64_disk_name = scr_ext_d64_name(_bam + $90, 16);

    var _type_names = ["DEL", "SEQ", "PRG", "USR", "REL", "???", "???", "???"];
    var _t = 18;
    var _s = 1;
    var _guard = 0;
    while (_t != 0 && _guard < 40) {
        var _o = scr_ext_d64_offset(_t, _s);
        if (_o < 0) {
            break;
        }
        for (var _i = 0; _i < 8; _i++) {
            var _e = _o + _i * 32;
            var _type = buffer_peek(d64_buf, _e + 2, buffer_u8);
            if (_type == 0) {
                continue;
            }
            var _blocks = buffer_peek(d64_buf, _e + 30, buffer_u8) + (buffer_peek(d64_buf, _e + 31, buffer_u8) << 8);
            array_push(d64_files, {
                name     : scr_ext_d64_name(_e + 5, 16),
                type     : _type & 7,
                typename : _type_names[_type & 7],
                track    : buffer_peek(d64_buf, _e + 3, buffer_u8),
                sector   : buffer_peek(d64_buf, _e + 4, buffer_u8),
                blocks   : _blocks
            });
        }
        _t = buffer_peek(d64_buf, _o, buffer_u8);
        _s = buffer_peek(d64_buf, _o + 1, buffer_u8);
        _guard++;
    }

    file_kind = "D64 (" + string(d64_tracks) + " tracks)";
    status_text = "D64 \"" + d64_disk_name + "\": " + string(array_length(d64_files)) + " files.";
    return true;
}

/// @desc scr_ext_d64_extract(track, sector)
/// Follows a file's T/S chain. Returns { buf, len } - caller deletes buf.
function scr_ext_d64_extract(_track, _sector) {
    var _out = buffer_create(4096, buffer_fixed, 1);
    var _len = 0;
    var _t = _track;
    var _s = _sector;
    var _guard = 0;
    while (_guard < 800) {
        var _o = scr_ext_d64_offset(_t, _s);
        if (_o < 0) {
            break;
        }
        var _nt = buffer_peek(d64_buf, _o, buffer_u8);
        var _ns = buffer_peek(d64_buf, _o + 1, buffer_u8);
        var _n = 254;
        if (_nt == 0) {
            // Last sector: _ns is the index of the last used byte
            _n = _ns - 1;
            if (_n < 0) {
                _n = 0;
            }
        }
        if (_n > 0) {
            if (_len + _n > buffer_get_size(_out)) {
                buffer_resize(_out, (_len + _n) * 2);
            }
            buffer_copy(d64_buf, _o + 2, _n, _out, _len);
            _len += _n;
        }
        if (_nt == 0) {
            break;
        }
        _t = _nt;
        _s = _ns;
        _guard++;
    }
    return { buf : _out, len : _len };
}

/// @desc scr_ext_d64_load_entry(index, overlay)
/// Extracts a directory entry and loads it into C64 memory as a PRG.
function scr_ext_d64_load_entry(_index, _overlay) {
    if (!buffer_exists(d64_buf)) {
        return false;
    }
    if (_index < 0 || _index >= array_length(d64_files)) {
        return false;
    }
    var _f = d64_files[_index];
    var _res = scr_ext_d64_extract(_f.track, _f.sector);

    if (!_overlay) {
        scr_ext_reset_memory();
        manual_entries = [];
    }
    var _ok = scr_ext_load_prg_bytes(_res.buf, 0, _res.len, _f.name);
    buffer_delete(_res.buf);

    d64_selected = _index;
    if (_ok) {
        scr_ext_analyse();
        var _n = array_length(segments);
        if (_overlay) {
            scr_ext_set_cursor(segments[_n - 1].start, true);
        }
        else {
            scr_ext_jump_to_start();
        }
    }
    return _ok;
}
