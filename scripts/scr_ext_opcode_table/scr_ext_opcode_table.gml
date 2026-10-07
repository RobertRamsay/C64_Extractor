/// @desc scr_ext_opcode_table()
/// Returns a 256-entry array indexed by opcode byte. Each entry is a struct:
/// { opcode, mn, mode, size, illegal, unstable, flow }
/// Includes every illegal opcode, since their presence drives the code / junk scoring.
function scr_ext_opcode_table() {
    var _t = array_create(256, 0);

    _t[$00] = scr_ext_op($00, "BRK", EXT_MODE_IMP);
    _t[$01] = scr_ext_op($01, "ORA", EXT_MODE_IZX);
    _t[$02] = scr_ext_op($02, "JAM", EXT_MODE_IMP);
    _t[$03] = scr_ext_op($03, "SLO", EXT_MODE_IZX);
    _t[$04] = scr_ext_op($04, "NOP", EXT_MODE_ZP);
    _t[$05] = scr_ext_op($05, "ORA", EXT_MODE_ZP);
    _t[$06] = scr_ext_op($06, "ASL", EXT_MODE_ZP);
    _t[$07] = scr_ext_op($07, "SLO", EXT_MODE_ZP);
    _t[$08] = scr_ext_op($08, "PHP", EXT_MODE_IMP);
    _t[$09] = scr_ext_op($09, "ORA", EXT_MODE_IMM);
    _t[$0A] = scr_ext_op($0A, "ASL", EXT_MODE_ACC);
    _t[$0B] = scr_ext_op($0B, "ANC", EXT_MODE_IMM);
    _t[$0C] = scr_ext_op($0C, "NOP", EXT_MODE_ABS);
    _t[$0D] = scr_ext_op($0D, "ORA", EXT_MODE_ABS);
    _t[$0E] = scr_ext_op($0E, "ASL", EXT_MODE_ABS);
    _t[$0F] = scr_ext_op($0F, "SLO", EXT_MODE_ABS);
    _t[$10] = scr_ext_op($10, "BPL", EXT_MODE_REL);
    _t[$11] = scr_ext_op($11, "ORA", EXT_MODE_IZY);
    _t[$12] = scr_ext_op($12, "JAM", EXT_MODE_IMP);
    _t[$13] = scr_ext_op($13, "SLO", EXT_MODE_IZY);
    _t[$14] = scr_ext_op($14, "NOP", EXT_MODE_ZPX);
    _t[$15] = scr_ext_op($15, "ORA", EXT_MODE_ZPX);
    _t[$16] = scr_ext_op($16, "ASL", EXT_MODE_ZPX);
    _t[$17] = scr_ext_op($17, "SLO", EXT_MODE_ZPX);
    _t[$18] = scr_ext_op($18, "CLC", EXT_MODE_IMP);
    _t[$19] = scr_ext_op($19, "ORA", EXT_MODE_ABY);
    _t[$1A] = scr_ext_op($1A, "NOP", EXT_MODE_IMP);
    _t[$1B] = scr_ext_op($1B, "SLO", EXT_MODE_ABY);
    _t[$1C] = scr_ext_op($1C, "NOP", EXT_MODE_ABX);
    _t[$1D] = scr_ext_op($1D, "ORA", EXT_MODE_ABX);
    _t[$1E] = scr_ext_op($1E, "ASL", EXT_MODE_ABX);
    _t[$1F] = scr_ext_op($1F, "SLO", EXT_MODE_ABX);
    _t[$20] = scr_ext_op($20, "JSR", EXT_MODE_ABS);
    _t[$21] = scr_ext_op($21, "AND", EXT_MODE_IZX);
    _t[$22] = scr_ext_op($22, "JAM", EXT_MODE_IMP);
    _t[$23] = scr_ext_op($23, "RLA", EXT_MODE_IZX);
    _t[$24] = scr_ext_op($24, "BIT", EXT_MODE_ZP);
    _t[$25] = scr_ext_op($25, "AND", EXT_MODE_ZP);
    _t[$26] = scr_ext_op($26, "ROL", EXT_MODE_ZP);
    _t[$27] = scr_ext_op($27, "RLA", EXT_MODE_ZP);
    _t[$28] = scr_ext_op($28, "PLP", EXT_MODE_IMP);
    _t[$29] = scr_ext_op($29, "AND", EXT_MODE_IMM);
    _t[$2A] = scr_ext_op($2A, "ROL", EXT_MODE_ACC);
    _t[$2B] = scr_ext_op($2B, "ANC", EXT_MODE_IMM);
    _t[$2C] = scr_ext_op($2C, "BIT", EXT_MODE_ABS);
    _t[$2D] = scr_ext_op($2D, "AND", EXT_MODE_ABS);
    _t[$2E] = scr_ext_op($2E, "ROL", EXT_MODE_ABS);
    _t[$2F] = scr_ext_op($2F, "RLA", EXT_MODE_ABS);
    _t[$30] = scr_ext_op($30, "BMI", EXT_MODE_REL);
    _t[$31] = scr_ext_op($31, "AND", EXT_MODE_IZY);
    _t[$32] = scr_ext_op($32, "JAM", EXT_MODE_IMP);
    _t[$33] = scr_ext_op($33, "RLA", EXT_MODE_IZY);
    _t[$34] = scr_ext_op($34, "NOP", EXT_MODE_ZPX);
    _t[$35] = scr_ext_op($35, "AND", EXT_MODE_ZPX);
    _t[$36] = scr_ext_op($36, "ROL", EXT_MODE_ZPX);
    _t[$37] = scr_ext_op($37, "RLA", EXT_MODE_ZPX);
    _t[$38] = scr_ext_op($38, "SEC", EXT_MODE_IMP);
    _t[$39] = scr_ext_op($39, "AND", EXT_MODE_ABY);
    _t[$3A] = scr_ext_op($3A, "NOP", EXT_MODE_IMP);
    _t[$3B] = scr_ext_op($3B, "RLA", EXT_MODE_ABY);
    _t[$3C] = scr_ext_op($3C, "NOP", EXT_MODE_ABX);
    _t[$3D] = scr_ext_op($3D, "AND", EXT_MODE_ABX);
    _t[$3E] = scr_ext_op($3E, "ROL", EXT_MODE_ABX);
    _t[$3F] = scr_ext_op($3F, "RLA", EXT_MODE_ABX);
    _t[$40] = scr_ext_op($40, "RTI", EXT_MODE_IMP);
    _t[$41] = scr_ext_op($41, "EOR", EXT_MODE_IZX);
    _t[$42] = scr_ext_op($42, "JAM", EXT_MODE_IMP);
    _t[$43] = scr_ext_op($43, "SRE", EXT_MODE_IZX);
    _t[$44] = scr_ext_op($44, "NOP", EXT_MODE_ZP);
    _t[$45] = scr_ext_op($45, "EOR", EXT_MODE_ZP);
    _t[$46] = scr_ext_op($46, "LSR", EXT_MODE_ZP);
    _t[$47] = scr_ext_op($47, "SRE", EXT_MODE_ZP);
    _t[$48] = scr_ext_op($48, "PHA", EXT_MODE_IMP);
    _t[$49] = scr_ext_op($49, "EOR", EXT_MODE_IMM);
    _t[$4A] = scr_ext_op($4A, "LSR", EXT_MODE_ACC);
    _t[$4B] = scr_ext_op($4B, "ALR", EXT_MODE_IMM);
    _t[$4C] = scr_ext_op($4C, "JMP", EXT_MODE_ABS);
    _t[$4D] = scr_ext_op($4D, "EOR", EXT_MODE_ABS);
    _t[$4E] = scr_ext_op($4E, "LSR", EXT_MODE_ABS);
    _t[$4F] = scr_ext_op($4F, "SRE", EXT_MODE_ABS);
    _t[$50] = scr_ext_op($50, "BVC", EXT_MODE_REL);
    _t[$51] = scr_ext_op($51, "EOR", EXT_MODE_IZY);
    _t[$52] = scr_ext_op($52, "JAM", EXT_MODE_IMP);
    _t[$53] = scr_ext_op($53, "SRE", EXT_MODE_IZY);
    _t[$54] = scr_ext_op($54, "NOP", EXT_MODE_ZPX);
    _t[$55] = scr_ext_op($55, "EOR", EXT_MODE_ZPX);
    _t[$56] = scr_ext_op($56, "LSR", EXT_MODE_ZPX);
    _t[$57] = scr_ext_op($57, "SRE", EXT_MODE_ZPX);
    _t[$58] = scr_ext_op($58, "CLI", EXT_MODE_IMP);
    _t[$59] = scr_ext_op($59, "EOR", EXT_MODE_ABY);
    _t[$5A] = scr_ext_op($5A, "NOP", EXT_MODE_IMP);
    _t[$5B] = scr_ext_op($5B, "SRE", EXT_MODE_ABY);
    _t[$5C] = scr_ext_op($5C, "NOP", EXT_MODE_ABX);
    _t[$5D] = scr_ext_op($5D, "EOR", EXT_MODE_ABX);
    _t[$5E] = scr_ext_op($5E, "LSR", EXT_MODE_ABX);
    _t[$5F] = scr_ext_op($5F, "SRE", EXT_MODE_ABX);
    _t[$60] = scr_ext_op($60, "RTS", EXT_MODE_IMP);
    _t[$61] = scr_ext_op($61, "ADC", EXT_MODE_IZX);
    _t[$62] = scr_ext_op($62, "JAM", EXT_MODE_IMP);
    _t[$63] = scr_ext_op($63, "RRA", EXT_MODE_IZX);
    _t[$64] = scr_ext_op($64, "NOP", EXT_MODE_ZP);
    _t[$65] = scr_ext_op($65, "ADC", EXT_MODE_ZP);
    _t[$66] = scr_ext_op($66, "ROR", EXT_MODE_ZP);
    _t[$67] = scr_ext_op($67, "RRA", EXT_MODE_ZP);
    _t[$68] = scr_ext_op($68, "PLA", EXT_MODE_IMP);
    _t[$69] = scr_ext_op($69, "ADC", EXT_MODE_IMM);
    _t[$6A] = scr_ext_op($6A, "ROR", EXT_MODE_ACC);
    _t[$6B] = scr_ext_op($6B, "ARR", EXT_MODE_IMM);
    _t[$6C] = scr_ext_op($6C, "JMP", EXT_MODE_IND);
    _t[$6D] = scr_ext_op($6D, "ADC", EXT_MODE_ABS);
    _t[$6E] = scr_ext_op($6E, "ROR", EXT_MODE_ABS);
    _t[$6F] = scr_ext_op($6F, "RRA", EXT_MODE_ABS);
    _t[$70] = scr_ext_op($70, "BVS", EXT_MODE_REL);
    _t[$71] = scr_ext_op($71, "ADC", EXT_MODE_IZY);
    _t[$72] = scr_ext_op($72, "JAM", EXT_MODE_IMP);
    _t[$73] = scr_ext_op($73, "RRA", EXT_MODE_IZY);
    _t[$74] = scr_ext_op($74, "NOP", EXT_MODE_ZPX);
    _t[$75] = scr_ext_op($75, "ADC", EXT_MODE_ZPX);
    _t[$76] = scr_ext_op($76, "ROR", EXT_MODE_ZPX);
    _t[$77] = scr_ext_op($77, "RRA", EXT_MODE_ZPX);
    _t[$78] = scr_ext_op($78, "SEI", EXT_MODE_IMP);
    _t[$79] = scr_ext_op($79, "ADC", EXT_MODE_ABY);
    _t[$7A] = scr_ext_op($7A, "NOP", EXT_MODE_IMP);
    _t[$7B] = scr_ext_op($7B, "RRA", EXT_MODE_ABY);
    _t[$7C] = scr_ext_op($7C, "NOP", EXT_MODE_ABX);
    _t[$7D] = scr_ext_op($7D, "ADC", EXT_MODE_ABX);
    _t[$7E] = scr_ext_op($7E, "ROR", EXT_MODE_ABX);
    _t[$7F] = scr_ext_op($7F, "RRA", EXT_MODE_ABX);
    _t[$80] = scr_ext_op($80, "NOP", EXT_MODE_IMM);
    _t[$81] = scr_ext_op($81, "STA", EXT_MODE_IZX);
    _t[$82] = scr_ext_op($82, "NOP", EXT_MODE_IMM);
    _t[$83] = scr_ext_op($83, "SAX", EXT_MODE_IZX);
    _t[$84] = scr_ext_op($84, "STY", EXT_MODE_ZP);
    _t[$85] = scr_ext_op($85, "STA", EXT_MODE_ZP);
    _t[$86] = scr_ext_op($86, "STX", EXT_MODE_ZP);
    _t[$87] = scr_ext_op($87, "SAX", EXT_MODE_ZP);
    _t[$88] = scr_ext_op($88, "DEY", EXT_MODE_IMP);
    _t[$89] = scr_ext_op($89, "NOP", EXT_MODE_IMM);
    _t[$8A] = scr_ext_op($8A, "TXA", EXT_MODE_IMP);
    _t[$8B] = scr_ext_op($8B, "ANE", EXT_MODE_IMM);
    _t[$8C] = scr_ext_op($8C, "STY", EXT_MODE_ABS);
    _t[$8D] = scr_ext_op($8D, "STA", EXT_MODE_ABS);
    _t[$8E] = scr_ext_op($8E, "STX", EXT_MODE_ABS);
    _t[$8F] = scr_ext_op($8F, "SAX", EXT_MODE_ABS);
    _t[$90] = scr_ext_op($90, "BCC", EXT_MODE_REL);
    _t[$91] = scr_ext_op($91, "STA", EXT_MODE_IZY);
    _t[$92] = scr_ext_op($92, "JAM", EXT_MODE_IMP);
    _t[$93] = scr_ext_op($93, "SHA", EXT_MODE_IZY);
    _t[$94] = scr_ext_op($94, "STY", EXT_MODE_ZPX);
    _t[$95] = scr_ext_op($95, "STA", EXT_MODE_ZPX);
    _t[$96] = scr_ext_op($96, "STX", EXT_MODE_ZPY);
    _t[$97] = scr_ext_op($97, "SAX", EXT_MODE_ZPY);
    _t[$98] = scr_ext_op($98, "TYA", EXT_MODE_IMP);
    _t[$99] = scr_ext_op($99, "STA", EXT_MODE_ABY);
    _t[$9A] = scr_ext_op($9A, "TXS", EXT_MODE_IMP);
    _t[$9B] = scr_ext_op($9B, "TAS", EXT_MODE_ABY);
    _t[$9C] = scr_ext_op($9C, "SHY", EXT_MODE_ABX);
    _t[$9D] = scr_ext_op($9D, "STA", EXT_MODE_ABX);
    _t[$9E] = scr_ext_op($9E, "SHX", EXT_MODE_ABY);
    _t[$9F] = scr_ext_op($9F, "SHA", EXT_MODE_ABY);
    _t[$A0] = scr_ext_op($A0, "LDY", EXT_MODE_IMM);
    _t[$A1] = scr_ext_op($A1, "LDA", EXT_MODE_IZX);
    _t[$A2] = scr_ext_op($A2, "LDX", EXT_MODE_IMM);
    _t[$A3] = scr_ext_op($A3, "LAX", EXT_MODE_IZX);
    _t[$A4] = scr_ext_op($A4, "LDY", EXT_MODE_ZP);
    _t[$A5] = scr_ext_op($A5, "LDA", EXT_MODE_ZP);
    _t[$A6] = scr_ext_op($A6, "LDX", EXT_MODE_ZP);
    _t[$A7] = scr_ext_op($A7, "LAX", EXT_MODE_ZP);
    _t[$A8] = scr_ext_op($A8, "TAY", EXT_MODE_IMP);
    _t[$A9] = scr_ext_op($A9, "LDA", EXT_MODE_IMM);
    _t[$AA] = scr_ext_op($AA, "TAX", EXT_MODE_IMP);
    _t[$AB] = scr_ext_op($AB, "LXA", EXT_MODE_IMM);
    _t[$AC] = scr_ext_op($AC, "LDY", EXT_MODE_ABS);
    _t[$AD] = scr_ext_op($AD, "LDA", EXT_MODE_ABS);
    _t[$AE] = scr_ext_op($AE, "LDX", EXT_MODE_ABS);
    _t[$AF] = scr_ext_op($AF, "LAX", EXT_MODE_ABS);
    _t[$B0] = scr_ext_op($B0, "BCS", EXT_MODE_REL);
    _t[$B1] = scr_ext_op($B1, "LDA", EXT_MODE_IZY);
    _t[$B2] = scr_ext_op($B2, "JAM", EXT_MODE_IMP);
    _t[$B3] = scr_ext_op($B3, "LAX", EXT_MODE_IZY);
    _t[$B4] = scr_ext_op($B4, "LDY", EXT_MODE_ZPX);
    _t[$B5] = scr_ext_op($B5, "LDA", EXT_MODE_ZPX);
    _t[$B6] = scr_ext_op($B6, "LDX", EXT_MODE_ZPY);
    _t[$B7] = scr_ext_op($B7, "LAX", EXT_MODE_ZPY);
    _t[$B8] = scr_ext_op($B8, "CLV", EXT_MODE_IMP);
    _t[$B9] = scr_ext_op($B9, "LDA", EXT_MODE_ABY);
    _t[$BA] = scr_ext_op($BA, "TSX", EXT_MODE_IMP);
    _t[$BB] = scr_ext_op($BB, "LAS", EXT_MODE_ABY);
    _t[$BC] = scr_ext_op($BC, "LDY", EXT_MODE_ABX);
    _t[$BD] = scr_ext_op($BD, "LDA", EXT_MODE_ABX);
    _t[$BE] = scr_ext_op($BE, "LDX", EXT_MODE_ABY);
    _t[$BF] = scr_ext_op($BF, "LAX", EXT_MODE_ABY);
    _t[$C0] = scr_ext_op($C0, "CPY", EXT_MODE_IMM);
    _t[$C1] = scr_ext_op($C1, "CMP", EXT_MODE_IZX);
    _t[$C2] = scr_ext_op($C2, "NOP", EXT_MODE_IMM);
    _t[$C3] = scr_ext_op($C3, "DCP", EXT_MODE_IZX);
    _t[$C4] = scr_ext_op($C4, "CPY", EXT_MODE_ZP);
    _t[$C5] = scr_ext_op($C5, "CMP", EXT_MODE_ZP);
    _t[$C6] = scr_ext_op($C6, "DEC", EXT_MODE_ZP);
    _t[$C7] = scr_ext_op($C7, "DCP", EXT_MODE_ZP);
    _t[$C8] = scr_ext_op($C8, "INY", EXT_MODE_IMP);
    _t[$C9] = scr_ext_op($C9, "CMP", EXT_MODE_IMM);
    _t[$CA] = scr_ext_op($CA, "DEX", EXT_MODE_IMP);
    _t[$CB] = scr_ext_op($CB, "SBX", EXT_MODE_IMM);
    _t[$CC] = scr_ext_op($CC, "CPY", EXT_MODE_ABS);
    _t[$CD] = scr_ext_op($CD, "CMP", EXT_MODE_ABS);
    _t[$CE] = scr_ext_op($CE, "DEC", EXT_MODE_ABS);
    _t[$CF] = scr_ext_op($CF, "DCP", EXT_MODE_ABS);
    _t[$D0] = scr_ext_op($D0, "BNE", EXT_MODE_REL);
    _t[$D1] = scr_ext_op($D1, "CMP", EXT_MODE_IZY);
    _t[$D2] = scr_ext_op($D2, "JAM", EXT_MODE_IMP);
    _t[$D3] = scr_ext_op($D3, "DCP", EXT_MODE_IZY);
    _t[$D4] = scr_ext_op($D4, "NOP", EXT_MODE_ZPX);
    _t[$D5] = scr_ext_op($D5, "CMP", EXT_MODE_ZPX);
    _t[$D6] = scr_ext_op($D6, "DEC", EXT_MODE_ZPX);
    _t[$D7] = scr_ext_op($D7, "DCP", EXT_MODE_ZPX);
    _t[$D8] = scr_ext_op($D8, "CLD", EXT_MODE_IMP);
    _t[$D9] = scr_ext_op($D9, "CMP", EXT_MODE_ABY);
    _t[$DA] = scr_ext_op($DA, "NOP", EXT_MODE_IMP);
    _t[$DB] = scr_ext_op($DB, "DCP", EXT_MODE_ABY);
    _t[$DC] = scr_ext_op($DC, "NOP", EXT_MODE_ABX);
    _t[$DD] = scr_ext_op($DD, "CMP", EXT_MODE_ABX);
    _t[$DE] = scr_ext_op($DE, "DEC", EXT_MODE_ABX);
    _t[$DF] = scr_ext_op($DF, "DCP", EXT_MODE_ABX);
    _t[$E0] = scr_ext_op($E0, "CPX", EXT_MODE_IMM);
    _t[$E1] = scr_ext_op($E1, "SBC", EXT_MODE_IZX);
    _t[$E2] = scr_ext_op($E2, "NOP", EXT_MODE_IMM);
    _t[$E3] = scr_ext_op($E3, "ISC", EXT_MODE_IZX);
    _t[$E4] = scr_ext_op($E4, "CPX", EXT_MODE_ZP);
    _t[$E5] = scr_ext_op($E5, "SBC", EXT_MODE_ZP);
    _t[$E6] = scr_ext_op($E6, "INC", EXT_MODE_ZP);
    _t[$E7] = scr_ext_op($E7, "ISC", EXT_MODE_ZP);
    _t[$E8] = scr_ext_op($E8, "INX", EXT_MODE_IMP);
    _t[$E9] = scr_ext_op($E9, "SBC", EXT_MODE_IMM);
    _t[$EA] = scr_ext_op($EA, "NOP", EXT_MODE_IMP);
    _t[$EB] = scr_ext_op($EB, "SBC", EXT_MODE_IMM);
    _t[$EC] = scr_ext_op($EC, "CPX", EXT_MODE_ABS);
    _t[$ED] = scr_ext_op($ED, "SBC", EXT_MODE_ABS);
    _t[$EE] = scr_ext_op($EE, "INC", EXT_MODE_ABS);
    _t[$EF] = scr_ext_op($EF, "ISC", EXT_MODE_ABS);
    _t[$F0] = scr_ext_op($F0, "BEQ", EXT_MODE_REL);
    _t[$F1] = scr_ext_op($F1, "SBC", EXT_MODE_IZY);
    _t[$F2] = scr_ext_op($F2, "JAM", EXT_MODE_IMP);
    _t[$F3] = scr_ext_op($F3, "ISC", EXT_MODE_IZY);
    _t[$F4] = scr_ext_op($F4, "NOP", EXT_MODE_ZPX);
    _t[$F5] = scr_ext_op($F5, "SBC", EXT_MODE_ZPX);
    _t[$F6] = scr_ext_op($F6, "INC", EXT_MODE_ZPX);
    _t[$F7] = scr_ext_op($F7, "ISC", EXT_MODE_ZPX);
    _t[$F8] = scr_ext_op($F8, "SED", EXT_MODE_IMP);
    _t[$F9] = scr_ext_op($F9, "SBC", EXT_MODE_ABY);
    _t[$FA] = scr_ext_op($FA, "NOP", EXT_MODE_IMP);
    _t[$FB] = scr_ext_op($FB, "ISC", EXT_MODE_ABY);
    _t[$FC] = scr_ext_op($FC, "NOP", EXT_MODE_ABX);
    _t[$FD] = scr_ext_op($FD, "SBC", EXT_MODE_ABX);
    _t[$FE] = scr_ext_op($FE, "INC", EXT_MODE_ABX);
    _t[$FF] = scr_ext_op($FF, "ISC", EXT_MODE_ABX);

    return _t;
}

/// @desc scr_ext_op(opcode, mnemonic, mode)
/// Builds one decode-table entry.
function scr_ext_op(_opcode, _mn, _mode) {
    var _size = 2;
    switch (_mode) {
        case EXT_MODE_IMP:
        case EXT_MODE_ACC:
            _size = 1;
            break;
        case EXT_MODE_ABS:
        case EXT_MODE_ABX:
        case EXT_MODE_ABY:
        case EXT_MODE_IND:
            _size = 3;
            break;
        default:
            _size = 2;
            break;
    }

    var _illegal = false;
    var _unstable = false;
    switch (_mn) {
        case "JAM": case "SLO": case "RLA": case "SRE": case "RRA":
        case "SAX": case "LAX": case "DCP": case "ISC": case "ANC":
        case "ALR": case "ARR": case "SBX":
            _illegal = true;
            break;
        case "ANE": case "LXA": case "SHA": case "TAS": case "SHY":
        case "SHX": case "LAS":
            _illegal = true;
            _unstable = true;
            break;
    }
    if (_mn == "NOP") {
        if (_opcode != $EA) {
            _illegal = true;
        }
    }
    if (_opcode == $EB) {
        _illegal = true;
    }

    var _flow = EXT_FLOW_NORMAL;
    if (_mode == EXT_MODE_REL) {
        _flow = EXT_FLOW_BRANCH;
    }
    else if (_mn == "JSR") {
        _flow = EXT_FLOW_JSR;
    }
    else if (_mn == "JMP") {
        if (_mode == EXT_MODE_ABS) {
            _flow = EXT_FLOW_JMP;
        }
        else {
            _flow = EXT_FLOW_STOP;
        }
    }
    else if (_mn == "RTS" || _mn == "RTI" || _mn == "BRK") {
        _flow = EXT_FLOW_STOP;
    }
    else if (_mn == "JAM") {
        _flow = EXT_FLOW_JAM;
    }

    return {
        opcode   : _opcode,
        mn       : _mn,
        mode     : _mode,
        size     : _size,
        illegal  : _illegal,
        unstable : _unstable,
        flow     : _flow
    };
}
