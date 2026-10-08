// ============================================================================
// Detection passes run by scr_ext_analyse, in this order:
//   1. VIC clues   - constant values the traced code writes to VIC registers
//   2. packed      - high-entropy pages (crunched data: Exomizer and friends)
//   3. text        - PETSCII / screen-code runs
//   4. graphics    - shape heuristic on 64-byte blocks
// Each pass only claims bytes that are still EXT_CLS_UNKNOWN, so traced code
// always wins and the code/junk scoring only sees what is left.
// ============================================================================

/// @desc scr_ext_popcount_table() - number of set bits for every byte value
function scr_ext_popcount_table() {
    var _t = array_create(256, 0);
    for (var _i = 0; _i < 256; _i++) {
        var _v = _i;
        var _n = 0;
        while (_v > 0) {
            _n += _v & 1;
            _v = _v >> 1;
        }
        _t[_i] = _n;
    }
    return _t;
}

/// @desc scr_ext_entropy_from_counts(counts, n) - Shannon entropy in bits per byte
function scr_ext_entropy_from_counts(_counts, _n) {
    if (_n <= 0) {
        return 0;
    }
    var _h = 0;
    for (var _i = 0; _i < 256; _i++) {
        var _c = _counts[_i];
        if (_c > 0) {
            var _p = _c / _n;
            _h -= _p * log2(_p);
        }
    }
    return _h;
}

/// @desc scr_ext_entropy_buf(buffer, offset, length)
function scr_ext_entropy_buf(_buf, _off, _len) {
    var _counts = array_create(256, 0);
    for (var _i = 0; _i < _len; _i++) {
        var _v = buffer_peek(_buf, _off + _i, buffer_u8);
        _counts[_v] += 1;
    }
    return scr_ext_entropy_from_counts(_counts, _len);
}

/// @desc scr_ext_packed_threshold(n)
/// Random bytes measure ~7.8 bits over 1024 samples and ~7.6 over 512,
/// 6502 code sits around 6-7, so the cut-off depends on the sample size.
function scr_ext_packed_threshold(_n) {
    if (_n >= 1024) {
        return 7.4;
    }
    return 7.15;
}

/// @desc scr_ext_mark_unknown(start, length, cls)
/// Claims loaded, still-unknown bytes in a range for a class.
function scr_ext_mark_unknown(_start, _len, _cls) {
    for (var _i = 0; _i < _len; _i++) {
        var _a = _start + _i;
        if (_a > 0xFFFF) {
            break;
        }
        if (buffer_peek(cls_buf, _a, buffer_u8) == EXT_CLS_UNKNOWN) {
            buffer_poke(cls_buf, _a, buffer_u8, _cls);
        }
    }
}

// ---------------------------------------------------------------------------
// 1. VIC clues
// ---------------------------------------------------------------------------

/// @desc scr_ext_find_vic_writes()
/// Walks traced code in address order tracking immediate values in A/X/Y,
/// and records every absolute store of a known value: { target, value, at }.
function scr_ext_find_vic_writes() {
    var _writes = [];
    var _ops = global.ext_ops;
    var _ra = -1;
    var _rx = -1;
    var _ry = -1;
    var _next = -1;

    for (var _a = 0; _a < 65536; _a++) {
        if (buffer_peek(istart_buf, _a, buffer_u8) != 1) {
            continue;
        }
        var _c = buffer_peek(cls_buf, _a, buffer_u8);
        if (_c != EXT_CLS_SURE && _c != EXT_CLS_LIKELY) {
            continue;
        }
        // New flow (gap, or an entry point): register contents unknown
        if (_a != _next || buffer_peek(entry_buf, _a, buffer_u8) == 1) {
            _ra = -1;
            _rx = -1;
            _ry = -1;
        }

        var _op = _ops[buffer_peek(mem_buf, _a, buffer_u8)];
        var _imm = -1;
        if (_op.mode == EXT_MODE_IMM) {
            _imm = scr_ext_peek8(_a + 1);
        }

        if (_op.mode == EXT_MODE_ABS) {
            var _v = -1;
            if (_op.mn == "STA") {
                _v = _ra;
            }
            else if (_op.mn == "STX") {
                _v = _rx;
            }
            else if (_op.mn == "STY") {
                _v = _ry;
            }
            if (_v >= 0) {
                array_push(_writes, { target : scr_ext_peek16(_a + 1), value : _v, at : _a, cls : _c });
            }
        }

        switch (_op.mn) {
            case "LDA":
                _ra = _imm;
                // Read-modify-write of a VIC / CIA register: start from its power-on value
                if (_op.mode == EXT_MODE_ABS) {
                    var _src = scr_ext_peek16(_a + 1);
                    if (_src == 0xD011) {
                        _ra = 0x1B;
                    }
                    else if (_src == 0xD016) {
                        _ra = 0xC8;
                    }
                    else if (_src == 0xD018) {
                        _ra = 0x15;
                    }
                    else if (_src == 0xDD00) {
                        _ra = 0x97;
                    }
                }
                break;
            case "AND":
            case "ORA":
            case "EOR":
                // Constant folding: LDA $D011 / ORA #$20 / STA $D011 is understood
                if (_op.mode == EXT_MODE_IMM && _ra >= 0) {
                    if (_op.mn == "AND") {
                        _ra = _ra & _imm;
                    }
                    else if (_op.mn == "ORA") {
                        _ra = _ra | _imm;
                    }
                    else {
                        _ra = _ra ^ _imm;
                    }
                }
                else {
                    _ra = -1;
                }
                break;
            case "LDX": _rx = _imm; break;
            case "LDY": _ry = _imm; break;
            case "TAX": _rx = _ra; break;
            case "TAY": _ry = _ra; break;
            case "TXA": _ra = _rx; break;
            case "TYA": _ra = _ry; break;
            case "INX": case "DEX": case "TSX": case "SBX":
                _rx = -1;
                break;
            case "INY": case "DEY":
                _ry = -1;
                break;
            case "LAX":
                _ra = -1;
                _rx = -1;
                break;
            case "ADC": case "SBC": case "PLA":
            case "ANC": case "ALR": case "ARR": case "ISC": case "RRA": case "SLO":
            case "SRE": case "RLA": case "ANE": case "LXA": case "LAS":
                _ra = -1;
                break;
            case "ASL": case "LSR": case "ROL": case "ROR":
                if (_op.mode == EXT_MODE_ACC) {
                    _ra = -1;
                }
                break;
            case "JSR":
                _ra = -1;
                _rx = -1;
                _ry = -1;
                break;
        }

        _next = (_a + _op.size) & 0xFFFF;
        if (_op.flow == EXT_FLOW_STOP || _op.flow == EXT_FLOW_JMP) {
            _next = -1;
        }
    }
    return _writes;
}

/// @desc scr_ext_add_clue(addr, length, kind, mode, why)
function scr_ext_add_clue(_addr, _len, _kind, _mode, _why) {
    var _a = _addr & 0xFFFF;
    for (var _i = 0; _i < array_length(vic_clues); _i++) {
        if (vic_clues[_i].addr == _a && vic_clues[_i].kind == _kind) {
            return false;
        }
    }
    array_push(vic_clues, { addr : _a, len : _len, kind : _kind, mode : _mode, why : _why, scr : -1, conf : clue_base_conf });
    return true;
}

/// @desc scr_ext_apply_vic_clues(writes)
/// Turns VIC register writes into clue regions (charset, bitmap, screen, sprites)
/// and marks the graphics ones blue.
function scr_ext_apply_vic_clues(_writes) {
    vic_clues = [];
    clue_index = -1;

    var _banks = [];
    var _bitmap = false;
    var _mc = false;
    var _spr_mc = false;
    for (var _i = 0; _i < array_length(_writes); _i++) {
        var _w = _writes[_i];
        if (_w.target == 0xDD00) {
            var _b = (3 - (_w.value & 3)) * 0x4000;
            var _known = false;
            for (var _k = 0; _k < array_length(_banks); _k++) {
                if (_banks[_k] == _b) {
                    _known = true;
                }
            }
            if (!_known) {
                array_push(_banks, _b);
            }
        }
        if (_w.target == 0xD011 && (_w.value & 0x20) != 0) {
            _bitmap = true;
        }
        if (_w.target == 0xD016 && (_w.value & 0x10) != 0) {
            _mc = true;
        }
        if (_w.target == 0xD01C && _w.value != 0) {
            _spr_mc = true;
        }
    }
    if (array_length(_banks) == 0) {
        array_push(_banks, 0);
    }

    for (var _i = 0; _i < array_length(_writes); _i++) {
        var _w = _writes[_i];
        var _why = "$" + scr_ext_hex(_w.target, 4) + "=$" + scr_ext_hex(_w.value, 2) + " @ $" + scr_ext_hex(_w.at, 4);
        // Writes in code traced from a strong entry are certain; weaker ones less so
        clue_base_conf = 100;
        if (_w.cls != EXT_CLS_SURE) {
            clue_base_conf = 85;
        }

        // $D018: screen, charset and bitmap locations inside each VIC bank
        if (_w.target == 0xD018) {
            for (var _k = 0; _k < array_length(_banks); _k++) {
                var _base = _banks[_k];
                scr_ext_add_clue(_base + ((_w.value >> 4) & 15) * 0x400, 1000, "Screen", -1, _why);

                if (_bitmap) {
                    var _bm = _base + ((_w.value >> 3) & 1) * 0x2000;
                    var _bmode = EXT_GFX_BMP_HR;
                    if (_mc) {
                        _bmode = EXT_GFX_BMP_MC;
                    }
                    if (scr_ext_add_clue(_bm, 8000, "Bitmap", _bmode, _why)) {
                        scr_ext_mark_unknown(_bm, 8000, EXT_CLS_GFX);
                        // Same $D018 write gives the screen RAM holding its colours
                        vic_clues[array_length(vic_clues) - 1].scr = (_base + ((_w.value >> 4) & 15) * 0x400) & 0xFFFF;
                    }
                }

                var _cs = _base + ((_w.value >> 1) & 7) * 0x800;
                // Banks 0 and 2 see the character ROM at +$1000-$1FFF
                var _rom = false;
                if (_base == 0x0000 || _base == 0x8000) {
                    var _off = _cs & 0x3FFF;
                    if (_off == 0x1000 || _off == 0x1800) {
                        _rom = true;
                    }
                }
                if (!_rom) {
                    var _cmode = EXT_GFX_CHAR_HR;
                    if (_mc) {
                        _cmode = EXT_GFX_CHAR_MC;
                    }
                    if (scr_ext_add_clue(_cs, 2048, "Charset", _cmode, _why)) {
                        scr_ext_mark_unknown(_cs, 2048, EXT_CLS_GFX);
                    }
                }
            }
        }

        // Sprite pointers: screen + $3F8..$3FF
        if (_w.target >= 0x0400 && (_w.target & 0x3FF) >= 0x3F8) {
            if ((_w.target < 0xD000 || _w.target >= 0xE000) && _w.target < 0xFFF8) {
                var _sp = (_w.target & 0xC000) + _w.value * 64;
                var _smode = EXT_GFX_SPR_HR;
                if (_spr_mc) {
                    _smode = EXT_GFX_SPR_MC;
                }
                if (scr_ext_add_clue(_sp, 64, "Sprite", _smode, _why)) {
                    scr_ext_mark_unknown(_sp, 64, EXT_CLS_GFX);
                }
            }
        }
    }
}

/// @desc scr_ext_jump_clue()
/// J: steps to the next finding (VIC clues first, then detected graphics / text / packed).
function scr_ext_jump_clue() {
    var _n = array_length(findings);
    if (_n == 0) {
        status_text = "No findings yet - press R to analyse.";
        return;
    }
    clue_index = (clue_index + 1) mod _n;
    scr_ext_jump_finding(clue_index);
}

/// @desc scr_ext_jump_finding(index)
/// Puts the viewer (mode, address, colours) and the cursor on a finding.
function scr_ext_jump_finding(_index) {
    clue_index = _index;
    var _c = findings[_index];
    if (_c.mark >= 0) {
        scr_ext_mark_apply(user_marks[_c.mark]);
        status_text = "Finding " + string(_index + 1) + "/" + string(array_length(findings)) + ": " + scr_ext_finding_text(_c);
        return;
    }
    if (_c.mode >= 0) {
        gfx_mode = _c.mode;
        gfx_zoom_lock = 0;
        scr_ext_gfx_setup();
    }
    gfx_addr = _c.addr;
    gfx_phase = gfx_addr mod gfx_row_bytes;
    if (_c.kind == "Bitmap" && _c.scr >= 0) {
        gfx_scr_addr = _c.scr;
        gfx_use_colour = true;
    }
    gfx_dirty = true;
    cursor_addr = _c.addr;
    scr_ext_views_to(_c.addr);
    if (_c.kind == "Bitmap" && _c.scr < 0) {
        scr_ext_gfx_find_colours();
    }
    status_text = "Finding " + string(_index + 1) + "/" + string(array_length(findings)) + ": " + scr_ext_finding_text(_c);
    if (_c.kind == "SID music" && _c.init >= 0) {
        scr_ext_sid_start(_c.init, _c.play, 0);
    }
}

/// @desc scr_ext_finding_text(finding) - one line for the status bar / summary
function scr_ext_finding_text(_c) {
    var _t = _c.kind + " at $" + scr_ext_hex(_c.addr, 4) + "-$" + scr_ext_hex(_c.addr + _c.len - 1, 4);
    _t += "   " + string(_c.conf) + "% confidence";
    if (_c.why != "") {
        _t += "   (" + _c.why + ")";
    }
    return _t;
}

/// @desc scr_ext_region_gfx_fraction(addr, length)
/// Share (0..1) of the region's 64-byte blocks that look like graphics:
/// loaded, not all one value, and smooth from row to row.
function scr_ext_region_gfx_fraction(_addr, _len) {
    var _pc = global.ext_popcount;
    var _blocks = _len div 64;
    if (_blocks < 1) {
        _blocks = 1;
    }
    var _good = 0;
    for (var _b = 0; _b < _blocks; _b++) {
        var _base = _addr + _b * 64;
        if (buffer_peek(loaded_buf, _base & 0xFFFF, buffer_u8) == 0) {
            continue;
        }
        var _first = buffer_peek(mem_buf, _base & 0xFFFF, buffer_u8);
        var _varied = false;
        var _h1 = 0;
        var _h3 = 0;
        for (var _i = 0; _i < 61; _i++) {
            var _v0 = buffer_peek(mem_buf, (_base + _i) & 0xFFFF, buffer_u8);
            if (_v0 != _first) {
                _varied = true;
            }
            _h1 += _pc[_v0 ^ buffer_peek(mem_buf, (_base + _i + 1) & 0xFFFF, buffer_u8)];
            _h3 += _pc[_v0 ^ buffer_peek(mem_buf, (_base + _i + 3) & 0xFFFF, buffer_u8)];
        }
        var _h = _h1;
        if (_h3 < _h) {
            _h = _h3;
        }
        if (_varied && _h / 61 <= 2.6) {
            _good += 1;
        }
    }
    return _good / _blocks;
}

/// @desc scr_ext_build_findings()
/// Collects everything worth looking at, with a confidence, best first.
function scr_ext_build_findings() {
    findings = [];
    clue_index = -1;

    // ---- Your marks: confirmed by eye, always first ----
    for (var _m = 0; _m < array_length(user_marks); _m++) {
        var _um = user_marks[_m];
        array_push(findings, { addr : _um.addr, len : _um.len, kind : scr_ext_mark_kind(_um.mode), mode : _um.mode, conf : 100,
            why : "set by you - exact view, columns and colours", scr : _um.scr, init : -1, play : -1, mark : _m });
    }

    // ---- VIC clues: the code says where these are ----
    for (var _i = 0; _i < array_length(vic_clues); _i++) {
        var _c = vic_clues[_i];
        var _conf = _c.conf;
        var _why = _c.why;
        if (buffer_peek(loaded_buf, _c.addr, buffer_u8) == 0) {
            _conf = round(_conf * 0.45);
            _why += ", not in the file - filled at runtime";
        }
        else if (_c.kind != "Screen") {
            // Scale by how much of it actually looks like graphics
            _conf = round(_conf * (0.55 + 0.45 * scr_ext_region_gfx_fraction(_c.addr, _c.len)));
        }
        else {
            _conf = round(_conf * 0.85);
        }
        array_push(findings, { addr : _c.addr, len : _c.len, kind : _c.kind, mode : _c.mode, conf : _conf, why : _why, scr : _c.scr, init : -1, play : -1, mark : -1 });
    }

    // ---- Bitmaps found by their layout ----
    for (var _i = 0; _i < array_length(bitmap_hits); _i++) {
        var _bh = bitmap_hits[_i];
        var _dupe = false;
        for (var _k = 0; _k < array_length(vic_clues); _k++) {
            if (vic_clues[_k].kind == "Bitmap" && abs(vic_clues[_k].addr - _bh.addr) < 320) {
                _dupe = true;
            }
        }
        if (!_dupe) {
            var _bmode = EXT_GFX_BMP_HR;
            var _mname = "hires";
            if (_bh.mc) {
                _bmode = EXT_GFX_BMP_MC;
                _mname = "multicolour";
            }
            array_push(findings, { addr : _bh.addr, len : 8000, kind : "Bitmap", mode : _bmode, conf : _bh.conf,
                why : _mname + " bitmap layout - cell rows line up (" + string(round(_bh.ratio * 100) / 100) + ")", scr : -1, init : -1, play : -1, mark : -1 });
        }
    }

    // ---- Runs of one class: graphics found by shape, text, packed data ----
    var _a = 0;
    while (_a < 65536) {
        var _cls = buffer_peek(cls_buf, _a, buffer_u8);
        var _b = _a;
        while (_b < 65536 && buffer_peek(cls_buf, _b, buffer_u8) == _cls) {
            _b++;
        }
        var _len = _b - _a;

        if (_cls == EXT_CLS_GFX && _len >= 256) {
            // Skip what a VIC clue or a detected bitmap already covers
            var _covered = false;
            for (var _k = 0; _k < array_length(bitmap_hits); _k++) {
                if (_a >= bitmap_hits[_k].addr && _a < bitmap_hits[_k].addr + 8000) {
                    _covered = true;
                }
            }
            for (var _k = 0; _k < array_length(vic_clues); _k++) {
                var _vc = vic_clues[_k];
                if (_a >= _vc.addr && _a < _vc.addr + _vc.len) {
                    _covered = true;
                }
            }
            if (!_covered) {
                // Sprites change little 3 bytes apart, characters 1 byte apart
                var _pc = global.ext_popcount;
                var _h1 = 0;
                var _h3 = 0;
                var _n = _len - 3;
                if (_n > 1024) {
                    _n = 1024;
                }
                for (var _j = 0; _j < _n; _j++) {
                    var _v = buffer_peek(mem_buf, _a + _j, buffer_u8);
                    _h1 += _pc[_v ^ buffer_peek(mem_buf, _a + _j + 1, buffer_u8)];
                    _h3 += _pc[_v ^ buffer_peek(mem_buf, _a + _j + 3, buffer_u8)];
                }
                var _kind = "Graphics (chars?)";
                var _mode = EXT_GFX_CHAR_HR;
                if (_h3 < _h1) {
                    _kind = "Graphics (sprites?)";
                    _mode = EXT_GFX_SPR_HR;
                }
                if (scr_ext_gfx_is_mc()) {
                    _mode += 1;     // keep the viewer's MC choice (HR -> MC variant)
                }
                var _gc = 40 + floor(_len / 256) * 3;
                if (_gc > 70) {
                    _gc = 70;
                }
                array_push(findings, { addr : _a, len : _len, kind : _kind, mode : _mode, conf : _gc, why : "shape only, no code reference", scr : -1, init : -1, play : -1, mark : -1 });
            }
        }
        if (_cls == EXT_CLS_TEXT && _len >= 24) {
            array_push(findings, { addr : _a, len : _len, kind : "Text", mode : -1, conf : 80, why : string(_len) + " characters", scr : -1, init : -1, play : -1, mark : -1 });
        }
        if (_cls == EXT_CLS_PACKED && _len >= 1024) {
            array_push(findings, { addr : _a, len : _len, kind : "Packed data", mode : -1, conf : 90, why : "press U to unpack", scr : -1, init : -1, play : -1, mark : -1 });
        }
        _a = _b;
    }

    scr_ext_detect_sid();

    array_sort(findings, function(_x, _y) {
        return _y.conf - _x.conf;
    });
}

// ---------------------------------------------------------------------------
// 2. Packed / crunched data
// ---------------------------------------------------------------------------

/// @desc scr_ext_detect_packed()
/// Measures entropy over a 1K window around every page.
function scr_ext_detect_packed() {
    for (var _page = 0; _page < 256; _page++) {
        var _base = _page * 256;
        var _any = false;
        for (var _i = 0; _i < 256; _i++) {
            if (buffer_peek(cls_buf, _base + _i, buffer_u8) == EXT_CLS_UNKNOWN) {
                _any = true;
                break;
            }
        }
        if (!_any) {
            continue;
        }
        var _w1 = _base - 384;
        var _w2 = _base + 640;
        if (_w1 < 0) {
            _w1 = 0;
        }
        if (_w2 > 65536) {
            _w2 = 65536;
        }
        var _counts = array_create(256, 0);
        var _n = 0;
        for (var _a = _w1; _a < _w2; _a++) {
            if (buffer_peek(loaded_buf, _a, buffer_u8) == 1) {
                _counts[buffer_peek(mem_buf, _a, buffer_u8)] += 1;
                _n += 1;
            }
        }
        if (_n < 512) {
            continue;
        }
        if (scr_ext_entropy_from_counts(_counts, _n) >= scr_ext_packed_threshold(_n)) {
            scr_ext_mark_unknown(_base, 256, EXT_CLS_PACKED);
        }
    }
}

// ---------------------------------------------------------------------------
// 3. Text
// ---------------------------------------------------------------------------

/// @desc scr_ext_detect_text()
/// Runs of 8+ PETSCII or screen-code characters that look like words.
function scr_ext_detect_text() {
    var _p = 0;
    while (_p < 65536) {
        if (buffer_peek(cls_buf, _p, buffer_u8) != EXT_CLS_UNKNOWN) {
            _p++;
            continue;
        }

        // PETSCII (upper case / graphics set)
        var _q = _p;
        var _letters = 0;
        var _spaces = 0;
        while (_q < 65536) {
            if (buffer_peek(cls_buf, _q, buffer_u8) != EXT_CLS_UNKNOWN) {
                break;
            }
            var _v = buffer_peek(mem_buf, _q, buffer_u8);
            var _ok = false;
            if (_v >= 0x20 && _v <= 0x5F) {
                _ok = true;
            }
            if (_v >= 0xC1 && _v <= 0xDA) {
                _ok = true;
            }
            if (!_ok) {
                break;
            }
            if ((_v >= 0x41 && _v <= 0x5A) || (_v >= 0xC1 && _v <= 0xDA)) {
                _letters++;
            }
            if (_v == 0x20) {
                _spaces++;
            }
            _q++;
        }
        var _len = _q - _p;
        if (_len >= 8 && _letters * 10 >= _len * 4 && _spaces >= 1) {
            scr_ext_mark_unknown(_p, _len, EXT_CLS_TEXT);
            _p = _q;
            continue;
        }

        // Screen codes (A = 1 ... Z = 26, space = $20)
        var _q2 = _p;
        var _letters2 = 0;
        var _spaces2 = 0;
        var _zeros2 = 0;
        while (_q2 < 65536) {
            if (buffer_peek(cls_buf, _q2, buffer_u8) != EXT_CLS_UNKNOWN) {
                break;
            }
            var _v2 = buffer_peek(mem_buf, _q2, buffer_u8);
            if (_v2 > 0x3F) {
                break;
            }
            if (_v2 >= 1 && _v2 <= 26) {
                _letters2++;
            }
            if (_v2 == 0x20) {
                _spaces2++;
            }
            if (_v2 == 0) {
                _zeros2++;
            }
            _q2++;
        }
        var _len2 = _q2 - _p;
        if (_len2 >= 8 && _letters2 * 10 >= _len2 * 4 && _spaces2 >= 1 && _zeros2 * 4 <= _len2) {
            scr_ext_mark_unknown(_p, _len2, EXT_CLS_TEXT);
            _p = _q2;
            continue;
        }
        _p++;
    }
}

// ---------------------------------------------------------------------------
// 4. Graphics shape heuristic
// ---------------------------------------------------------------------------

/// @desc scr_ext_detect_gfx()
/// Graphics have neighbouring rows that look alike: few bits change between a
/// byte and the next one (chars, 1 byte per row) or the one 3 further on
/// (sprites, 3 bytes per row). Code and packed data change ~4 bits per byte.
function scr_ext_detect_gfx() {
    var _pc = global.ext_popcount;
    for (var _blk = 0; _blk < 1024; _blk++) {
        var _base = _blk * 64;
        var _unknown = 0;
        var _zero = 0;
        var _ff = 0;
        var _d1 = -1;
        var _d2 = -1;
        var _distinct = 0;
        for (var _i = 0; _i < 64; _i++) {
            if (buffer_peek(cls_buf, _base + _i, buffer_u8) == EXT_CLS_UNKNOWN) {
                _unknown++;
            }
            var _v = buffer_peek(mem_buf, _base + _i, buffer_u8);
            if (_v == 0) {
                _zero++;
            }
            if (_v == 0xFF) {
                _ff++;
            }
            if (_distinct < 3) {
                if (_distinct == 0) {
                    _d1 = _v;
                    _distinct = 1;
                }
                else if (_distinct == 1 && _v != _d1) {
                    _d2 = _v;
                    _distinct = 2;
                }
                else if (_distinct == 2 && _v != _d1 && _v != _d2) {
                    _distinct = 3;
                }
            }
        }
        if (_unknown < 56 || _zero > 58 || _ff > 58 || _distinct < 3) {
            continue;
        }

        var _h1 = 0;
        var _n1 = 0;
        for (var _i = 0; _i < 63; _i++) {
            if ((_i mod 8) != 7) {
                _h1 += _pc[buffer_peek(mem_buf, _base + _i, buffer_u8) ^ buffer_peek(mem_buf, _base + _i + 1, buffer_u8)];
                _n1++;
            }
        }
        var _h3 = 0;
        for (var _i = 0; _i < 61; _i++) {
            _h3 += _pc[buffer_peek(mem_buf, _base + _i, buffer_u8) ^ buffer_peek(mem_buf, _base + _i + 3, buffer_u8)];
        }
        var _h = _h1 / _n1;
        if (_h3 / 61 < _h) {
            _h = _h3 / 61;
        }
        if (_h <= 2.0) {
            scr_ext_mark_unknown(_base, 64, EXT_CLS_GFX);
        }
    }
}

// ---------------------------------------------------------------------------
// D64 file summary
// ---------------------------------------------------------------------------

/// @desc scr_ext_scan_file_buf(buffer, length)
/// Quick look at a PRG without loading it: { load, finish, size, packed, sys }.
function scr_ext_scan_file_buf(_buf, _len) {
    var _r = { load : -1, finish : -1, size : 0, packed : false, sys : -1 };
    if (_len < 3) {
        return _r;
    }
    _r.load = buffer_peek(_buf, 0, buffer_u8) + (buffer_peek(_buf, 1, buffer_u8) << 8);
    _r.size = _len - 2;
    _r.finish = _r.load + _r.size - 1;
    if (_r.finish > 0xFFFF) {
        _r.finish = 0xFFFF;
    }

    var _windows = 0;
    var _high = 0;
    var _o = 2;
    while (_o + 512 <= _len) {
        var _n = _len - _o;
        if (_n > 1024) {
            _n = 1024;
        }
        if (scr_ext_entropy_buf(_buf, _o, _n) >= scr_ext_packed_threshold(_n)) {
            _high++;
        }
        _windows++;
        _o += 1024;
    }
    if (_windows > 0 && _high * 2 >= _windows) {
        _r.packed = true;
    }

    if (_r.load == 0x0801) {
        var _end = _len;
        if (_end > 90) {
            _end = 90;
        }
        for (var _i = 6; _i < _end; _i++) {
            if (buffer_peek(_buf, _i, buffer_u8) == 0x9E) {
                var _j = _i + 1;
                while (_j < _len && (buffer_peek(_buf, _j, buffer_u8) == 0x20 || buffer_peek(_buf, _j, buffer_u8) == 0x28)) {
                    _j++;
                }
                var _val = 0;
                var _digits = 0;
                while (_j < _len && _digits < 5) {
                    var _d = buffer_peek(_buf, _j, buffer_u8);
                    if (_d < 0x30 || _d > 0x39) {
                        break;
                    }
                    _val = _val * 10 + (_d - 0x30);
                    _digits++;
                    _j++;
                }
                if (_digits > 0) {
                    _r.sys = _val;
                }
                break;
            }
        }
    }
    return _r;
}

// ---------------------------------------------------------------------------
// 5. SID music / sound code
// ---------------------------------------------------------------------------

/// @desc scr_ext_detect_sid()
/// 1. Finds every store to the SID ($D400-$D7FF) by its byte pattern - STA/STX/
///    STY/SAX absolute or indexed - so it works whatever the bytes were classed as.
/// 2. Groups the stores into routines (no more than $300 apart).
/// 3. Collects possible init / play addresses: a JMP init / JMP play table in
///    front of the routine, and every JSR / JMP elsewhere that lands in it.
/// 4. Proves it: runs init, then play for 25 frames on the 6502 core, and checks
///    the SID registers change frame to frame like music. Verified = 100%.
function scr_ext_detect_sid() {
    // ---- 1. SID stores by pattern ----
    var _hits = [];
    for (var _a = 0; _a < 0xFFFD; _a++) {
        var _op = buffer_peek(mem_buf, _a, buffer_u8);
        if (_op != 0x8D && _op != 0x9D && _op != 0x99 && _op != 0x8E && _op != 0x8C && _op != 0x8F) {
            continue;
        }
        var _hi = buffer_peek(mem_buf, _a + 2, buffer_u8);
        if (_hi < 0xD4 || _hi > 0xD7) {
            continue;
        }
        if (buffer_peek(loaded_buf, _a, buffer_u8) == 0) {
            continue;
        }
        var _cls = buffer_peek(cls_buf, _a, buffer_u8);
        if (_cls == EXT_CLS_TEXT) {
            continue;
        }
        array_push(_hits, { at : _a, reg : buffer_peek(mem_buf, _a + 1, buffer_u8) & 0x1F, indexed : (_op == 0x9D || _op == 0x99) });
    }
    var _n = array_length(_hits);
    if (_n == 0) {
        return;
    }

    // ---- JSR / JMP targets anywhere in memory (candidate entry points) ----
    var _calls = [];
    for (var _a = 0; _a < 0xFFFD; _a++) {
        var _o = buffer_peek(mem_buf, _a, buffer_u8);
        if (_o == 0x20 || _o == 0x4C) {
            if (buffer_peek(loaded_buf, _a, buffer_u8) == 1) {
                array_push(_calls, scr_ext_peek16(_a + 1));
            }
        }
    }

    var _verify_budget = 6;     // routines play-tested per analysis
    var _prev_find = -1;        // last SID finding pushed (for merging a split player)
    var _prev_table = -1;
    var _prev_regs = array_create(32, 0);
    var _i = 0;
    while (_i < _n) {
        var _j = _i;
        while (_j + 1 < _n && _hits[_j + 1].at - _hits[_j].at <= 0x300) {
            _j++;
        }
        var _regs = array_create(32, 0);
        var _distinct = 0;
        var _indexed = false;
        var _volume = false;
        for (var _k = _i; _k <= _j; _k++) {
            var _r = _hits[_k].reg;
            if (_regs[_r] == 0) {
                _regs[_r] = 1;
                _distinct++;
            }
            if (_hits[_k].indexed) {
                _indexed = true;
            }
            if (_r == 0x18) {
                _volume = true;
            }
        }
        var _start = _hits[_i].at;
        var _end = _hits[_j].at + 3;

        if (_distinct >= 3) {
            var _conf = 45;
            if (_distinct >= 7) {
                _conf = 70;
            }
            if (_distinct >= 12) {
                _conf = 85;
            }
            if (_indexed) {
                _conf += 5;
            }
            if (_volume) {
                _conf += 5;
            }

            // ---- 3. entry candidates: [init, play] pairs, best first ----
            var _pairs = [];
            var _lo = _start - 0x800;
            if (_lo < 0) {
                _lo = 0;
            }
            for (var _p = _start - 1; _p >= _lo; _p--) {
                if (buffer_peek(mem_buf, _p, buffer_u8) == 0x4C && buffer_peek(mem_buf, (_p + 3) & 0xFFFF, buffer_u8) == 0x4C) {
                    var _t1 = scr_ext_peek16(_p + 1);
                    var _t2 = scr_ext_peek16(_p + 4);
                    if (_t1 != _t2 && _t1 >= _start - 0x800 && _t1 <= _end + 0x800 && _t2 >= _start - 0x800 && _t2 <= _end + 0x800) {
                        if (scr_ext_is_loaded(_t1) && scr_ext_is_loaded(_t2)) {
                            // Usually JMP init / JMP play, but some players swap them
                            array_push(_pairs, { init : _t1, play : _t2, table : _p });
                            array_push(_pairs, { init : _t2, play : _t1, table : _p });
                            break;
                        }
                    }
                }
            }
            // Calls into the routine: each could be play, any other could be init
            var _targets = [];
            for (var _c = 0; _c < array_length(_calls); _c++) {
                var _t = _calls[_c];
                if (_t >= _start - 0x200 && _t <= _end && scr_ext_is_loaded(_t)) {
                    var _seen = false;
                    for (var _q = 0; _q < array_length(_targets); _q++) {
                        if (_targets[_q] == _t) {
                            _seen = true;
                        }
                    }
                    if (!_seen && array_length(_targets) < 6) {
                        array_push(_targets, _t);
                    }
                }
            }
            for (var _pl = 0; _pl < array_length(_targets); _pl++) {
                var _init_guess = -1;
                for (var _in = 0; _in < array_length(_targets); _in++) {
                    if (_in != _pl) {
                        _init_guess = _targets[_in];
                        break;
                    }
                }
                array_push(_pairs, { init : _init_guess, play : _targets[_pl], table : -1 });
            }

            // ---- Same entry table as the routine before: one player split by its data ----
            if (array_length(_pairs) > 0 && _pairs[0].table >= 0 && _pairs[0].table == _prev_table && _prev_find >= 0) {
                var _pf = findings[_prev_find];
                if (_end > _pf.addr + _pf.len) {
                    _pf.len = _end - _pf.addr;
                }
                for (var _rr = 0; _rr < 32; _rr++) {
                    if (_regs[_rr] == 1) {
                        _prev_regs[_rr] = 1;
                    }
                }
                _i = _j + 1;
                continue;
            }

            // ---- 4. verify by playing ----
            var _kind = "SID sound code";
            var _why = scr_ext_sid_regs_text(_distinct, _indexed);
            var _init = -1;
            var _play = -1;
            if (array_length(_pairs) > 0 && _pairs[0].table >= 0) {
                // A table is good evidence even before playing it
                _kind = "SID music";
                _init = _pairs[0].init;
                _play = _pairs[0].play;
                _start = _pairs[0].table;
                _conf += 15;
                _why = "JMP table: init $" + scr_ext_hex(_init, 4) + "  play $" + scr_ext_hex(_play, 4) + " (not confirmed by playing), " + _why;
            }
            var _tries = array_length(_pairs);
            if (_tries > 5) {
                _tries = 5;
            }
            if (_verify_budget > 0) {
                _verify_budget -= 1;
                for (var _t3 = 0; _t3 < _tries; _t3++) {
                    var _v = scr_ext_sid_verify(_pairs[_t3].init, _pairs[_t3].play);
                    if (_v >= 1) {
                        _kind = "SID music";
                        _init = _pairs[_t3].init;
                        _play = _pairs[_t3].play;
                        if (_pairs[_t3].table >= 0) {
                            _start = _pairs[_t3].table;
                        }
                        var _init_txt = "none";
                        if (_init >= 0) {
                            _init_txt = "$" + scr_ext_hex(_init, 4);
                        }
                        if (_v == 2) {
                            _conf = 100;
                            _why = "verified - it plays: init " + _init_txt + "  play $" + scr_ext_hex(_play, 4) + ", notes change every few frames";
                        }
                        else {
                            _conf = 90;
                            _why = "runs: init " + _init_txt + "  play $" + scr_ext_hex(_play, 4) + ", SID set up but little change yet";
                        }
                        break;
                    }
                }
            }
            if (_conf > 100) {
                _conf = 100;
            }
            array_push(findings, { addr : _start, len : _end - _start, kind : _kind, mode : -1, conf : _conf, why : _why, scr : -1, init : _init, play : _play, mark : -1 });
            _prev_find = array_length(findings) - 1;
            _prev_table = -1;
            if (array_length(_pairs) > 0) {
                _prev_table = _pairs[0].table;
            }
            _prev_regs = _regs;
        }
        _i = _j + 1;
    }
}

/// @desc scr_ext_sid_regs_text(distinct, indexed) - what the stores cover, in words
function scr_ext_sid_regs_text(_distinct, _indexed) {
    var _t = string(_distinct) + " different SID registers stored to";
    if (_indexed) {
        _t += " (indexed, e.g. STA $D400,X - one set reaches all 3 voices)";
    }
    return _t;
}

/// @desc scr_ext_sid_verify(init, play)
/// Runs init (if any) then play for 25 frames on a copy of memory.
/// Returns 2 = SID registers keep changing (music), 1 = runs and sets the SID up,
/// 0 = doesn't run cleanly, -1 = not checked (the 6502 is busy).
function scr_ext_sid_verify(_init, _play) {
    if (cpu_active || sid_playing) {
        return -1;
    }
    // The 6502 may be holding a paused multi-stage unpack: keep it intact
    var _keep_cpu = variable_clone(cpu);
    var _keep_mem = buffer_create(65536, buffer_fixed, 1);
    var _keep_w = buffer_create(65536, buffer_fixed, 1);
    var _keep_ex = buffer_create(65536, buffer_fixed, 1);
    buffer_copy(cpu_mem, 0, 65536, _keep_mem, 0);
    buffer_copy(cpu_w, 0, 65536, _keep_w, 0);
    buffer_copy(cpu_execd, 0, 65536, _keep_ex, 0);

    var _result = scr_ext_sid_verify_run(_init, _play);

    cpu = _keep_cpu;
    buffer_copy(_keep_mem, 0, 65536, cpu_mem, 0);
    buffer_copy(_keep_w, 0, 65536, cpu_w, 0);
    buffer_copy(_keep_ex, 0, 65536, cpu_execd, 0);
    buffer_delete(_keep_mem);
    buffer_delete(_keep_w);
    buffer_delete(_keep_ex);
    return _result;
}

/// @desc scr_ext_sid_verify_run(init, play) - the test itself (see scr_ext_sid_verify)
function scr_ext_sid_verify_run(_init, _play) {
    buffer_copy(mem_buf, 0, 65536, cpu_mem, 0);
    buffer_fill(cpu_w, 0, buffer_u8, 0, 65536);
    buffer_fill(cpu_execd, 0, buffer_u8, 0, 65536);
    buffer_fill(sid_shadow, 0, buffer_u8, 0, 32);
    buffer_poke(cpu_mem, 0x01, buffer_u8, 0x37);
    cpu = scr_ext_cpu_new_state();
    cpu.sp = 0xF6;

    if (_init >= 0) {
        if (scr_ext_sid_call(_init, 0, 150000) != "return") {
            return 0;
        }
    }
    var _prev = array_create(25, -1);
    var _changes = 0;
    var _touched = 0;
    // Up to 100 frames (2 s) - quiet intros and long notes need time - but stop
    // as soon as it is clearly music
    for (var _f = 0; _f < 100; _f++) {
        if (scr_ext_sid_call(_play, 0, 25000) != "return") {
            return 0;
        }
        if (_changes >= 8 && (buffer_peek(sid_shadow, 0x18, buffer_u8) & 15) > 0) {
            return 2;
        }
        for (var _r = 0; _r < 25; _r++) {
            var _v = buffer_peek(sid_shadow, _r, buffer_u8);
            if (_v != _prev[_r]) {
                if (_prev[_r] >= 0) {
                    _changes += 1;
                }
                else if (_v != 0) {
                    _touched += 1;
                }
                _prev[_r] = _v;
            }
        }
    }
    var _volume = buffer_peek(sid_shadow, 0x18, buffer_u8) & 15;
    if (_volume > 0 && _changes >= 8) {
        return 2;
    }
    if (_changes > 0 || _touched >= 3) {
        return 1;
    }
    return 0;
}

// ---------------------------------------------------------------------------
// 6. Bitmaps by their layout
// ---------------------------------------------------------------------------

/// @desc scr_ext_bitmap_ratio(base)
/// A bitmap is 1000 cells of 8 bytes in screen order, so the bottom row of a
/// cell continues into the top row of the cell 40 further on (the one below it
/// on screen) much better than into an unrelated cell. Code, charsets, sprites
/// and packed data show no such preference. Returns below/unrelated (low = bitmap)
/// or -1 when the block is mostly empty or too noisy inside its cells.
function scr_ext_bitmap_ratio(_b) {
    var _pc = global.ext_popcount;
    var _vb = 0;
    var _vr = 0;
    var _vi = 0;
    var _ink = 0;
    var _n = 0;
    for (var _c = 0; _c < 960; _c += 5) {
        var _a7 = buffer_peek(mem_buf, (_b + _c * 8 + 7) & 0xFFFF, buffer_u8);
        var _below = buffer_peek(mem_buf, (_b + (_c + 40) * 8) & 0xFFFF, buffer_u8);
        var _other = buffer_peek(mem_buf, (_b + ((_c + 57) mod 1000) * 8) & 0xFFFF, buffer_u8);
        _vb += _pc[_a7 ^ _below];
        _vr += _pc[_a7 ^ _other];
        _vi += _pc[buffer_peek(mem_buf, (_b + _c * 8 + 3) & 0xFFFF, buffer_u8) ^ buffer_peek(mem_buf, (_b + _c * 8 + 4) & 0xFFFF, buffer_u8)];
        if (_a7 != 0) {
            _ink += 1;
        }
        _n += 1;
    }
    if (_ink * 10 < _n * 3) {
        return -1;
    }
    if (_vi / _n > 3.0) {
        return -1;
    }
    return (_vb + 1) / (_vr + 1);
}

/// @desc scr_ext_bitmap_r8(base)
/// Works from any start address: in a bitmap a byte and the byte 8 later are the
/// same pixel row in neighbouring cells (side by side on screen). In charsets,
/// sprites, code and packed data, 8 later is unrelated. Low = bitmap, -1 = empty.
function scr_ext_bitmap_r8(_b) {
    var _pc = global.ext_popcount;
    var _vs = 0;
    var _vf = 0;
    var _ink = 0;
    var _n = 0;
    for (var _k = 0; _k < 7600; _k += 37) {
        var _i = _b + _k;
        var _v = buffer_peek(mem_buf, _i & 0xFFFF, buffer_u8);
        _vs += _pc[_v ^ buffer_peek(mem_buf, (_i + 8) & 0xFFFF, buffer_u8)];
        _vf += _pc[_v ^ buffer_peek(mem_buf, (_i + 2333) & 0xFFFF, buffer_u8)];
        if (_v != 0) {
            _ink += 1;
        }
        _n += 1;
    }
    if (_ink * 10 < _n * 3) {
        return -1;
    }
    return (_vs + 1) / (_vf + 1);
}

/// @desc scr_ext_bitmap_is_mc(base)
/// Multicolour pictures agree more between neighbouring pixel PAIRS than between
/// neighbouring single pixels (01 / 10 are colours, not edges); hires the reverse.
function scr_ext_bitmap_is_mc(_b) {
    var _be = 0;
    var _bt = 0;
    var _pe = 0;
    var _pt = 0;
    for (var _i = 0; _i < 8000; _i += 3) {
        var _v = buffer_peek(mem_buf, (_b + _i) & 0xFFFF, buffer_u8);
        for (var _k = 0; _k < 7; _k++) {
            _bt += 1;
            if (((_v >> _k) & 1) == ((_v >> (_k + 1)) & 1)) {
                _be += 1;
            }
        }
        for (var _k = 0; _k < 3; _k++) {
            _pt += 1;
            if (((_v >> (_k * 2)) & 3) == ((_v >> (_k * 2 + 2)) & 3)) {
                _pe += 1;
            }
        }
    }
    return (_pe / _pt) > (_be / _bt);
}

/// @desc scr_ext_bitmap_refine(base, mc)
/// Exact start: +/- one character row in cells, then +/- 7 bytes, by the same
/// smoothness score Align [L] uses.
function scr_ext_bitmap_refine(_b, _mc) {
    var _best = _b;
    var _best_s = scr_ext_gfx_align_score(_b, _mc);
    for (var _o = -320; _o <= 320; _o += 8) {
        var _c = _b + _o;
        if (_c < 0 || _c + 8000 > 65536) {
            continue;
        }
        var _s = scr_ext_gfx_align_score(_c, _mc);
        if (_s >= 0 && (_best_s < 0 || _s < _best_s)) {
            _best_s = _s;
            _best = _c;
        }
    }
    var _coarse = _best;
    for (var _f = -7; _f <= 7; _f++) {
        var _c2 = _coarse + _f;
        if (_c2 < 0 || _c2 + 8000 > 65536) {
            continue;
        }
        var _s2 = scr_ext_gfx_align_score(_c2, _mc);
        if (_s2 >= 0 && (_best_s < 0 || _s2 < _best_s)) {
            _best_s = _s2;
            _best = _c2;
        }
    }
    return _best;
}

/// @desc scr_ext_detect_bitmaps()
/// Scans loaded memory in 64-byte steps for 8000-byte bitmaps, refines each
/// hit to its exact start, marks it blue and records it in bitmap_hits.
function scr_ext_detect_bitmaps() {
    bitmap_hits = [];
    var _cand = [];
    for (var _b = 0; _b + 8000 <= 65536; _b += 64) {
        if (buffer_peek(loaded_buf, _b, buffer_u8) == 0) {
            continue;
        }
        if (buffer_peek(loaded_buf, _b + 3999, buffer_u8) == 0 || buffer_peek(loaded_buf, _b + 7999, buffer_u8) == 0) {
            continue;
        }
        if (buffer_peek(cls_buf, _b + 4000, buffer_u8) == EXT_CLS_SURE) {
            continue;
        }
        // Either test can flag it: cell-below (needs the right phase) or
        // side-by-side (any phase). The better of the two is kept as its score.
        var _r = scr_ext_bitmap_ratio(_b);
        var _r8 = scr_ext_bitmap_r8(_b);
        var _score = -1;
        if (_r >= 0 && _r < 0.8) {
            _score = _r;
        }
        if (_r8 >= 0 && _r8 < 0.8) {
            if (_score < 0 || _r8 < _score) {
                _score = _r8;
            }
        }
        if (_score >= 0) {
            array_push(_cand, { addr : _b, ratio : _score });
        }
    }

    // One picture per cluster of hits: the best one, refined to its exact start
    var _i = 0;
    var _n = array_length(_cand);
    while (_i < _n) {
        var _j = _i;
        var _best = _i;
        while (_j + 1 < _n && _cand[_j + 1].addr - _cand[_i].addr < 8000) {
            _j++;
            if (_cand[_j].ratio < _cand[_best].ratio) {
                _best = _j;
            }
        }
        // A run of hits longer than one picture: skip what starts inside the last one
        var _found = array_length(bitmap_hits);
        if (_found > 0) {
            if (_cand[_i].addr < bitmap_hits[_found - 1].addr + 8000) {
                _i = _j + 1;
                continue;
            }
        }
        var _mc = scr_ext_bitmap_is_mc(_cand[_best].addr);
        var _base = scr_ext_bitmap_refine(_cand[_best].addr, _mc);
        var _ratio = scr_ext_bitmap_ratio(_base);
        var _ratio8 = scr_ext_bitmap_r8(_base);
        if (_ratio < 0 || (_ratio8 >= 0 && _ratio8 < _ratio)) {
            _ratio = _ratio8;
        }
        if (_ratio < 0) {
            _ratio = _cand[_best].ratio;
        }
        var _conf = 55;
        if (_ratio <= 0.65) {
            _conf = 70;
        }
        if (_ratio <= 0.5) {
            _conf = 85;
        }
        if (_ratio <= 0.35) {
            _conf = 95;
        }
        array_push(bitmap_hits, { addr : _base, mc : _mc, ratio : _ratio, conf : _conf });
        scr_ext_mark_unknown(_base, 8000, EXT_CLS_GFX);
        _i = _j + 1;
    }
}

// ---------------------------------------------------------------------------
// Your marks: views you have lined up by eye and confirmed with Mark as found
// ---------------------------------------------------------------------------

/// @desc scr_ext_mark_kind(mode) - finding name for a mark
function scr_ext_mark_kind(_mode) {
    switch (_mode) {
        case EXT_GFX_BMP_HR:
        case EXT_GFX_BMP_MC:
            return "Bitmap (yours)";
        case EXT_GFX_SPR_HR:
        case EXT_GFX_SPR_MC:
            return "Sprites (yours)";
    }
    return "Charset (yours)";
}

/// @desc scr_ext_mark_toggle()
/// Mark as found [Y]: records the viewer exactly as it is now. Pressing it again
/// with the viewer on the same start removes that mark.
function scr_ext_mark_toggle() {
    for (var _i = 0; _i < array_length(user_marks); _i++) {
        if (user_marks[_i].addr == gfx_addr && user_marks[_i].mode == gfx_mode) {
            array_delete(user_marks, _i, 1);
            scr_ext_analyse();
            status_text = "Mark removed at $" + scr_ext_hex(gfx_addr, 4) + ".";
            return;
        }
    }
    // Range: from the viewer start to the end of the selection, else the whole view
    var _len = gfx_screen_bytes;
    if (scr_ext_gfx_is_bitmap()) {
        _len = 8000;
    }
    if (sel_active && sel_end > gfx_addr) {
        _len = sel_end - gfx_addr + 1;
    }
    if (gfx_addr + _len > 65536) {
        _len = 65536 - gfx_addr;
    }
    var _cols = gfx_char_cols;
    if (scr_ext_gfx_is_sprite()) {
        _cols = gfx_spr_cols;
    }
    array_push(user_marks, {
        addr       : gfx_addr,
        len        : _len,
        mode       : gfx_mode,
        cols       : _cols,
        colours    : [gfx_col[0], gfx_col[1], gfx_col[2], gfx_col[3]],
        use_colour : gfx_use_colour,
        scr        : gfx_scr_addr,
        col        : gfx_col_addr
    });
    var _keep_addr = gfx_addr;
    var _keep_mode = gfx_mode;
    scr_ext_analyse();
    gfx_addr = _keep_addr;
    gfx_mode = _keep_mode;
    gfx_dirty = true;

    // Keep the disk findings list in step without a rescan
    if (buffer_exists(d64_buf) && d64_selected >= 0 && array_length(disk_results) > 0) {
        array_push(disk_results, {
            file  : d64_selected,
            fname : d64_files[d64_selected].name,
            cat   : scr_ext_disk_category({ kind : scr_ext_mark_kind(gfx_mode), mode : gfx_mode }),
            kind  : scr_ext_mark_kind(gfx_mode),
            addr  : _keep_addr,
            len   : _len,
            mode  : gfx_mode,
            conf  : 100,
            why   : "set by you"
        });
        array_sort(disk_results, function(_x, _y) {
            return _y.conf - _x.conf;
        });
    }
    status_text = "Marked " + scr_ext_mark_kind(gfx_mode) + " at $" + scr_ext_hex(_keep_addr, 4) + "-$" + scr_ext_hex(_keep_addr + _len - 1, 4) + " (100%). Y again here removes it.";
}

/// @desc scr_ext_mark_apply(mark) - puts the viewer back exactly as marked
function scr_ext_mark_apply(_m) {
    gfx_mode = _m.mode;
    if (_m.mode == EXT_GFX_SPR_HR || _m.mode == EXT_GFX_SPR_MC) {
        gfx_spr_cols = _m.cols;
    }
    else if (_m.mode == EXT_GFX_CHAR_HR || _m.mode == EXT_GFX_CHAR_MC) {
        gfx_char_cols = _m.cols;
    }
    gfx_col = [_m.colours[0], _m.colours[1], _m.colours[2], _m.colours[3]];
    gfx_use_colour = _m.use_colour;
    gfx_scr_addr = _m.scr;
    gfx_col_addr = _m.col;
    gfx_zoom_lock = 0;
    scr_ext_gfx_setup();
    gfx_addr = _m.addr;
    gfx_phase = gfx_addr mod gfx_row_bytes;
    gfx_dirty = true;
    cursor_addr = _m.addr;
    scr_ext_views_to(_m.addr);
}

/// @desc scr_ext_marks_force()
/// Marked ranges are graphics, whatever the code guesses said (run during analysis).
function scr_ext_marks_force() {
    for (var _m = 0; _m < array_length(user_marks); _m++) {
        var _um = user_marks[_m];
        for (var _i = 0; _i < _um.len; _i++) {
            var _a = _um.addr + _i;
            if (_a > 0xFFFF) {
                break;
            }
            if (buffer_peek(loaded_buf, _a, buffer_u8) == 1) {
                buffer_poke(cls_buf, _a, buffer_u8, EXT_CLS_GFX);
                buffer_poke(istart_buf, _a, buffer_u8, 0);
            }
        }
    }
}
