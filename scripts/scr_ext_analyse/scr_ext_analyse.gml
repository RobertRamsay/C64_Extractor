/// @desc scr_ext_analyse()
/// Full static analysis pass over the 64K image:
///   1. find entry points (BASIC SYS, load address, vectors, manual)
///   2. recursive-descent trace from each entry  -> green / yellow
///   3. heuristic scoring of everything untraced  -> yellow / orange / red
function scr_ext_analyse() {
    // loaded_buf holds 1 for loaded bytes, which equals EXT_CLS_UNKNOWN
    buffer_copy(loaded_buf, 0, 65536, cls_buf, 0);
    buffer_fill(istart_buf, 0, buffer_u8, 0, 65536);
    buffer_fill(entry_buf,  0, buffer_u8, 0, 65536);

    entries = scr_ext_find_entries();
    for (var _i = 0; _i < array_length(manual_entries); _i++) {
        array_push(entries, { addr : manual_entries[_i], strong : true, why : "manual" });
    }

    // Strong entries first, then weak ones
    for (var _i = 0; _i < array_length(entries); _i++) {
        var _e = entries[_i];
        buffer_poke(entry_buf, _e.addr, buffer_u8, 1);
        if (_e.strong) {
            scr_ext_trace(_e.addr, EXT_CLS_SURE);
        }
    }
    for (var _i = 0; _i < array_length(entries); _i++) {
        var _e = entries[_i];
        if (!_e.strong) {
            scr_ext_trace(_e.addr, EXT_CLS_LIKELY);
        }
    }

    // Data detection on everything the tracer didn't claim
    scr_ext_apply_vic_clues(scr_ext_find_vic_writes());
    scr_ext_detect_packed();
    scr_ext_detect_text();
    scr_ext_detect_gfx();

    // Whatever is left is graded as possible / doubtful / not code
    scr_ext_score_unknown();
    scr_ext_count_classes();

    // One-line verdict for the info panel
    var _loaded = 65536 - cls_counts[EXT_CLS_NONE];
    verdict_text = "";
    if (_loaded > 0 && cls_counts[EXT_CLS_PACKED] * 10 >= _loaded * 3) {
        verdict_text = "Mostly packed data - this file is crunched. Press U to unpack it.";
    }
    scr_ext_build_findings();
    if (verdict_text == "" && array_length(findings) > 0) {
        verdict_text = string(array_length(findings)) + " findings (" + string(array_length(vic_clues)) + " from VIC registers in the code) - N shows the summary, J steps through them.";
    }
    map_dirty = true;
}

/// @desc scr_ext_find_entries()
/// Returns an array of { addr, strong, why }.
function scr_ext_find_entries() {
    var _list = [];

    if (is_dump) {
        // Interrupt / reset vectors, skipping the stock KERNAL handlers
        var _vec_addr = [0x0314, 0x0318, 0xFFFA, 0xFFFC, 0xFFFE];
        var _vec_name = ["IRQ $0314", "NMI $0318", "NMI $FFFA", "RESET $FFFC", "IRQ $FFFE"];
        var _rom_default = [0xEA31, 0xEA81, 0xEA7E, 0xFE47, 0xFE43, 0xFE66, 0xFCE2, 0xFF48];
        for (var _i = 0; _i < array_length(_vec_addr); _i++) {
            var _a = scr_ext_peek16(_vec_addr[_i]);
            var _skip = false;
            for (var _k = 0; _k < array_length(_rom_default); _k++) {
                if (_a == _rom_default[_k]) {
                    _skip = true;
                }
            }
            if (!_skip) {
                array_push(_list, { addr : _a, strong : false, why : _vec_name[_i] });
            }
        }
        return _list;
    }

    for (var _s = 0; _s < array_length(segments); _s++) {
        var _seg = segments[_s];
        if (_seg.start == 0x0801) {
            var _found = scr_ext_find_basic_sys();
            for (var _k = 0; _k < array_length(_found); _k++) {
                array_push(_list, { addr : _found[_k], strong : true, why : "BASIC SYS" });
            }
        }
        else {
            array_push(_list, { addr : _seg.start, strong : false, why : "load address" });
        }
    }
    return _list;
}

/// @desc scr_ext_find_basic_sys()
/// Walks the BASIC program at $0801 and returns every SYS target found.
function scr_ext_find_basic_sys() {
    var _out = [];
    var _p = 0x0801;
    var _lines = 0;
    while (_lines < 10) {
        if (!scr_ext_is_loaded(_p)) {
            break;
        }
        var _link = scr_ext_peek16(_p);
        if (_link == 0) {
            break;
        }
        var _q = _p + 4;
        var _end = _p + 84;
        while (_q < _end) {
            var _b = scr_ext_peek8(_q);
            if (_b == 0) {
                break;
            }
            if (_b == 0x9E) {
                var _r = _q + 1;
                var _rb = scr_ext_peek8(_r);
                while (_rb == 0x20 || _rb == 0x28) {
                    _r++;
                    _rb = scr_ext_peek8(_r);
                }
                var _val = 0;
                var _digits = 0;
                while (_rb >= 0x30 && _rb <= 0x39 && _digits < 5) {
                    _val = _val * 10 + (_rb - 0x30);
                    _digits++;
                    _r++;
                    _rb = scr_ext_peek8(_r);
                }
                if (_digits > 0 && _val < 65536) {
                    array_push(_out, _val);
                }
            }
            _q++;
        }
        if (_link <= _p) {
            break;
        }
        _p = _link;
        _lines++;
    }
    return _out;
}

/// @desc scr_ext_op_target(addr, op)
/// Operand value: branch destination, absolute address or zero-page/immediate byte.
function scr_ext_op_target(_a, _op) {
    switch (_op.mode) {
        case EXT_MODE_REL:
            var _d = scr_ext_peek8(_a + 1);
            if (_d > 127) {
                _d -= 256;
            }
            return (_a + 2 + _d) & 0xFFFF;
        case EXT_MODE_ABS:
        case EXT_MODE_ABX:
        case EXT_MODE_ABY:
        case EXT_MODE_IND:
            return scr_ext_peek16(_a + 1);
        case EXT_MODE_IMM:
        case EXT_MODE_ZP:
        case EXT_MODE_ZPX:
        case EXT_MODE_ZPY:
        case EXT_MODE_IZX:
        case EXT_MODE_IZY:
            return scr_ext_peek8(_a + 1);
    }
    return -1;
}

/// @desc scr_ext_trace(start, level)
/// Recursive-descent disassembly. Marks instruction bytes with 'level'
/// (EXT_CLS_SURE or EXT_CLS_LIKELY) and follows branches, JSR and JMP.
function scr_ext_trace(_start, _level) {
    var _ops = global.ext_ops;
    var _stack = [_start & 0xFFFF];
    var _guard = 0;
    var _max = 200000;

    while (array_length(_stack) > 0 && _guard < _max) {
        var _a = array_pop(_stack);
        var _walking = true;
        while (_walking) {
            _guard++;
            if (_guard >= _max) {
                break;
            }
            if (buffer_peek(loaded_buf, _a, buffer_u8) == 0) {
                break;
            }
            var _cls_here = buffer_peek(cls_buf, _a, buffer_u8);
            if (buffer_peek(istart_buf, _a, buffer_u8) == 1) {
                // Already traced at this level or better
                if (_cls_here == EXT_CLS_SURE || _cls_here == _level) {
                    break;
                }
            }
            else {
                // Landing in the middle of an existing instruction
                if (_cls_here == EXT_CLS_SURE || _cls_here == EXT_CLS_LIKELY) {
                    break;
                }
            }

            var _op = _ops[buffer_peek(mem_buf, _a, buffer_u8)];
            if (_op.flow == EXT_FLOW_JAM || _op.unstable) {
                break;
            }

            var _ok = true;
            for (var _k = 0; _k < _op.size; _k++) {
                var _b = (_a + _k) & 0xFFFF;
                if (buffer_peek(loaded_buf, _b, buffer_u8) == 0) {
                    _ok = false;
                }
                if (_k > 0) {
                    if (buffer_peek(istart_buf, _b, buffer_u8) == 1) {
                        _ok = false;
                    }
                }
            }
            if (!_ok) {
                break;
            }

            buffer_poke(istart_buf, _a, buffer_u8, 1);
            for (var _k = 0; _k < _op.size; _k++) {
                var _b = (_a + _k) & 0xFFFF;
                if (buffer_peek(cls_buf, _b, buffer_u8) != EXT_CLS_SURE) {
                    buffer_poke(cls_buf, _b, buffer_u8, _level);
                }
            }

            switch (_op.flow) {
                case EXT_FLOW_BRANCH:
                case EXT_FLOW_JSR:
                    array_push(_stack, scr_ext_op_target(_a, _op));
                    break;
                case EXT_FLOW_JMP:
                    array_push(_stack, scr_ext_op_target(_a, _op));
                    _walking = false;
                    break;
                case EXT_FLOW_STOP:
                    _walking = false;
                    break;
            }
            _a = (_a + _op.size) & 0xFFFF;
        }
    }
}

/// @desc scr_ext_seq_score(addr)
/// Scores a linear run of instructions starting at addr.
/// High = looks like code, low/negative = looks like data.
function scr_ext_seq_score(_p) {
    var _ops = global.ext_ops;
    var _score = 0;
    var _a = _p;
    var _prev = -1;
    var _same = 0;

    for (var _i = 0; _i < EXT_SEQ_LENGTH; _i++) {
        if (buffer_peek(loaded_buf, _a, buffer_u8) == 0) {
            _score -= 4;
            break;
        }
        var _byte = buffer_peek(mem_buf, _a, buffer_u8);
        var _op = _ops[_byte];

        if (_op.flow == EXT_FLOW_JAM) {
            _score -= 12;
            break;
        }
        if (_op.unstable) {
            _score -= 8;
            break;
        }
        if (_byte == 0x00) {
            _score -= 5;
            break;
        }

        var _bad = false;
        for (var _k = 1; _k < _op.size; _k++) {
            if (buffer_peek(loaded_buf, (_a + _k) & 0xFFFF, buffer_u8) == 0) {
                _bad = true;
            }
        }
        if (_bad) {
            _score -= 4;
            break;
        }

        if (_op.illegal) {
            if (_op.mn == "NOP") {
                _score -= 3;
            }
            else {
                _score -= 2;
            }
        }
        else {
            _score += 2;
        }

        // Runs of the same opcode are typical of data
        if (_byte == _prev) {
            _same++;
            if (_same >= 2) {
                _score -= 6;
                break;
            }
        }
        else {
            _same = 0;
        }
        _prev = _byte;

        // Absolute operands: where do they point?
        if (_op.size == 3) {
            var _t = scr_ext_peek16(_a + 1);
            if (_t < 0x0100) {
                _score -= 2;        // assemblers use zero-page modes for these
            }
            else if (_t >= 0xD000 && _t < 0xE000) {
                _score += 2;        // VIC / SID / CIA / colour RAM
            }
            else if (_t >= 0xFF81 && _t <= 0xFFF3) {
                _score += 2;        // KERNAL jump table
            }
            else if (buffer_peek(loaded_buf, _t, buffer_u8) == 1) {
                _score += 1;
            }
            else if (_t < 0x0400) {
                _score += 1;        // stack, vectors, system area
            }
            else {
                _score -= 1;
            }
        }

        if (_op.mode == EXT_MODE_REL) {
            var _bt = scr_ext_op_target(_a, _op);
            if (buffer_peek(loaded_buf, _bt, buffer_u8) == 1) {
                _score += 1;
            }
            else {
                _score -= 3;
            }
        }

        if (_op.flow == EXT_FLOW_STOP || _op.flow == EXT_FLOW_JMP) {
            _score += 3;
            break;
        }
        _a = (_a + _op.size) & 0xFFFF;
    }
    return _score;
}

/// @desc scr_ext_score_unknown()
/// Linear sweep over every untraced loaded byte, classifying it by sequence score.
function scr_ext_score_unknown() {
    var _ops = global.ext_ops;
    var _p = 0;
    while (_p < 65536) {
        if (buffer_peek(cls_buf, _p, buffer_u8) != EXT_CLS_UNKNOWN) {
            _p++;
            continue;
        }
        var _s = scr_ext_seq_score(_p);
        var _size = _ops[buffer_peek(mem_buf, _p, buffer_u8)].size;

        var _level = EXT_CLS_NOT;
        if (_s >= EXT_LIKELY_SCORE) {
            _level = EXT_CLS_LIKELY;
        }
        else if (_s >= EXT_DOUBT_SCORE) {
            _level = EXT_CLS_DOUBT;
        }

        if (_level != EXT_CLS_NOT && _p + _size <= 65536) {
            var _free = true;
            for (var _k = 0; _k < _size; _k++) {
                if (buffer_peek(cls_buf, _p + _k, buffer_u8) != EXT_CLS_UNKNOWN) {
                    _free = false;
                }
            }
            if (_free) {
                buffer_poke(istart_buf, _p, buffer_u8, 1);
                for (var _k = 0; _k < _size; _k++) {
                    buffer_poke(cls_buf, _p + _k, buffer_u8, _level);
                }
                _p += _size;
                continue;
            }
        }
        buffer_poke(cls_buf, _p, buffer_u8, EXT_CLS_NOT);
        _p++;
    }
}

/// @desc scr_ext_count_classes()
function scr_ext_count_classes() {
    cls_counts = array_create(EXT_CLS_COUNT, 0);
    for (var _i = 0; _i < 65536; _i++) {
        var _c = buffer_peek(cls_buf, _i, buffer_u8);
        cls_counts[_c] += 1;
    }
}
