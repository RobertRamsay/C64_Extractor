/// @desc scr_ext_format_operand(addr, op)
function scr_ext_format_operand(_a, _op) {
    switch (_op.mode) {
        case EXT_MODE_IMP: return "";
        case EXT_MODE_ACC: return "A";
        case EXT_MODE_IMM: return "#$" + scr_ext_hex(scr_ext_peek8(_a + 1), 2);
        case EXT_MODE_ZP:  return "$" + scr_ext_hex(scr_ext_peek8(_a + 1), 2);
        case EXT_MODE_ZPX: return "$" + scr_ext_hex(scr_ext_peek8(_a + 1), 2) + ",X";
        case EXT_MODE_ZPY: return "$" + scr_ext_hex(scr_ext_peek8(_a + 1), 2) + ",Y";
        case EXT_MODE_ABS: return "$" + scr_ext_hex(scr_ext_peek16(_a + 1), 4);
        case EXT_MODE_ABX: return "$" + scr_ext_hex(scr_ext_peek16(_a + 1), 4) + ",X";
        case EXT_MODE_ABY: return "$" + scr_ext_hex(scr_ext_peek16(_a + 1), 4) + ",Y";
        case EXT_MODE_IND: return "($" + scr_ext_hex(scr_ext_peek16(_a + 1), 4) + ")";
        case EXT_MODE_IZX: return "($" + scr_ext_hex(scr_ext_peek8(_a + 1), 2) + ",X)";
        case EXT_MODE_IZY: return "($" + scr_ext_hex(scr_ext_peek8(_a + 1), 2) + "),Y";
        case EXT_MODE_REL: return "$" + scr_ext_hex(scr_ext_op_target(_a, _op), 4);
    }
    return "";
}

/// @desc scr_ext_disasm_line(addr)
/// One line of the disassembly view: an instruction where the analyser found one,
/// otherwise up to 4 data bytes of the same class, or a collapsed not-loaded run.
/// Returns { addr, size, bytes, text, cls, entry }.
function scr_ext_disasm_line(_a) {
    var _addr = _a & $FFFF;
    var _cls = buffer_peek(cls_buf, _addr, buffer_u8);
    var _line = {
        addr  : _addr,
        size  : 1,
        bytes : "",
        text  : "",
        cls   : _cls,
        entry : buffer_peek(entry_buf, _addr, buffer_u8) == 1
    };

    if (_cls == EXT_CLS_NONE) {
        var _n = 0;
        var _b = _addr;
        while (_n < 256) {
            if (buffer_peek(loaded_buf, _b, buffer_u8) == 1) {
                break;
            }
            _n++;
            _b = (_b + 1) & $FFFF;
            if (_b == 0) {
                break;
            }
        }
        if (_n < 1) {
            _n = 1;
        }
        _line.size = _n;
        _line.text = "-- not loaded (" + string(_n) + " bytes)";
        return _line;
    }

    if (buffer_peek(istart_buf, _addr, buffer_u8) == 1) {
        var _op = global.ext_ops[buffer_peek(mem_buf, _addr, buffer_u8)];
        _line.size = _op.size;
        var _bytes = "";
        for (var _k = 0; _k < _op.size; _k++) {
            _bytes += scr_ext_hex(scr_ext_peek8(_addr + _k), 2) + " ";
        }
        _line.bytes = _bytes;
        var _text = _op.mn;
        var _operand = scr_ext_format_operand(_addr, _op);
        if (_operand != "") {
            _text += " " + _operand;
        }
        if (_op.illegal) {
            _text += "   ; illegal";
        }
        _line.text = _text;
        return _line;
    }

    // Data bytes
    var _count = 0;
    var _text_d = ".byte ";
    var _bytes_d = "";
    while (_count < 4) {
        var _bd = (_addr + _count) & $FFFF;
        if (_count > 0) {
            if (buffer_peek(cls_buf, _bd, buffer_u8) != _cls) {
                break;
            }
            if (buffer_peek(istart_buf, _bd, buffer_u8) == 1) {
                break;
            }
            if (buffer_peek(entry_buf, _bd, buffer_u8) == 1) {
                break;
            }
            _text_d += ",";
        }
        var _v = buffer_peek(mem_buf, _bd, buffer_u8);
        _text_d += "$" + scr_ext_hex(_v, 2);
        _bytes_d += scr_ext_hex(_v, 2) + " ";
        _count++;
    }
    _line.size = _count;
    _line.bytes = _bytes_d;
    _line.text = _text_d;
    return _line;
}

/// @desc scr_ext_align_to_instr(addr)
/// If addr sits inside a decoded instruction, returns that instruction's start.
function scr_ext_align_to_instr(_a) {
    var _addr = _a & $FFFF;
    if (buffer_peek(istart_buf, _addr, buffer_u8) == 1) {
        return _addr;
    }
    for (var _k = 1; _k <= 2; _k++) {
        var _b = (_addr - _k) & $FFFF;
        if (buffer_peek(istart_buf, _b, buffer_u8) == 1) {
            if (global.ext_ops[buffer_peek(mem_buf, _b, buffer_u8)].size > _k) {
                return _b;
            }
        }
    }
    return _addr;
}

/// @desc scr_ext_prev_line_start(addr)
/// Best guess at the start of the disassembly line before addr (for scrolling up).
function scr_ext_prev_line_start(_a) {
    var _addr = _a & $FFFF;
    var _prev = (_addr - 1) & $FFFF;

    // Not-loaded run: jump back over it (up to a page)
    if (buffer_peek(loaded_buf, _prev, buffer_u8) == 0) {
        var _n = 1;
        var _b = _prev;
        while (_n < 256) {
            var _c = (_b - 1) & $FFFF;
            if (buffer_peek(loaded_buf, _c, buffer_u8) == 1) {
                break;
            }
            _b = _c;
            _n++;
        }
        return _b;
    }

    // An instruction that ends exactly at addr
    for (var _k = 1; _k <= 3; _k++) {
        var _s = (_addr - _k) & $FFFF;
        if (buffer_peek(istart_buf, _s, buffer_u8) == 1) {
            if (global.ext_ops[buffer_peek(mem_buf, _s, buffer_u8)].size == _k) {
                return _s;
            }
        }
    }

    // Data: step back up to 4 bytes, stopping at code or not-loaded memory
    var _step = 1;
    while (_step < 4) {
        var _d = (_addr - _step - 1) & $FFFF;
        if (buffer_peek(loaded_buf, _d, buffer_u8) == 0) {
            break;
        }
        if (buffer_peek(istart_buf, _d, buffer_u8) == 1) {
            break;
        }
        _step++;
    }
    return (_addr - _step) & $FFFF;
}
