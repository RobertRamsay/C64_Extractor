// ============================================================================
// Decrunch runner: a bare 6502 (RAM only, no VIC/SID/CIA) that runs a file's
// own self-extractor until it jumps into the freshly unpacked program.
// Works for Exomizer, ByteBoozer, PuCrunch etc. without knowing their formats.
// Core verified against Klaus Dormann's 6502 functional test (incl. decimal mode).
// ============================================================================

#macro EXT_CPU_MAX_STEPS   80000000
#macro EXT_CPU_MIN_WRITES  1024
#macro EXT_CPU_MAX_STAGES  4

#macro CPU_ADC 0
#macro CPU_ALR 1
#macro CPU_ANC 2
#macro CPU_AND 3
#macro CPU_ANE 4
#macro CPU_ARR 5
#macro CPU_ASL 6
#macro CPU_BCC 7
#macro CPU_BCS 8
#macro CPU_BEQ 9
#macro CPU_BIT 10
#macro CPU_BMI 11
#macro CPU_BNE 12
#macro CPU_BPL 13
#macro CPU_BRK 14
#macro CPU_BVC 15
#macro CPU_BVS 16
#macro CPU_CLC 17
#macro CPU_CLD 18
#macro CPU_CLI 19
#macro CPU_CLV 20
#macro CPU_CMP 21
#macro CPU_CPX 22
#macro CPU_CPY 23
#macro CPU_DCP 24
#macro CPU_DEC 25
#macro CPU_DEX 26
#macro CPU_DEY 27
#macro CPU_EOR 28
#macro CPU_INC 29
#macro CPU_INX 30
#macro CPU_INY 31
#macro CPU_ISC 32
#macro CPU_JAM 33
#macro CPU_JMP 34
#macro CPU_JSR 35
#macro CPU_LAS 36
#macro CPU_LAX 37
#macro CPU_LDA 38
#macro CPU_LDX 39
#macro CPU_LDY 40
#macro CPU_LSR 41
#macro CPU_LXA 42
#macro CPU_NOP 43
#macro CPU_ORA 44
#macro CPU_PHA 45
#macro CPU_PHP 46
#macro CPU_PLA 47
#macro CPU_PLP 48
#macro CPU_RLA 49
#macro CPU_ROL 50
#macro CPU_ROR 51
#macro CPU_RRA 52
#macro CPU_RTI 53
#macro CPU_RTS 54
#macro CPU_SAX 55
#macro CPU_SBC 56
#macro CPU_SBX 57
#macro CPU_SEC 58
#macro CPU_SED 59
#macro CPU_SEI 60
#macro CPU_SHA 61
#macro CPU_SHX 62
#macro CPU_SHY 63
#macro CPU_SLO 64
#macro CPU_SRE 65
#macro CPU_STA 66
#macro CPU_STX 67
#macro CPU_STY 68
#macro CPU_TAS 69
#macro CPU_TAX 70
#macro CPU_TAY 71
#macro CPU_TSX 72
#macro CPU_TXA 73
#macro CPU_TXS 74
#macro CPU_TYA 75

/// @desc scr_ext_cpu_tables()
/// Per-opcode operation id and "reads an operand from memory" flag.
function scr_ext_cpu_tables() {
    var _id = array_create(256, 0);
    var _rd = array_create(256, 0);
    _id[0x00] = CPU_BRK; _rd[0x00] = 0;
    _id[0x01] = CPU_ORA; _rd[0x01] = 1;
    _id[0x02] = CPU_JAM; _rd[0x02] = 0;
    _id[0x03] = CPU_SLO; _rd[0x03] = 1;
    _id[0x04] = CPU_NOP; _rd[0x04] = 1;
    _id[0x05] = CPU_ORA; _rd[0x05] = 1;
    _id[0x06] = CPU_ASL; _rd[0x06] = 1;
    _id[0x07] = CPU_SLO; _rd[0x07] = 1;
    _id[0x08] = CPU_PHP; _rd[0x08] = 0;
    _id[0x09] = CPU_ORA; _rd[0x09] = 1;
    _id[0x0A] = CPU_ASL; _rd[0x0A] = 0;
    _id[0x0B] = CPU_ANC; _rd[0x0B] = 1;
    _id[0x0C] = CPU_NOP; _rd[0x0C] = 1;
    _id[0x0D] = CPU_ORA; _rd[0x0D] = 1;
    _id[0x0E] = CPU_ASL; _rd[0x0E] = 1;
    _id[0x0F] = CPU_SLO; _rd[0x0F] = 1;
    _id[0x10] = CPU_BPL; _rd[0x10] = 0;
    _id[0x11] = CPU_ORA; _rd[0x11] = 1;
    _id[0x12] = CPU_JAM; _rd[0x12] = 0;
    _id[0x13] = CPU_SLO; _rd[0x13] = 1;
    _id[0x14] = CPU_NOP; _rd[0x14] = 1;
    _id[0x15] = CPU_ORA; _rd[0x15] = 1;
    _id[0x16] = CPU_ASL; _rd[0x16] = 1;
    _id[0x17] = CPU_SLO; _rd[0x17] = 1;
    _id[0x18] = CPU_CLC; _rd[0x18] = 0;
    _id[0x19] = CPU_ORA; _rd[0x19] = 1;
    _id[0x1A] = CPU_NOP; _rd[0x1A] = 0;
    _id[0x1B] = CPU_SLO; _rd[0x1B] = 1;
    _id[0x1C] = CPU_NOP; _rd[0x1C] = 1;
    _id[0x1D] = CPU_ORA; _rd[0x1D] = 1;
    _id[0x1E] = CPU_ASL; _rd[0x1E] = 1;
    _id[0x1F] = CPU_SLO; _rd[0x1F] = 1;
    _id[0x20] = CPU_JSR; _rd[0x20] = 0;
    _id[0x21] = CPU_AND; _rd[0x21] = 1;
    _id[0x22] = CPU_JAM; _rd[0x22] = 0;
    _id[0x23] = CPU_RLA; _rd[0x23] = 1;
    _id[0x24] = CPU_BIT; _rd[0x24] = 1;
    _id[0x25] = CPU_AND; _rd[0x25] = 1;
    _id[0x26] = CPU_ROL; _rd[0x26] = 1;
    _id[0x27] = CPU_RLA; _rd[0x27] = 1;
    _id[0x28] = CPU_PLP; _rd[0x28] = 0;
    _id[0x29] = CPU_AND; _rd[0x29] = 1;
    _id[0x2A] = CPU_ROL; _rd[0x2A] = 0;
    _id[0x2B] = CPU_ANC; _rd[0x2B] = 1;
    _id[0x2C] = CPU_BIT; _rd[0x2C] = 1;
    _id[0x2D] = CPU_AND; _rd[0x2D] = 1;
    _id[0x2E] = CPU_ROL; _rd[0x2E] = 1;
    _id[0x2F] = CPU_RLA; _rd[0x2F] = 1;
    _id[0x30] = CPU_BMI; _rd[0x30] = 0;
    _id[0x31] = CPU_AND; _rd[0x31] = 1;
    _id[0x32] = CPU_JAM; _rd[0x32] = 0;
    _id[0x33] = CPU_RLA; _rd[0x33] = 1;
    _id[0x34] = CPU_NOP; _rd[0x34] = 1;
    _id[0x35] = CPU_AND; _rd[0x35] = 1;
    _id[0x36] = CPU_ROL; _rd[0x36] = 1;
    _id[0x37] = CPU_RLA; _rd[0x37] = 1;
    _id[0x38] = CPU_SEC; _rd[0x38] = 0;
    _id[0x39] = CPU_AND; _rd[0x39] = 1;
    _id[0x3A] = CPU_NOP; _rd[0x3A] = 0;
    _id[0x3B] = CPU_RLA; _rd[0x3B] = 1;
    _id[0x3C] = CPU_NOP; _rd[0x3C] = 1;
    _id[0x3D] = CPU_AND; _rd[0x3D] = 1;
    _id[0x3E] = CPU_ROL; _rd[0x3E] = 1;
    _id[0x3F] = CPU_RLA; _rd[0x3F] = 1;
    _id[0x40] = CPU_RTI; _rd[0x40] = 0;
    _id[0x41] = CPU_EOR; _rd[0x41] = 1;
    _id[0x42] = CPU_JAM; _rd[0x42] = 0;
    _id[0x43] = CPU_SRE; _rd[0x43] = 1;
    _id[0x44] = CPU_NOP; _rd[0x44] = 1;
    _id[0x45] = CPU_EOR; _rd[0x45] = 1;
    _id[0x46] = CPU_LSR; _rd[0x46] = 1;
    _id[0x47] = CPU_SRE; _rd[0x47] = 1;
    _id[0x48] = CPU_PHA; _rd[0x48] = 0;
    _id[0x49] = CPU_EOR; _rd[0x49] = 1;
    _id[0x4A] = CPU_LSR; _rd[0x4A] = 0;
    _id[0x4B] = CPU_ALR; _rd[0x4B] = 1;
    _id[0x4C] = CPU_JMP; _rd[0x4C] = 0;
    _id[0x4D] = CPU_EOR; _rd[0x4D] = 1;
    _id[0x4E] = CPU_LSR; _rd[0x4E] = 1;
    _id[0x4F] = CPU_SRE; _rd[0x4F] = 1;
    _id[0x50] = CPU_BVC; _rd[0x50] = 0;
    _id[0x51] = CPU_EOR; _rd[0x51] = 1;
    _id[0x52] = CPU_JAM; _rd[0x52] = 0;
    _id[0x53] = CPU_SRE; _rd[0x53] = 1;
    _id[0x54] = CPU_NOP; _rd[0x54] = 1;
    _id[0x55] = CPU_EOR; _rd[0x55] = 1;
    _id[0x56] = CPU_LSR; _rd[0x56] = 1;
    _id[0x57] = CPU_SRE; _rd[0x57] = 1;
    _id[0x58] = CPU_CLI; _rd[0x58] = 0;
    _id[0x59] = CPU_EOR; _rd[0x59] = 1;
    _id[0x5A] = CPU_NOP; _rd[0x5A] = 0;
    _id[0x5B] = CPU_SRE; _rd[0x5B] = 1;
    _id[0x5C] = CPU_NOP; _rd[0x5C] = 1;
    _id[0x5D] = CPU_EOR; _rd[0x5D] = 1;
    _id[0x5E] = CPU_LSR; _rd[0x5E] = 1;
    _id[0x5F] = CPU_SRE; _rd[0x5F] = 1;
    _id[0x60] = CPU_RTS; _rd[0x60] = 0;
    _id[0x61] = CPU_ADC; _rd[0x61] = 1;
    _id[0x62] = CPU_JAM; _rd[0x62] = 0;
    _id[0x63] = CPU_RRA; _rd[0x63] = 1;
    _id[0x64] = CPU_NOP; _rd[0x64] = 1;
    _id[0x65] = CPU_ADC; _rd[0x65] = 1;
    _id[0x66] = CPU_ROR; _rd[0x66] = 1;
    _id[0x67] = CPU_RRA; _rd[0x67] = 1;
    _id[0x68] = CPU_PLA; _rd[0x68] = 0;
    _id[0x69] = CPU_ADC; _rd[0x69] = 1;
    _id[0x6A] = CPU_ROR; _rd[0x6A] = 0;
    _id[0x6B] = CPU_ARR; _rd[0x6B] = 1;
    _id[0x6C] = CPU_JMP; _rd[0x6C] = 0;
    _id[0x6D] = CPU_ADC; _rd[0x6D] = 1;
    _id[0x6E] = CPU_ROR; _rd[0x6E] = 1;
    _id[0x6F] = CPU_RRA; _rd[0x6F] = 1;
    _id[0x70] = CPU_BVS; _rd[0x70] = 0;
    _id[0x71] = CPU_ADC; _rd[0x71] = 1;
    _id[0x72] = CPU_JAM; _rd[0x72] = 0;
    _id[0x73] = CPU_RRA; _rd[0x73] = 1;
    _id[0x74] = CPU_NOP; _rd[0x74] = 1;
    _id[0x75] = CPU_ADC; _rd[0x75] = 1;
    _id[0x76] = CPU_ROR; _rd[0x76] = 1;
    _id[0x77] = CPU_RRA; _rd[0x77] = 1;
    _id[0x78] = CPU_SEI; _rd[0x78] = 0;
    _id[0x79] = CPU_ADC; _rd[0x79] = 1;
    _id[0x7A] = CPU_NOP; _rd[0x7A] = 0;
    _id[0x7B] = CPU_RRA; _rd[0x7B] = 1;
    _id[0x7C] = CPU_NOP; _rd[0x7C] = 1;
    _id[0x7D] = CPU_ADC; _rd[0x7D] = 1;
    _id[0x7E] = CPU_ROR; _rd[0x7E] = 1;
    _id[0x7F] = CPU_RRA; _rd[0x7F] = 1;
    _id[0x80] = CPU_NOP; _rd[0x80] = 1;
    _id[0x81] = CPU_STA; _rd[0x81] = 0;
    _id[0x82] = CPU_NOP; _rd[0x82] = 1;
    _id[0x83] = CPU_SAX; _rd[0x83] = 0;
    _id[0x84] = CPU_STY; _rd[0x84] = 0;
    _id[0x85] = CPU_STA; _rd[0x85] = 0;
    _id[0x86] = CPU_STX; _rd[0x86] = 0;
    _id[0x87] = CPU_SAX; _rd[0x87] = 0;
    _id[0x88] = CPU_DEY; _rd[0x88] = 0;
    _id[0x89] = CPU_NOP; _rd[0x89] = 1;
    _id[0x8A] = CPU_TXA; _rd[0x8A] = 0;
    _id[0x8B] = CPU_ANE; _rd[0x8B] = 1;
    _id[0x8C] = CPU_STY; _rd[0x8C] = 0;
    _id[0x8D] = CPU_STA; _rd[0x8D] = 0;
    _id[0x8E] = CPU_STX; _rd[0x8E] = 0;
    _id[0x8F] = CPU_SAX; _rd[0x8F] = 0;
    _id[0x90] = CPU_BCC; _rd[0x90] = 0;
    _id[0x91] = CPU_STA; _rd[0x91] = 0;
    _id[0x92] = CPU_JAM; _rd[0x92] = 0;
    _id[0x93] = CPU_SHA; _rd[0x93] = 0;
    _id[0x94] = CPU_STY; _rd[0x94] = 0;
    _id[0x95] = CPU_STA; _rd[0x95] = 0;
    _id[0x96] = CPU_STX; _rd[0x96] = 0;
    _id[0x97] = CPU_SAX; _rd[0x97] = 0;
    _id[0x98] = CPU_TYA; _rd[0x98] = 0;
    _id[0x99] = CPU_STA; _rd[0x99] = 0;
    _id[0x9A] = CPU_TXS; _rd[0x9A] = 0;
    _id[0x9B] = CPU_TAS; _rd[0x9B] = 0;
    _id[0x9C] = CPU_SHY; _rd[0x9C] = 0;
    _id[0x9D] = CPU_STA; _rd[0x9D] = 0;
    _id[0x9E] = CPU_SHX; _rd[0x9E] = 0;
    _id[0x9F] = CPU_SHA; _rd[0x9F] = 0;
    _id[0xA0] = CPU_LDY; _rd[0xA0] = 1;
    _id[0xA1] = CPU_LDA; _rd[0xA1] = 1;
    _id[0xA2] = CPU_LDX; _rd[0xA2] = 1;
    _id[0xA3] = CPU_LAX; _rd[0xA3] = 1;
    _id[0xA4] = CPU_LDY; _rd[0xA4] = 1;
    _id[0xA5] = CPU_LDA; _rd[0xA5] = 1;
    _id[0xA6] = CPU_LDX; _rd[0xA6] = 1;
    _id[0xA7] = CPU_LAX; _rd[0xA7] = 1;
    _id[0xA8] = CPU_TAY; _rd[0xA8] = 0;
    _id[0xA9] = CPU_LDA; _rd[0xA9] = 1;
    _id[0xAA] = CPU_TAX; _rd[0xAA] = 0;
    _id[0xAB] = CPU_LXA; _rd[0xAB] = 1;
    _id[0xAC] = CPU_LDY; _rd[0xAC] = 1;
    _id[0xAD] = CPU_LDA; _rd[0xAD] = 1;
    _id[0xAE] = CPU_LDX; _rd[0xAE] = 1;
    _id[0xAF] = CPU_LAX; _rd[0xAF] = 1;
    _id[0xB0] = CPU_BCS; _rd[0xB0] = 0;
    _id[0xB1] = CPU_LDA; _rd[0xB1] = 1;
    _id[0xB2] = CPU_JAM; _rd[0xB2] = 0;
    _id[0xB3] = CPU_LAX; _rd[0xB3] = 1;
    _id[0xB4] = CPU_LDY; _rd[0xB4] = 1;
    _id[0xB5] = CPU_LDA; _rd[0xB5] = 1;
    _id[0xB6] = CPU_LDX; _rd[0xB6] = 1;
    _id[0xB7] = CPU_LAX; _rd[0xB7] = 1;
    _id[0xB8] = CPU_CLV; _rd[0xB8] = 0;
    _id[0xB9] = CPU_LDA; _rd[0xB9] = 1;
    _id[0xBA] = CPU_TSX; _rd[0xBA] = 0;
    _id[0xBB] = CPU_LAS; _rd[0xBB] = 1;
    _id[0xBC] = CPU_LDY; _rd[0xBC] = 1;
    _id[0xBD] = CPU_LDA; _rd[0xBD] = 1;
    _id[0xBE] = CPU_LDX; _rd[0xBE] = 1;
    _id[0xBF] = CPU_LAX; _rd[0xBF] = 1;
    _id[0xC0] = CPU_CPY; _rd[0xC0] = 1;
    _id[0xC1] = CPU_CMP; _rd[0xC1] = 1;
    _id[0xC2] = CPU_NOP; _rd[0xC2] = 1;
    _id[0xC3] = CPU_DCP; _rd[0xC3] = 1;
    _id[0xC4] = CPU_CPY; _rd[0xC4] = 1;
    _id[0xC5] = CPU_CMP; _rd[0xC5] = 1;
    _id[0xC6] = CPU_DEC; _rd[0xC6] = 1;
    _id[0xC7] = CPU_DCP; _rd[0xC7] = 1;
    _id[0xC8] = CPU_INY; _rd[0xC8] = 0;
    _id[0xC9] = CPU_CMP; _rd[0xC9] = 1;
    _id[0xCA] = CPU_DEX; _rd[0xCA] = 0;
    _id[0xCB] = CPU_SBX; _rd[0xCB] = 1;
    _id[0xCC] = CPU_CPY; _rd[0xCC] = 1;
    _id[0xCD] = CPU_CMP; _rd[0xCD] = 1;
    _id[0xCE] = CPU_DEC; _rd[0xCE] = 1;
    _id[0xCF] = CPU_DCP; _rd[0xCF] = 1;
    _id[0xD0] = CPU_BNE; _rd[0xD0] = 0;
    _id[0xD1] = CPU_CMP; _rd[0xD1] = 1;
    _id[0xD2] = CPU_JAM; _rd[0xD2] = 0;
    _id[0xD3] = CPU_DCP; _rd[0xD3] = 1;
    _id[0xD4] = CPU_NOP; _rd[0xD4] = 1;
    _id[0xD5] = CPU_CMP; _rd[0xD5] = 1;
    _id[0xD6] = CPU_DEC; _rd[0xD6] = 1;
    _id[0xD7] = CPU_DCP; _rd[0xD7] = 1;
    _id[0xD8] = CPU_CLD; _rd[0xD8] = 0;
    _id[0xD9] = CPU_CMP; _rd[0xD9] = 1;
    _id[0xDA] = CPU_NOP; _rd[0xDA] = 0;
    _id[0xDB] = CPU_DCP; _rd[0xDB] = 1;
    _id[0xDC] = CPU_NOP; _rd[0xDC] = 1;
    _id[0xDD] = CPU_CMP; _rd[0xDD] = 1;
    _id[0xDE] = CPU_DEC; _rd[0xDE] = 1;
    _id[0xDF] = CPU_DCP; _rd[0xDF] = 1;
    _id[0xE0] = CPU_CPX; _rd[0xE0] = 1;
    _id[0xE1] = CPU_SBC; _rd[0xE1] = 1;
    _id[0xE2] = CPU_NOP; _rd[0xE2] = 1;
    _id[0xE3] = CPU_ISC; _rd[0xE3] = 1;
    _id[0xE4] = CPU_CPX; _rd[0xE4] = 1;
    _id[0xE5] = CPU_SBC; _rd[0xE5] = 1;
    _id[0xE6] = CPU_INC; _rd[0xE6] = 1;
    _id[0xE7] = CPU_ISC; _rd[0xE7] = 1;
    _id[0xE8] = CPU_INX; _rd[0xE8] = 0;
    _id[0xE9] = CPU_SBC; _rd[0xE9] = 1;
    _id[0xEA] = CPU_NOP; _rd[0xEA] = 0;
    _id[0xEB] = CPU_SBC; _rd[0xEB] = 1;
    _id[0xEC] = CPU_CPX; _rd[0xEC] = 1;
    _id[0xED] = CPU_SBC; _rd[0xED] = 1;
    _id[0xEE] = CPU_INC; _rd[0xEE] = 1;
    _id[0xEF] = CPU_ISC; _rd[0xEF] = 1;
    _id[0xF0] = CPU_BEQ; _rd[0xF0] = 0;
    _id[0xF1] = CPU_SBC; _rd[0xF1] = 1;
    _id[0xF2] = CPU_JAM; _rd[0xF2] = 0;
    _id[0xF3] = CPU_ISC; _rd[0xF3] = 1;
    _id[0xF4] = CPU_NOP; _rd[0xF4] = 1;
    _id[0xF5] = CPU_SBC; _rd[0xF5] = 1;
    _id[0xF6] = CPU_INC; _rd[0xF6] = 1;
    _id[0xF7] = CPU_ISC; _rd[0xF7] = 1;
    _id[0xF8] = CPU_SED; _rd[0xF8] = 0;
    _id[0xF9] = CPU_SBC; _rd[0xF9] = 1;
    _id[0xFA] = CPU_NOP; _rd[0xFA] = 0;
    _id[0xFB] = CPU_ISC; _rd[0xFB] = 1;
    _id[0xFC] = CPU_NOP; _rd[0xFC] = 1;
    _id[0xFD] = CPU_SBC; _rd[0xFD] = 1;
    _id[0xFE] = CPU_INC; _rd[0xFE] = 1;
    _id[0xFF] = CPU_ISC; _rd[0xFF] = 1;
    global.cpu_id = _id;
    global.cpu_rd = _rd;
    global.cpu_mode = array_create(256, 0);
    global.cpu_size = array_create(256, 0);
    for (var _i = 0; _i < 256; _i++) {
        global.cpu_mode[_i] = global.ext_ops[_i].mode;
        global.cpu_size[_i] = global.ext_ops[_i].size;
    }
}

/// @desc scr_ext_cpu_new_state() - registers and runner bookkeeping
function scr_ext_cpu_new_state() {
    return {
        pc : 0, a : 0, x : 0, y : 0, sp : 0xFD,
        fc : 0, fz : 0, fn : 0, fv : 0, fi : 0, fd : 0,
        port : 0x37, io : true, raster : 0,
        writes : 0, steps : 0,
        prev_ctrl : false, prev_jsr : false,
        stage : 1
    };
}

/// @desc scr_ext_decrunch_start(entry)
/// Copies the loaded file into the runner's RAM and starts at entry
/// (normally the BASIC SYS address). Runs a slice per frame from the Step event.
function scr_ext_decrunch_start(_entry) {
    buffer_copy(mem_buf, 0, 65536, cpu_mem, 0);
    buffer_fill(cpu_w, 0, buffer_u8, 0, 65536);
    buffer_fill(cpu_execd, 0, buffer_u8, 0, 65536);

    // What KERNAL LOAD and BASIC leave behind
    var _end = 0x0801;
    for (var _i = 0; _i < array_length(segments); _i++) {
        if (segments[_i].finish + 1 > _end) {
            _end = segments[_i].finish + 1;
        }
    }
    buffer_poke(cpu_mem, 0x00, buffer_u8, 0x2F);
    buffer_poke(cpu_mem, 0x01, buffer_u8, 0x37);
    buffer_poke(cpu_mem, 0x2B, buffer_u8, 0x01);
    buffer_poke(cpu_mem, 0x2C, buffer_u8, 0x08);
    var _ptrs = [0x2D, 0x2F, 0x31, 0xAE];
    for (var _i = 0; _i < array_length(_ptrs); _i++) {
        buffer_poke(cpu_mem, _ptrs[_i], buffer_u8, _end & 0xFF);
        buffer_poke(cpu_mem, _ptrs[_i] + 1, buffer_u8, (_end >> 8) & 0xFF);
    }

    cpu = scr_ext_cpu_new_state();
    cpu.pc = _entry & 0xFFFF;
    cpu.sp = 0xF6;
    // SYS is a JSR from BASIC: a plain RTS goes back into the BASIC ROM
    var _ret = 0xA7EA - 1;
    buffer_poke(cpu_mem, 0x100 + cpu.sp, buffer_u8, (_ret >> 8) & 0xFF);
    cpu.sp = (cpu.sp - 1) & 255;
    buffer_poke(cpu_mem, 0x100 + cpu.sp, buffer_u8, _ret & 0xFF);
    cpu.sp = (cpu.sp - 1) & 255;

    cpu_entry = _entry & 0xFFFF;
    cpu_active = true;
    status_text = "Unpacking from $" + scr_ext_hex(cpu_entry, 4) + "...";
}

/// @desc scr_ext_decrunch_resume()
/// Carries on from where the runner stopped (multi-stage packers).
function scr_ext_decrunch_resume() {
    cpu.prev_ctrl = false;
    cpu.prev_jsr = false;
    cpu.stage += 1;
    cpu_active = true;
    status_text = "Unpacking stage " + string(cpu.stage) + "...";
}

/// @desc scr_ext_cpu_slice(ms)
/// Runs the 6502 for up to ms milliseconds, then hands back to the frame.
function scr_ext_cpu_slice(_ms) {
    var _m = cpu_mem;
    var _wb = cpu_w;
    var _ex = cpu_execd;
    var _id_t = global.cpu_id;
    var _rd_t = global.cpu_rd;
    var _mode_t = global.cpu_mode;
    var _size_t = global.cpu_size;

    var _pc = cpu.pc;
    var _a = cpu.a;
    var _x = cpu.x;
    var _y = cpu.y;
    var _sp = cpu.sp;
    var _fc = cpu.fc;
    var _fz = cpu.fz;
    var _fn = cpu.fn;
    var _fv = cpu.fv;
    var _fi = cpu.fi;
    var _fd = cpu.fd;
    var _port = cpu.port;
    var _io = cpu.io;
    var _raster = cpu.raster;
    var _writes = cpu.writes;
    var _steps = cpu.steps;
    var _prev_ctrl = cpu.prev_ctrl;
    var _prev_jsr = cpu.prev_jsr;

    var _deadline = get_timer() + _ms * 1000;
    var _count = 0;
    var _result = "";
    var _result_pc = 0;

    while (true) {
        _count += 1;
        if ((_count & 1023) == 0) {
            if (get_timer() > _deadline) {
                break;
            }
            if (_steps >= EXT_CPU_MAX_STEPS) {
                _result = "budget";
                _result_pc = _pc;
                break;
            }
        }

        // ---- Stop rules ----
        // Execution reached ROM space we haven't written: a KERNAL/BASIC call
        if (((_pc >= 0xA000 && _pc < 0xC000) || _pc >= 0xE000) && buffer_peek(_wb, _pc, buffer_u8) == 0) {
            if (_prev_jsr) {
                // A ROM subroutine we can't run: behave as if it returned
                _sp = (_sp + 1) & 255;
                var _rlo = buffer_peek(_m, 0x100 + _sp, buffer_u8);
                _sp = (_sp + 1) & 255;
                var _rhi = buffer_peek(_m, 0x100 + _sp, buffer_u8);
                _pc = ((_rlo | (_rhi << 8)) + 1) & 0xFFFF;
                _prev_jsr = false;
                continue;
            }
            _result = "rom";
            _result_pc = _pc;
            break;
        }
        // A jump / return into bytes written (since last run) by the unpacker
        if (_prev_ctrl && _writes >= EXT_CPU_MIN_WRITES && _pc >= 0x0400) {
            if (buffer_peek(_wb, _pc, buffer_u8) == 1 && buffer_peek(_ex, _pc, buffer_u8) == 0) {
                _result = "start";
                _result_pc = _pc;
                break;
            }
        }

        var _op = buffer_peek(_m, _pc, buffer_u8);
        var _id = _id_t[_op];
        if (_id == CPU_BRK) {
            _result = "brk";
            _result_pc = _pc;
            break;
        }
        if (_id == CPU_JAM) {
            _result = "jam";
            _result_pc = _pc;
            break;
        }
        var _sz = _size_t[_op];
        for (var _k = 0; _k < _sz; _k++) {
            buffer_poke(_ex, (_pc + _k) & 0xFFFF, buffer_u8, 1);
        }

        // ---- Effective address ----
        var _mode = _mode_t[_op];
        var _o1 = buffer_peek(_m, (_pc + 1) & 0xFFFF, buffer_u8);
        var _o2 = buffer_peek(_m, (_pc + 2) & 0xFFFF, buffer_u8);
        var _npc = (_pc + _sz) & 0xFFFF;
        var _ea = 0;
        switch (_mode) {
            case EXT_MODE_IMM: _ea = (_pc + 1) & 0xFFFF; break;
            case EXT_MODE_ZP:  _ea = _o1; break;
            case EXT_MODE_ZPX: _ea = (_o1 + _x) & 255; break;
            case EXT_MODE_ZPY: _ea = (_o1 + _y) & 255; break;
            case EXT_MODE_ABS: _ea = _o1 | (_o2 << 8); break;
            case EXT_MODE_ABX: _ea = ((_o1 | (_o2 << 8)) + _x) & 0xFFFF; break;
            case EXT_MODE_ABY: _ea = ((_o1 | (_o2 << 8)) + _y) & 0xFFFF; break;
            case EXT_MODE_IND:
                var _ptr = _o1 | (_o2 << 8);
                _ea = buffer_peek(_m, _ptr, buffer_u8) | (buffer_peek(_m, (_ptr & 0xFF00) | ((_ptr + 1) & 255), buffer_u8) << 8);
                break;
            case EXT_MODE_IZX:
                var _zx = (_o1 + _x) & 255;
                _ea = buffer_peek(_m, _zx, buffer_u8) | (buffer_peek(_m, (_zx + 1) & 255, buffer_u8) << 8);
                break;
            case EXT_MODE_IZY:
                _ea = ((buffer_peek(_m, _o1, buffer_u8) | (buffer_peek(_m, (_o1 + 1) & 255, buffer_u8) << 8)) + _y) & 0xFFFF;
                break;
            case EXT_MODE_REL:
                var _d = _o1;
                if (_d > 127) {
                    _d -= 256;
                }
                _ea = (_pc + 2 + _d) & 0xFFFF;
                break;
        }

        // ---- Operand read (I/O area answers a few registers) ----
        var _v = 0;
        if (_rd_t[_op] == 1) {
            if (_mode == EXT_MODE_IMM) {
                _v = buffer_peek(_m, _ea, buffer_u8);
            }
            else if (_ea >= 0xD000 && _ea < 0xE000 && _io) {
                _v = 0;
                if (_ea == 0xD012) {
                    _raster = (_raster + 1) & 255;
                    _v = _raster;
                }
                else if (_ea == 0xD011) {
                    _v = 0x1B | ((_raster & 1) << 7);
                }
                else if (_ea == 0xDC00 || _ea == 0xDC01) {
                    _v = 0xFF;
                }
            }
            else {
                _v = buffer_peek(_m, _ea, buffer_u8);
            }
        }

        // ---- Execute ----
        var _wv = -1;       // value to store at _ea, -1 = no store
        var _nzv = -1;      // value to set N and Z from, -1 = leave flags
        var _do_adc = false;
        var _do_sbc = false;
        var _do_cmp = false;
        var _arg = 0;
        var _cmp_reg = 0;
        var _carry = 0;
        _prev_ctrl = false;
        _prev_jsr = false;

        switch (_id) {
            case CPU_LDA: _a = _v; _nzv = _a; break;
            case CPU_LDX: _x = _v; _nzv = _x; break;
            case CPU_LDY: _y = _v; _nzv = _y; break;
            case CPU_LAX: _a = _v; _x = _v; _nzv = _v; break;
            case CPU_STA: _wv = _a; break;
            case CPU_STX: _wv = _x; break;
            case CPU_STY: _wv = _y; break;
            case CPU_SAX: _wv = _a & _x; break;
            case CPU_TAX: _x = _a; _nzv = _x; break;
            case CPU_TAY: _y = _a; _nzv = _y; break;
            case CPU_TXA: _a = _x; _nzv = _a; break;
            case CPU_TYA: _a = _y; _nzv = _a; break;
            case CPU_TSX: _x = _sp; _nzv = _x; break;
            case CPU_TXS: _sp = _x; break;
            case CPU_INX: _x = (_x + 1) & 255; _nzv = _x; break;
            case CPU_INY: _y = (_y + 1) & 255; _nzv = _y; break;
            case CPU_DEX: _x = (_x - 1) & 255; _nzv = _x; break;
            case CPU_DEY: _y = (_y - 1) & 255; _nzv = _y; break;
            case CPU_AND: _a = _a & _v; _nzv = _a; break;
            case CPU_ORA: _a = _a | _v; _nzv = _a; break;
            case CPU_EOR: _a = _a ^ _v; _nzv = _a; break;
            case CPU_ADC: _do_adc = true; _arg = _v; break;
            case CPU_SBC: _do_sbc = true; _arg = _v; break;
            case CPU_CMP: _do_cmp = true; _cmp_reg = _a; _arg = _v; break;
            case CPU_CPX: _do_cmp = true; _cmp_reg = _x; _arg = _v; break;
            case CPU_CPY: _do_cmp = true; _cmp_reg = _y; _arg = _v; break;
            case CPU_BIT:
                _fz = 0;
                if ((_a & _v) == 0) {
                    _fz = 1;
                }
                _fn = (_v >> 7) & 1;
                _fv = (_v >> 6) & 1;
                break;

            case CPU_ASL:
            case CPU_SLO:
                if (_mode == EXT_MODE_ACC) {
                    _fc = _a >> 7;
                    _a = (_a << 1) & 255;
                    _nzv = _a;
                }
                else {
                    _fc = _v >> 7;
                    _wv = (_v << 1) & 255;
                    if (_id == CPU_SLO) {
                        _a = _a | _wv;
                        _nzv = _a;
                    }
                    else {
                        _nzv = _wv;
                    }
                }
                break;

            case CPU_LSR:
            case CPU_SRE:
                if (_mode == EXT_MODE_ACC) {
                    _fc = _a & 1;
                    _a = _a >> 1;
                    _nzv = _a;
                }
                else {
                    _fc = _v & 1;
                    _wv = _v >> 1;
                    if (_id == CPU_SRE) {
                        _a = _a ^ _wv;
                        _nzv = _a;
                    }
                    else {
                        _nzv = _wv;
                    }
                }
                break;

            case CPU_ROL:
            case CPU_RLA:
                if (_mode == EXT_MODE_ACC) {
                    _carry = _a >> 7;
                    _a = ((_a << 1) | _fc) & 255;
                    _fc = _carry;
                    _nzv = _a;
                }
                else {
                    _carry = _v >> 7;
                    _wv = ((_v << 1) | _fc) & 255;
                    _fc = _carry;
                    if (_id == CPU_RLA) {
                        _a = _a & _wv;
                        _nzv = _a;
                    }
                    else {
                        _nzv = _wv;
                    }
                }
                break;

            case CPU_ROR:
            case CPU_RRA:
                if (_mode == EXT_MODE_ACC) {
                    _carry = _a & 1;
                    _a = (_a >> 1) | (_fc << 7);
                    _fc = _carry;
                    _nzv = _a;
                }
                else {
                    _carry = _v & 1;
                    _wv = (_v >> 1) | (_fc << 7);
                    _fc = _carry;
                    if (_id == CPU_RRA) {
                        _do_adc = true;
                        _arg = _wv;
                    }
                    else {
                        _nzv = _wv;
                    }
                }
                break;

            case CPU_INC:
            case CPU_ISC:
                _wv = (_v + 1) & 255;
                if (_id == CPU_ISC) {
                    _do_sbc = true;
                    _arg = _wv;
                }
                else {
                    _nzv = _wv;
                }
                break;

            case CPU_DEC:
            case CPU_DCP:
                _wv = (_v - 1) & 255;
                if (_id == CPU_DCP) {
                    _do_cmp = true;
                    _cmp_reg = _a;
                    _arg = _wv;
                }
                else {
                    _nzv = _wv;
                }
                break;

            case CPU_ANC:
                _a = _a & _v;
                _nzv = _a;
                _fc = _a >> 7;
                break;
            case CPU_ALR:
                _a = _a & _v;
                _fc = _a & 1;
                _a = _a >> 1;
                _nzv = _a;
                break;
            case CPU_ARR:
                _a = _a & _v;
                _a = (_a >> 1) | (_fc << 7);
                _nzv = _a;
                _fc = (_a >> 6) & 1;
                _fv = ((_a >> 6) ^ (_a >> 5)) & 1;
                break;
            case CPU_SBX:
                var _sbx = (_a & _x) - _v;
                _fc = 0;
                if (_sbx >= 0) {
                    _fc = 1;
                }
                _x = _sbx & 255;
                _nzv = _x;
                break;

            case CPU_CLC: _fc = 0; break;
            case CPU_SEC: _fc = 1; break;
            case CPU_CLI: _fi = 0; break;
            case CPU_SEI: _fi = 1; break;
            case CPU_CLD: _fd = 0; break;
            case CPU_SED: _fd = 1; break;
            case CPU_CLV: _fv = 0; break;

            case CPU_PHA:
                buffer_poke(_m, 0x100 + _sp, buffer_u8, _a);
                _sp = (_sp - 1) & 255;
                break;
            case CPU_PHP:
                buffer_poke(_m, 0x100 + _sp, buffer_u8, (_fn << 7) | (_fv << 6) | 0x30 | (_fd << 3) | (_fi << 2) | (_fz << 1) | _fc);
                _sp = (_sp - 1) & 255;
                break;
            case CPU_PLA:
                _sp = (_sp + 1) & 255;
                _a = buffer_peek(_m, 0x100 + _sp, buffer_u8);
                _nzv = _a;
                break;
            case CPU_PLP:
                _sp = (_sp + 1) & 255;
                var _pl = buffer_peek(_m, 0x100 + _sp, buffer_u8);
                _fn = (_pl >> 7) & 1;
                _fv = (_pl >> 6) & 1;
                _fd = (_pl >> 3) & 1;
                _fi = (_pl >> 2) & 1;
                _fz = (_pl >> 1) & 1;
                _fc = _pl & 1;
                break;

            case CPU_JMP:
                _npc = _ea;
                _prev_ctrl = true;
                break;
            case CPU_JSR:
                var _ret = (_npc - 1) & 0xFFFF;
                buffer_poke(_m, 0x100 + _sp, buffer_u8, _ret >> 8);
                _sp = (_sp - 1) & 255;
                buffer_poke(_m, 0x100 + _sp, buffer_u8, _ret & 255);
                _sp = (_sp - 1) & 255;
                _npc = _ea;
                _prev_jsr = true;
                break;
            case CPU_RTS:
                _sp = (_sp + 1) & 255;
                var _slo = buffer_peek(_m, 0x100 + _sp, buffer_u8);
                _sp = (_sp + 1) & 255;
                var _shi = buffer_peek(_m, 0x100 + _sp, buffer_u8);
                _npc = ((_slo | (_shi << 8)) + 1) & 0xFFFF;
                _prev_ctrl = true;
                break;
            case CPU_RTI:
                _sp = (_sp + 1) & 255;
                var _ip = buffer_peek(_m, 0x100 + _sp, buffer_u8);
                _fn = (_ip >> 7) & 1;
                _fv = (_ip >> 6) & 1;
                _fd = (_ip >> 3) & 1;
                _fi = (_ip >> 2) & 1;
                _fz = (_ip >> 1) & 1;
                _fc = _ip & 1;
                _sp = (_sp + 1) & 255;
                var _ilo = buffer_peek(_m, 0x100 + _sp, buffer_u8);
                _sp = (_sp + 1) & 255;
                var _ihi = buffer_peek(_m, 0x100 + _sp, buffer_u8);
                _npc = _ilo | (_ihi << 8);
                _prev_ctrl = true;
                break;

            case CPU_BPL: if (_fn == 0) { _npc = _ea; } break;
            case CPU_BMI: if (_fn == 1) { _npc = _ea; } break;
            case CPU_BVC: if (_fv == 0) { _npc = _ea; } break;
            case CPU_BVS: if (_fv == 1) { _npc = _ea; } break;
            case CPU_BCC: if (_fc == 0) { _npc = _ea; } break;
            case CPU_BCS: if (_fc == 1) { _npc = _ea; } break;
            case CPU_BNE: if (_fz == 0) { _npc = _ea; } break;
            case CPU_BEQ: if (_fz == 1) { _npc = _ea; } break;

            case CPU_NOP:
                break;

            default:
                // ANE, LXA, LAS, SHA, SHX, SHY, TAS: unstable, never used by packers
                _result = "unsupported";
                _result_pc = _pc;
                break;
        }
        if (_result != "") {
            break;
        }

        // ---- Deferred arithmetic ----
        if (_do_adc) {
            if (_fd == 1) {
                var _lo = (_a & 15) + (_arg & 15) + _fc;
                var _hi = (_a >> 4) + (_arg >> 4);
                if (_lo > 9) {
                    _lo += 6;
                    _hi += 1;
                }
                _fz = 0;
                if (((_a + _arg + _fc) & 255) == 0) {
                    _fz = 1;
                }
                _fn = (_hi >> 3) & 1;
                _fv = 0;
                if (((~(_a ^ _arg)) & (_a ^ (_hi << 4)) & 0x80) != 0) {
                    _fv = 1;
                }
                if (_hi > 9) {
                    _hi += 6;
                }
                _fc = 0;
                if (_hi > 15) {
                    _fc = 1;
                }
                _a = ((_hi << 4) | (_lo & 15)) & 255;
            }
            else {
                var _sum = _a + _arg + _fc;
                _fv = 0;
                if (((~(_a ^ _arg)) & (_a ^ _sum) & 0x80) != 0) {
                    _fv = 1;
                }
                _fc = 0;
                if (_sum > 255) {
                    _fc = 1;
                }
                _a = _sum & 255;
                _nzv = _a;
            }
        }
        if (_do_sbc) {
            var _dif = _a - _arg - (1 - _fc);
            _fv = 0;
            if (((_a ^ _arg) & (_a ^ _dif) & 0x80) != 0) {
                _fv = 1;
            }
            if (_fd == 1) {
                var _dlo = (_a & 15) - (_arg & 15) - (1 - _fc);
                var _dhi = (_a >> 4) - (_arg >> 4);
                if (_dlo < 0) {
                    _dlo -= 6;
                    _dhi -= 1;
                }
                if (_dhi < 0) {
                    _dhi -= 6;
                }
                _fc = 0;
                if (_dif >= 0) {
                    _fc = 1;
                }
                _nzv = _dif & 255;
                _a = ((_dhi << 4) | (_dlo & 15)) & 255;
            }
            else {
                _fc = 0;
                if (_dif >= 0) {
                    _fc = 1;
                }
                _a = _dif & 255;
                _nzv = _a;
            }
        }
        if (_do_cmp) {
            var _cr = _cmp_reg - _arg;
            _fc = 0;
            if (_cr >= 0) {
                _fc = 1;
            }
            _nzv = _cr & 255;
        }
        if (_nzv >= 0) {
            _fn = _nzv >> 7;
            _fz = 0;
            if (_nzv == 0) {
                _fz = 1;
            }
        }

        // ---- Store (processor port, I/O, RAM) ----
        if (_wv >= 0) {
            if (_ea == 0x0001) {
                _port = _wv;
                _io = ((_wv & 3) != 0) && ((_wv & 4) != 0);
            }
            if (_ea >= 0xD000 && _ea < 0xE000 && _io) {
                // I/O register write: ignored
            }
            else {
                buffer_poke(_m, _ea, buffer_u8, _wv);
                buffer_poke(_wb, _ea, buffer_u8, 1);
                buffer_poke(_ex, _ea, buffer_u8, 0);
                _writes += 1;
            }
        }

        _pc = _npc;
        _steps += 1;
    }

    cpu.pc = _pc;
    cpu.a = _a;
    cpu.x = _x;
    cpu.y = _y;
    cpu.sp = _sp;
    cpu.fc = _fc;
    cpu.fz = _fz;
    cpu.fn = _fn;
    cpu.fv = _fv;
    cpu.fi = _fi;
    cpu.fd = _fd;
    cpu.port = _port;
    cpu.io = _io;
    cpu.raster = _raster;
    cpu.writes = _writes;
    cpu.steps = _steps;
    cpu.prev_ctrl = _prev_ctrl;
    cpu.prev_jsr = _prev_jsr;

    if (_result != "") {
        scr_ext_decrunch_finish(_result, _result_pc);
    }
    else {
        status_text = "Unpacking: " + string(_steps) + " instructions, " + string(_writes) + " bytes written   (Esc to cancel)";
    }
}

/// @desc scr_ext_decrunch_finish(result, pc)
/// Takes the unpacked memory, re-analyses it, and continues if it is still packed.
function scr_ext_decrunch_finish(_result, _pc) {
    cpu_active = false;

    if (_result != "start" && _result != "rom") {
        var _why = "an unsupported instruction";
        if (_result == "brk") {
            _why = "a BRK";
        }
        if (_result == "jam") {
            _why = "a JAM (CPU lock-up) opcode";
        }
        if (_result == "budget") {
            _why = "the instruction limit";
        }
        status_text = "Unpack stopped at $" + scr_ext_hex(_pc, 4) + " on " + _why + " after " + string(cpu.steps) + " instructions - memory left as loaded.";
        return;
    }

    // Take the runner's RAM; anything it wrote now counts as loaded
    buffer_copy(cpu_mem, 0, 65536, mem_buf, 0);
    var _lo = -1;
    var _hi = -1;
    for (var _i = 0; _i < 65536; _i++) {
        if (buffer_peek(cpu_w, _i, buffer_u8) == 1) {
            buffer_poke(loaded_buf, _i, buffer_u8, 1);
            if (_i >= 0x0200) {
                if (_lo < 0) {
                    _lo = _i;
                }
                _hi = _i;
            }
        }
    }
    if (_lo >= 0) {
        array_push(segments, { start : _lo, finish : _hi, name : "unpacked" });
    }

    var _start = _pc;
    if (_result == "rom" && _pc >= 0xA000 && _pc < 0xC000) {
        // The unpacker handed over to BASIC RUN: the program starts from its SYS line
        var _sys = scr_ext_find_basic_sys();
        if (array_length(_sys) > 0) {
            _start = _sys[0];
        }
    }
    manual_entries = [_start];
    file_kind = "unpacked by running its decruncher";
    scr_ext_analyse();
    scr_ext_set_cursor(_start, true);

    var _loaded = 65536 - cls_counts[EXT_CLS_NONE];
    var _still_packed = false;
    if (_loaded > 0 && cls_counts[EXT_CLS_PACKED] * 10 >= _loaded * 3) {
        _still_packed = true;
    }
    if (_still_packed && _result == "start" && cpu.stage < EXT_CPU_MAX_STAGES) {
        scr_ext_decrunch_resume();
        return;
    }
    status_text = "Unpacked: start $" + scr_ext_hex(_start, 4) + " after " + string(cpu.steps) + " instructions (" + string(cpu.writes) + " bytes written, stage " + string(cpu.stage) + ").";
    scr_ext_keep_unpacked();
}

/// @desc scr_ext_unpack_entry()
/// Where to start the decruncher: the BASIC SYS address, else the cursor.
function scr_ext_unpack_entry() {
    for (var _i = 0; _i < array_length(entries); _i++) {
        if (entries[_i].why == "BASIC SYS") {
            return entries[_i].addr;
        }
    }
    return cursor_addr;
}

/// @desc scr_ext_maybe_auto_unpack()
/// Called after a load: starts the runner by itself when the file looks crunched.
function scr_ext_maybe_auto_unpack() {
    if (!auto_unpack) {
        return;
    }
    var _loaded = 65536 - cls_counts[EXT_CLS_NONE];
    if (_loaded > 0 && cls_counts[EXT_CLS_PACKED] * 10 >= _loaded * 3) {
        scr_ext_decrunch_start(scr_ext_unpack_entry());
    }
}
