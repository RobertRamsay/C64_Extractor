/// @desc scr_ext_opcode_table()
/// Returns a 256-entry array indexed by opcode byte. Each entry is a struct:
/// { opcode, mn, mode, size, illegal, unstable, flow }
/// Includes every illegal opcode, since their presence drives the code / junk scoring.
function scr_ext_opcode_table() {
    var _t = array_create(256, 0);

    _t[0x00] = scr_ext_op(0x00, "BRK", EXT_MODE_IMP);
    _t[0x01] = scr_ext_op(0x01, "ORA", EXT_MODE_IZX);
    _t[0x02] = scr_ext_op(0x02, "JAM", EXT_MODE_IMP);
    _t[0x03] = scr_ext_op(0x03, "SLO", EXT_MODE_IZX);
    _t[0x04] = scr_ext_op(0x04, "NOP", EXT_MODE_ZP);
    _t[0x05] = scr_ext_op(0x05, "ORA", EXT_MODE_ZP);
    _t[0x06] = scr_ext_op(0x06, "ASL", EXT_MODE_ZP);
    _t[0x07] = scr_ext_op(0x07, "SLO", EXT_MODE_ZP);
    _t[0x08] = scr_ext_op(0x08, "PHP", EXT_MODE_IMP);
    _t[0x09] = scr_ext_op(0x09, "ORA", EXT_MODE_IMM);
    _t[0x0A] = scr_ext_op(0x0A, "ASL", EXT_MODE_ACC);
    _t[0x0B] = scr_ext_op(0x0B, "ANC", EXT_MODE_IMM);
    _t[0x0C] = scr_ext_op(0x0C, "NOP", EXT_MODE_ABS);
    _t[0x0D] = scr_ext_op(0x0D, "ORA", EXT_MODE_ABS);
    _t[0x0E] = scr_ext_op(0x0E, "ASL", EXT_MODE_ABS);
    _t[0x0F] = scr_ext_op(0x0F, "SLO", EXT_MODE_ABS);
    _t[0x10] = scr_ext_op(0x10, "BPL", EXT_MODE_REL);
    _t[0x11] = scr_ext_op(0x11, "ORA", EXT_MODE_IZY);
    _t[0x12] = scr_ext_op(0x12, "JAM", EXT_MODE_IMP);
    _t[0x13] = scr_ext_op(0x13, "SLO", EXT_MODE_IZY);
    _t[0x14] = scr_ext_op(0x14, "NOP", EXT_MODE_ZPX);
    _t[0x15] = scr_ext_op(0x15, "ORA", EXT_MODE_ZPX);
    _t[0x16] = scr_ext_op(0x16, "ASL", EXT_MODE_ZPX);
    _t[0x17] = scr_ext_op(0x17, "SLO", EXT_MODE_ZPX);
    _t[0x18] = scr_ext_op(0x18, "CLC", EXT_MODE_IMP);
    _t[0x19] = scr_ext_op(0x19, "ORA", EXT_MODE_ABY);
    _t[0x1A] = scr_ext_op(0x1A, "NOP", EXT_MODE_IMP);
    _t[0x1B] = scr_ext_op(0x1B, "SLO", EXT_MODE_ABY);
    _t[0x1C] = scr_ext_op(0x1C, "NOP", EXT_MODE_ABX);
    _t[0x1D] = scr_ext_op(0x1D, "ORA", EXT_MODE_ABX);
    _t[0x1E] = scr_ext_op(0x1E, "ASL", EXT_MODE_ABX);
    _t[0x1F] = scr_ext_op(0x1F, "SLO", EXT_MODE_ABX);
    _t[0x20] = scr_ext_op(0x20, "JSR", EXT_MODE_ABS);
    _t[0x21] = scr_ext_op(0x21, "AND", EXT_MODE_IZX);
    _t[0x22] = scr_ext_op(0x22, "JAM", EXT_MODE_IMP);
    _t[0x23] = scr_ext_op(0x23, "RLA", EXT_MODE_IZX);
    _t[0x24] = scr_ext_op(0x24, "BIT", EXT_MODE_ZP);
    _t[0x25] = scr_ext_op(0x25, "AND", EXT_MODE_ZP);
    _t[0x26] = scr_ext_op(0x26, "ROL", EXT_MODE_ZP);
    _t[0x27] = scr_ext_op(0x27, "RLA", EXT_MODE_ZP);
    _t[0x28] = scr_ext_op(0x28, "PLP", EXT_MODE_IMP);
    _t[0x29] = scr_ext_op(0x29, "AND", EXT_MODE_IMM);
    _t[0x2A] = scr_ext_op(0x2A, "ROL", EXT_MODE_ACC);
    _t[0x2B] = scr_ext_op(0x2B, "ANC", EXT_MODE_IMM);
    _t[0x2C] = scr_ext_op(0x2C, "BIT", EXT_MODE_ABS);
    _t[0x2D] = scr_ext_op(0x2D, "AND", EXT_MODE_ABS);
    _t[0x2E] = scr_ext_op(0x2E, "ROL", EXT_MODE_ABS);
    _t[0x2F] = scr_ext_op(0x2F, "RLA", EXT_MODE_ABS);
    _t[0x30] = scr_ext_op(0x30, "BMI", EXT_MODE_REL);
    _t[0x31] = scr_ext_op(0x31, "AND", EXT_MODE_IZY);
    _t[0x32] = scr_ext_op(0x32, "JAM", EXT_MODE_IMP);
    _t[0x33] = scr_ext_op(0x33, "RLA", EXT_MODE_IZY);
    _t[0x34] = scr_ext_op(0x34, "NOP", EXT_MODE_ZPX);
    _t[0x35] = scr_ext_op(0x35, "AND", EXT_MODE_ZPX);
    _t[0x36] = scr_ext_op(0x36, "ROL", EXT_MODE_ZPX);
    _t[0x37] = scr_ext_op(0x37, "RLA", EXT_MODE_ZPX);
    _t[0x38] = scr_ext_op(0x38, "SEC", EXT_MODE_IMP);
    _t[0x39] = scr_ext_op(0x39, "AND", EXT_MODE_ABY);
    _t[0x3A] = scr_ext_op(0x3A, "NOP", EXT_MODE_IMP);
    _t[0x3B] = scr_ext_op(0x3B, "RLA", EXT_MODE_ABY);
    _t[0x3C] = scr_ext_op(0x3C, "NOP", EXT_MODE_ABX);
    _t[0x3D] = scr_ext_op(0x3D, "AND", EXT_MODE_ABX);
    _t[0x3E] = scr_ext_op(0x3E, "ROL", EXT_MODE_ABX);
    _t[0x3F] = scr_ext_op(0x3F, "RLA", EXT_MODE_ABX);
    _t[0x40] = scr_ext_op(0x40, "RTI", EXT_MODE_IMP);
    _t[0x41] = scr_ext_op(0x41, "EOR", EXT_MODE_IZX);
    _t[0x42] = scr_ext_op(0x42, "JAM", EXT_MODE_IMP);
    _t[0x43] = scr_ext_op(0x43, "SRE", EXT_MODE_IZX);
    _t[0x44] = scr_ext_op(0x44, "NOP", EXT_MODE_ZP);
    _t[0x45] = scr_ext_op(0x45, "EOR", EXT_MODE_ZP);
    _t[0x46] = scr_ext_op(0x46, "LSR", EXT_MODE_ZP);
    _t[0x47] = scr_ext_op(0x47, "SRE", EXT_MODE_ZP);
    _t[0x48] = scr_ext_op(0x48, "PHA", EXT_MODE_IMP);
    _t[0x49] = scr_ext_op(0x49, "EOR", EXT_MODE_IMM);
    _t[0x4A] = scr_ext_op(0x4A, "LSR", EXT_MODE_ACC);
    _t[0x4B] = scr_ext_op(0x4B, "ALR", EXT_MODE_IMM);
    _t[0x4C] = scr_ext_op(0x4C, "JMP", EXT_MODE_ABS);
    _t[0x4D] = scr_ext_op(0x4D, "EOR", EXT_MODE_ABS);
    _t[0x4E] = scr_ext_op(0x4E, "LSR", EXT_MODE_ABS);
    _t[0x4F] = scr_ext_op(0x4F, "SRE", EXT_MODE_ABS);
    _t[0x50] = scr_ext_op(0x50, "BVC", EXT_MODE_REL);
    _t[0x51] = scr_ext_op(0x51, "EOR", EXT_MODE_IZY);
    _t[0x52] = scr_ext_op(0x52, "JAM", EXT_MODE_IMP);
    _t[0x53] = scr_ext_op(0x53, "SRE", EXT_MODE_IZY);
    _t[0x54] = scr_ext_op(0x54, "NOP", EXT_MODE_ZPX);
    _t[0x55] = scr_ext_op(0x55, "EOR", EXT_MODE_ZPX);
    _t[0x56] = scr_ext_op(0x56, "LSR", EXT_MODE_ZPX);
    _t[0x57] = scr_ext_op(0x57, "SRE", EXT_MODE_ZPX);
    _t[0x58] = scr_ext_op(0x58, "CLI", EXT_MODE_IMP);
    _t[0x59] = scr_ext_op(0x59, "EOR", EXT_MODE_ABY);
    _t[0x5A] = scr_ext_op(0x5A, "NOP", EXT_MODE_IMP);
    _t[0x5B] = scr_ext_op(0x5B, "SRE", EXT_MODE_ABY);
    _t[0x5C] = scr_ext_op(0x5C, "NOP", EXT_MODE_ABX);
    _t[0x5D] = scr_ext_op(0x5D, "EOR", EXT_MODE_ABX);
    _t[0x5E] = scr_ext_op(0x5E, "LSR", EXT_MODE_ABX);
    _t[0x5F] = scr_ext_op(0x5F, "SRE", EXT_MODE_ABX);
    _t[0x60] = scr_ext_op(0x60, "RTS", EXT_MODE_IMP);
    _t[0x61] = scr_ext_op(0x61, "ADC", EXT_MODE_IZX);
    _t[0x62] = scr_ext_op(0x62, "JAM", EXT_MODE_IMP);
    _t[0x63] = scr_ext_op(0x63, "RRA", EXT_MODE_IZX);
    _t[0x64] = scr_ext_op(0x64, "NOP", EXT_MODE_ZP);
    _t[0x65] = scr_ext_op(0x65, "ADC", EXT_MODE_ZP);
    _t[0x66] = scr_ext_op(0x66, "ROR", EXT_MODE_ZP);
    _t[0x67] = scr_ext_op(0x67, "RRA", EXT_MODE_ZP);
    _t[0x68] = scr_ext_op(0x68, "PLA", EXT_MODE_IMP);
    _t[0x69] = scr_ext_op(0x69, "ADC", EXT_MODE_IMM);
    _t[0x6A] = scr_ext_op(0x6A, "ROR", EXT_MODE_ACC);
    _t[0x6B] = scr_ext_op(0x6B, "ARR", EXT_MODE_IMM);
    _t[0x6C] = scr_ext_op(0x6C, "JMP", EXT_MODE_IND);
    _t[0x6D] = scr_ext_op(0x6D, "ADC", EXT_MODE_ABS);
    _t[0x6E] = scr_ext_op(0x6E, "ROR", EXT_MODE_ABS);
    _t[0x6F] = scr_ext_op(0x6F, "RRA", EXT_MODE_ABS);
    _t[0x70] = scr_ext_op(0x70, "BVS", EXT_MODE_REL);
    _t[0x71] = scr_ext_op(0x71, "ADC", EXT_MODE_IZY);
    _t[0x72] = scr_ext_op(0x72, "JAM", EXT_MODE_IMP);
    _t[0x73] = scr_ext_op(0x73, "RRA", EXT_MODE_IZY);
    _t[0x74] = scr_ext_op(0x74, "NOP", EXT_MODE_ZPX);
    _t[0x75] = scr_ext_op(0x75, "ADC", EXT_MODE_ZPX);
    _t[0x76] = scr_ext_op(0x76, "ROR", EXT_MODE_ZPX);
    _t[0x77] = scr_ext_op(0x77, "RRA", EXT_MODE_ZPX);
    _t[0x78] = scr_ext_op(0x78, "SEI", EXT_MODE_IMP);
    _t[0x79] = scr_ext_op(0x79, "ADC", EXT_MODE_ABY);
    _t[0x7A] = scr_ext_op(0x7A, "NOP", EXT_MODE_IMP);
    _t[0x7B] = scr_ext_op(0x7B, "RRA", EXT_MODE_ABY);
    _t[0x7C] = scr_ext_op(0x7C, "NOP", EXT_MODE_ABX);
    _t[0x7D] = scr_ext_op(0x7D, "ADC", EXT_MODE_ABX);
    _t[0x7E] = scr_ext_op(0x7E, "ROR", EXT_MODE_ABX);
    _t[0x7F] = scr_ext_op(0x7F, "RRA", EXT_MODE_ABX);
    _t[0x80] = scr_ext_op(0x80, "NOP", EXT_MODE_IMM);
    _t[0x81] = scr_ext_op(0x81, "STA", EXT_MODE_IZX);
    _t[0x82] = scr_ext_op(0x82, "NOP", EXT_MODE_IMM);
    _t[0x83] = scr_ext_op(0x83, "SAX", EXT_MODE_IZX);
    _t[0x84] = scr_ext_op(0x84, "STY", EXT_MODE_ZP);
    _t[0x85] = scr_ext_op(0x85, "STA", EXT_MODE_ZP);
    _t[0x86] = scr_ext_op(0x86, "STX", EXT_MODE_ZP);
    _t[0x87] = scr_ext_op(0x87, "SAX", EXT_MODE_ZP);
    _t[0x88] = scr_ext_op(0x88, "DEY", EXT_MODE_IMP);
    _t[0x89] = scr_ext_op(0x89, "NOP", EXT_MODE_IMM);
    _t[0x8A] = scr_ext_op(0x8A, "TXA", EXT_MODE_IMP);
    _t[0x8B] = scr_ext_op(0x8B, "ANE", EXT_MODE_IMM);
    _t[0x8C] = scr_ext_op(0x8C, "STY", EXT_MODE_ABS);
    _t[0x8D] = scr_ext_op(0x8D, "STA", EXT_MODE_ABS);
    _t[0x8E] = scr_ext_op(0x8E, "STX", EXT_MODE_ABS);
    _t[0x8F] = scr_ext_op(0x8F, "SAX", EXT_MODE_ABS);
    _t[0x90] = scr_ext_op(0x90, "BCC", EXT_MODE_REL);
    _t[0x91] = scr_ext_op(0x91, "STA", EXT_MODE_IZY);
    _t[0x92] = scr_ext_op(0x92, "JAM", EXT_MODE_IMP);
    _t[0x93] = scr_ext_op(0x93, "SHA", EXT_MODE_IZY);
    _t[0x94] = scr_ext_op(0x94, "STY", EXT_MODE_ZPX);
    _t[0x95] = scr_ext_op(0x95, "STA", EXT_MODE_ZPX);
    _t[0x96] = scr_ext_op(0x96, "STX", EXT_MODE_ZPY);
    _t[0x97] = scr_ext_op(0x97, "SAX", EXT_MODE_ZPY);
    _t[0x98] = scr_ext_op(0x98, "TYA", EXT_MODE_IMP);
    _t[0x99] = scr_ext_op(0x99, "STA", EXT_MODE_ABY);
    _t[0x9A] = scr_ext_op(0x9A, "TXS", EXT_MODE_IMP);
    _t[0x9B] = scr_ext_op(0x9B, "TAS", EXT_MODE_ABY);
    _t[0x9C] = scr_ext_op(0x9C, "SHY", EXT_MODE_ABX);
    _t[0x9D] = scr_ext_op(0x9D, "STA", EXT_MODE_ABX);
    _t[0x9E] = scr_ext_op(0x9E, "SHX", EXT_MODE_ABY);
    _t[0x9F] = scr_ext_op(0x9F, "SHA", EXT_MODE_ABY);
    _t[0xA0] = scr_ext_op(0xA0, "LDY", EXT_MODE_IMM);
    _t[0xA1] = scr_ext_op(0xA1, "LDA", EXT_MODE_IZX);
    _t[0xA2] = scr_ext_op(0xA2, "LDX", EXT_MODE_IMM);
    _t[0xA3] = scr_ext_op(0xA3, "LAX", EXT_MODE_IZX);
    _t[0xA4] = scr_ext_op(0xA4, "LDY", EXT_MODE_ZP);
    _t[0xA5] = scr_ext_op(0xA5, "LDA", EXT_MODE_ZP);
    _t[0xA6] = scr_ext_op(0xA6, "LDX", EXT_MODE_ZP);
    _t[0xA7] = scr_ext_op(0xA7, "LAX", EXT_MODE_ZP);
    _t[0xA8] = scr_ext_op(0xA8, "TAY", EXT_MODE_IMP);
    _t[0xA9] = scr_ext_op(0xA9, "LDA", EXT_MODE_IMM);
    _t[0xAA] = scr_ext_op(0xAA, "TAX", EXT_MODE_IMP);
    _t[0xAB] = scr_ext_op(0xAB, "LXA", EXT_MODE_IMM);
    _t[0xAC] = scr_ext_op(0xAC, "LDY", EXT_MODE_ABS);
    _t[0xAD] = scr_ext_op(0xAD, "LDA", EXT_MODE_ABS);
    _t[0xAE] = scr_ext_op(0xAE, "LDX", EXT_MODE_ABS);
    _t[0xAF] = scr_ext_op(0xAF, "LAX", EXT_MODE_ABS);
    _t[0xB0] = scr_ext_op(0xB0, "BCS", EXT_MODE_REL);
    _t[0xB1] = scr_ext_op(0xB1, "LDA", EXT_MODE_IZY);
    _t[0xB2] = scr_ext_op(0xB2, "JAM", EXT_MODE_IMP);
    _t[0xB3] = scr_ext_op(0xB3, "LAX", EXT_MODE_IZY);
    _t[0xB4] = scr_ext_op(0xB4, "LDY", EXT_MODE_ZPX);
    _t[0xB5] = scr_ext_op(0xB5, "LDA", EXT_MODE_ZPX);
    _t[0xB6] = scr_ext_op(0xB6, "LDX", EXT_MODE_ZPY);
    _t[0xB7] = scr_ext_op(0xB7, "LAX", EXT_MODE_ZPY);
    _t[0xB8] = scr_ext_op(0xB8, "CLV", EXT_MODE_IMP);
    _t[0xB9] = scr_ext_op(0xB9, "LDA", EXT_MODE_ABY);
    _t[0xBA] = scr_ext_op(0xBA, "TSX", EXT_MODE_IMP);
    _t[0xBB] = scr_ext_op(0xBB, "LAS", EXT_MODE_ABY);
    _t[0xBC] = scr_ext_op(0xBC, "LDY", EXT_MODE_ABX);
    _t[0xBD] = scr_ext_op(0xBD, "LDA", EXT_MODE_ABX);
    _t[0xBE] = scr_ext_op(0xBE, "LDX", EXT_MODE_ABY);
    _t[0xBF] = scr_ext_op(0xBF, "LAX", EXT_MODE_ABY);
    _t[0xC0] = scr_ext_op(0xC0, "CPY", EXT_MODE_IMM);
    _t[0xC1] = scr_ext_op(0xC1, "CMP", EXT_MODE_IZX);
    _t[0xC2] = scr_ext_op(0xC2, "NOP", EXT_MODE_IMM);
    _t[0xC3] = scr_ext_op(0xC3, "DCP", EXT_MODE_IZX);
    _t[0xC4] = scr_ext_op(0xC4, "CPY", EXT_MODE_ZP);
    _t[0xC5] = scr_ext_op(0xC5, "CMP", EXT_MODE_ZP);
    _t[0xC6] = scr_ext_op(0xC6, "DEC", EXT_MODE_ZP);
    _t[0xC7] = scr_ext_op(0xC7, "DCP", EXT_MODE_ZP);
    _t[0xC8] = scr_ext_op(0xC8, "INY", EXT_MODE_IMP);
    _t[0xC9] = scr_ext_op(0xC9, "CMP", EXT_MODE_IMM);
    _t[0xCA] = scr_ext_op(0xCA, "DEX", EXT_MODE_IMP);
    _t[0xCB] = scr_ext_op(0xCB, "SBX", EXT_MODE_IMM);
    _t[0xCC] = scr_ext_op(0xCC, "CPY", EXT_MODE_ABS);
    _t[0xCD] = scr_ext_op(0xCD, "CMP", EXT_MODE_ABS);
    _t[0xCE] = scr_ext_op(0xCE, "DEC", EXT_MODE_ABS);
    _t[0xCF] = scr_ext_op(0xCF, "DCP", EXT_MODE_ABS);
    _t[0xD0] = scr_ext_op(0xD0, "BNE", EXT_MODE_REL);
    _t[0xD1] = scr_ext_op(0xD1, "CMP", EXT_MODE_IZY);
    _t[0xD2] = scr_ext_op(0xD2, "JAM", EXT_MODE_IMP);
    _t[0xD3] = scr_ext_op(0xD3, "DCP", EXT_MODE_IZY);
    _t[0xD4] = scr_ext_op(0xD4, "NOP", EXT_MODE_ZPX);
    _t[0xD5] = scr_ext_op(0xD5, "CMP", EXT_MODE_ZPX);
    _t[0xD6] = scr_ext_op(0xD6, "DEC", EXT_MODE_ZPX);
    _t[0xD7] = scr_ext_op(0xD7, "DCP", EXT_MODE_ZPX);
    _t[0xD8] = scr_ext_op(0xD8, "CLD", EXT_MODE_IMP);
    _t[0xD9] = scr_ext_op(0xD9, "CMP", EXT_MODE_ABY);
    _t[0xDA] = scr_ext_op(0xDA, "NOP", EXT_MODE_IMP);
    _t[0xDB] = scr_ext_op(0xDB, "DCP", EXT_MODE_ABY);
    _t[0xDC] = scr_ext_op(0xDC, "NOP", EXT_MODE_ABX);
    _t[0xDD] = scr_ext_op(0xDD, "CMP", EXT_MODE_ABX);
    _t[0xDE] = scr_ext_op(0xDE, "DEC", EXT_MODE_ABX);
    _t[0xDF] = scr_ext_op(0xDF, "DCP", EXT_MODE_ABX);
    _t[0xE0] = scr_ext_op(0xE0, "CPX", EXT_MODE_IMM);
    _t[0xE1] = scr_ext_op(0xE1, "SBC", EXT_MODE_IZX);
    _t[0xE2] = scr_ext_op(0xE2, "NOP", EXT_MODE_IMM);
    _t[0xE3] = scr_ext_op(0xE3, "ISC", EXT_MODE_IZX);
    _t[0xE4] = scr_ext_op(0xE4, "CPX", EXT_MODE_ZP);
    _t[0xE5] = scr_ext_op(0xE5, "SBC", EXT_MODE_ZP);
    _t[0xE6] = scr_ext_op(0xE6, "INC", EXT_MODE_ZP);
    _t[0xE7] = scr_ext_op(0xE7, "ISC", EXT_MODE_ZP);
    _t[0xE8] = scr_ext_op(0xE8, "INX", EXT_MODE_IMP);
    _t[0xE9] = scr_ext_op(0xE9, "SBC", EXT_MODE_IMM);
    _t[0xEA] = scr_ext_op(0xEA, "NOP", EXT_MODE_IMP);
    _t[0xEB] = scr_ext_op(0xEB, "SBC", EXT_MODE_IMM);
    _t[0xEC] = scr_ext_op(0xEC, "CPX", EXT_MODE_ABS);
    _t[0xED] = scr_ext_op(0xED, "SBC", EXT_MODE_ABS);
    _t[0xEE] = scr_ext_op(0xEE, "INC", EXT_MODE_ABS);
    _t[0xEF] = scr_ext_op(0xEF, "ISC", EXT_MODE_ABS);
    _t[0xF0] = scr_ext_op(0xF0, "BEQ", EXT_MODE_REL);
    _t[0xF1] = scr_ext_op(0xF1, "SBC", EXT_MODE_IZY);
    _t[0xF2] = scr_ext_op(0xF2, "JAM", EXT_MODE_IMP);
    _t[0xF3] = scr_ext_op(0xF3, "ISC", EXT_MODE_IZY);
    _t[0xF4] = scr_ext_op(0xF4, "NOP", EXT_MODE_ZPX);
    _t[0xF5] = scr_ext_op(0xF5, "SBC", EXT_MODE_ZPX);
    _t[0xF6] = scr_ext_op(0xF6, "INC", EXT_MODE_ZPX);
    _t[0xF7] = scr_ext_op(0xF7, "ISC", EXT_MODE_ZPX);
    _t[0xF8] = scr_ext_op(0xF8, "SED", EXT_MODE_IMP);
    _t[0xF9] = scr_ext_op(0xF9, "SBC", EXT_MODE_ABY);
    _t[0xFA] = scr_ext_op(0xFA, "NOP", EXT_MODE_IMP);
    _t[0xFB] = scr_ext_op(0xFB, "ISC", EXT_MODE_ABY);
    _t[0xFC] = scr_ext_op(0xFC, "NOP", EXT_MODE_ABX);
    _t[0xFD] = scr_ext_op(0xFD, "SBC", EXT_MODE_ABX);
    _t[0xFE] = scr_ext_op(0xFE, "INC", EXT_MODE_ABX);
    _t[0xFF] = scr_ext_op(0xFF, "ISC", EXT_MODE_ABX);

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
        if (_opcode != 0xEA) {
            _illegal = true;
        }
    }
    if (_opcode == 0xEB) {
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
