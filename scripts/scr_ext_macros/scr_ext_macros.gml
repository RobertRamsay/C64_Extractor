// ============================================================================
// C64 Extractor - shared constants
// ============================================================================

// Memory classification, one value per byte in cls_buf.
// NOTE: EXT_CLS_UNKNOWN must stay 1, scr_ext_analyse copies loaded_buf
// (1 = loaded) straight into cls_buf to initialise it.
// not loaded
#macro EXT_CLS_NONE     0
// loaded, not yet classified
#macro EXT_CLS_UNKNOWN  1
// green  - traced from a strong entry point
#macro EXT_CLS_SURE     2
// yellow - traced from a weak entry or high heuristic score
#macro EXT_CLS_LIKELY   3
// orange - weak heuristic score
#macro EXT_CLS_DOUBT    4
// red    - definitely not code
#macro EXT_CLS_NOT      5
// blue   - graphics (phase 3)
#macro EXT_CLS_GFX      6
// purple - SID / music (phase 4)
#macro EXT_CLS_MUSIC    7
// cyan   - text (phase 3)
#macro EXT_CLS_TEXT     8
#macro EXT_CLS_COUNT    9

// 6502 addressing modes
#macro EXT_MODE_IMP  0
#macro EXT_MODE_ACC  1
#macro EXT_MODE_IMM  2
#macro EXT_MODE_ZP   3
#macro EXT_MODE_ZPX  4
#macro EXT_MODE_ZPY  5
#macro EXT_MODE_ABS  6
#macro EXT_MODE_ABX  7
#macro EXT_MODE_ABY  8
#macro EXT_MODE_IND  9
#macro EXT_MODE_IZX  10
#macro EXT_MODE_IZY  11
#macro EXT_MODE_REL  12

// Control flow types used by the tracer
#macro EXT_FLOW_NORMAL  0
#macro EXT_FLOW_BRANCH  1
#macro EXT_FLOW_JSR     2
// JMP absolute
#macro EXT_FLOW_JMP     3
// RTS, RTI, BRK, JMP (indirect)
#macro EXT_FLOW_STOP    4
// KIL / JAM - CPU locks up, never real code
#macro EXT_FLOW_JAM     5

// Heuristic thresholds for untraced bytes
#macro EXT_SEQ_LENGTH    12
#macro EXT_LIKELY_SCORE  14
#macro EXT_DOUBT_SCORE   6
