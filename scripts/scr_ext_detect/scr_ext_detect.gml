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
            case "LDA": _ra = _imm; break;
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
            case "ADC": case "SBC": case "AND": case "ORA": case "EOR": case "PLA":
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
            if (_w.target < 0xD000 || _w.target >= 0xE000) {
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
    status_text = "Finding " + string(_index + 1) + "/" + string(array_length(findings)) + ": " + scr_ext_finding_text(_c);
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
        array_push(findings, { addr : _c.addr, len : _c.len, kind : _c.kind, mode : _c.mode, conf : _conf, why : _why, scr : _c.scr });
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
            // Skip what a VIC clue already covers
            var _covered = false;
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
                array_push(findings, { addr : _a, len : _len, kind : _kind, mode : _mode, conf : _gc, why : "shape only, no code reference", scr : -1 });
            }
        }
        if (_cls == EXT_CLS_TEXT && _len >= 24) {
            array_push(findings, { addr : _a, len : _len, kind : "Text", mode : -1, conf : 80, why : string(_len) + " characters", scr : -1 });
        }
        if (_cls == EXT_CLS_PACKED && _len >= 1024) {
            array_push(findings, { addr : _a, len : _len, kind : "Packed data", mode : -1, conf : 90, why : "press U to unpack", scr : -1 });
        }
        _a = _b;
    }

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
