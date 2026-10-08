// ============================================================================
// SID playback through reSID (the sid64 extension from C64 Dev Machine).
// The tune's own init / play routines are run on the extractor's 6502 core
// (scr_ext_cpu_slice in call mode). After every play call the 25 SID
// registers are snapshotted; sid64_render_log turns 4 frames at a time into
// 44.1 kHz audio which is streamed into a GameMaker play queue, kept ~12
// frames ahead of what is being heard. Same scheme as CDM's SID asset preview.
// ============================================================================

#macro EXT_SID_CLOCK      985248     // PAL
#macro EXT_SID_RATE       44100
#macro EXT_SID_CYCLES     19656      // one PAL frame
#macro EXT_SID_RING       32
#macro EXT_SID_INIT_STEPS 200000
#macro EXT_SID_PLAY_STEPS 40000

/// @desc scr_ext_sid_setup() - checks for the extension (called once from Create)
function scr_ext_sid_setup() {
    sid_ok = false;
    try {
        if (sid64_version() >= 2) {
            sid64_select(0);
            sid64_init(EXT_SID_CLOCK, EXT_SID_RATE, sid_model, 0);
            sid64_set_gain(0.6);
            sid64_set_cycles_per_frame(EXT_SID_CYCLES);
            sid_ok = true;
        }
    }
    catch (_e) {
        sid_ok = false;
    }
}

/// @desc scr_ext_sid_call(addr, a) - JSR addr with A = a, run until it returns
function scr_ext_sid_call(_addr, _a, _budget) {
    var _ret = EXT_CPU_SENTINEL - 1;
    buffer_poke(cpu_mem, 0x100 + cpu.sp, buffer_u8, (_ret >> 8) & 0xFF);
    cpu.sp = (cpu.sp - 1) & 255;
    buffer_poke(cpu_mem, 0x100 + cpu.sp, buffer_u8, _ret & 0xFF);
    cpu.sp = (cpu.sp - 1) & 255;
    cpu.pc = _addr & 0xFFFF;
    cpu.a = _a & 255;
    cpu.x = 0;
    cpu.y = 0;
    cpu.fi = 1;
    cpu.steps = 0;
    cpu.prev_ctrl = false;
    cpu.prev_jsr = false;
    return scr_ext_cpu_slice(2000, true, _budget);
}

/// @desc scr_ext_sid_start(init, play, song)
function scr_ext_sid_start(_init, _play, _song) {
    scr_ext_sid_stop();
    if (!sid_ok) {
        status_text = "SID playback needs the sid64 (reSID) extension, which isn't available on this platform.";
        return false;
    }
    if (cpu_active) {
        status_text = "Wait for the unpack to finish before playing.";
        return false;
    }

    // The tune runs on its own copy of memory, so playing never changes the analysis
    buffer_copy(mem_buf, 0, 65536, cpu_mem, 0);
    buffer_fill(cpu_w, 0, buffer_u8, 0, 65536);
    buffer_fill(cpu_execd, 0, buffer_u8, 0, 65536);
    buffer_fill(sid_shadow, 0, buffer_u8, 0, 32);
    buffer_poke(cpu_mem, 0x01, buffer_u8, 0x37);
    cpu = scr_ext_cpu_new_state();
    cpu.sp = 0xF6;

    var _r = scr_ext_sid_call(_init, _song, EXT_SID_INIT_STEPS);
    if (_r != "return") {
        status_text = "SID init at $" + scr_ext_hex(_init, 4) + " didn't return (" + _r + " at $" + scr_ext_hex(cpu.pc, 4) + ").";
        return false;
    }

    sid_init_addr = _init;
    sid_play_addr = _play;
    sid_song = _song;
    sid_cap = ceil(4 * EXT_SID_CYCLES * EXT_SID_RATE / EXT_SID_CLOCK) + 128;
    sid_fb = buffer_create(128, buffer_fixed, 1);
    buffer_fill(sid_fb, 0, buffer_u8, 0, 128);
    sid_ring = [];
    for (var _i = 0; _i < EXT_SID_RING; _i++) {
        array_push(sid_ring, buffer_create(sid_cap * 2, buffer_fixed, 2));
    }
    sid_ring_i = 0;
    sid_rendered = 0;

    sid64_select(0);
    sid64_init(EXT_SID_CLOCK, EXT_SID_RATE, sid_model, 0);
    sid64_set_gain(0.6);
    sid64_set_cycles_per_frame(EXT_SID_CYCLES);
    sid64_settle(buffer_peek(sid_shadow, 0x18, buffer_u8), 100);

    sid_queue = audio_create_play_queue(buffer_s16, EXT_SID_RATE, audio_mono);
    sid_playing = true;
    for (var _c = 0; _c < 3; _c++) {
        if (!scr_ext_sid_chunk()) {
            return false;
        }
    }
    sid_inst = audio_play_sound(sid_queue, 1, false);
    sid_start_time = get_timer();

    var _model_name = "6581";
    if (sid_model == 1) {
        _model_name = "8580";
    }
    status_text = "Playing SID: init $" + scr_ext_hex(_init, 4) + "  play $" + scr_ext_hex(_play, 4) + "  tune " + string(_song + 1) + "  (" + _model_name + ")   P stop, Shift+P next tune, Ctrl+P 6581/8580";
    return true;
}

/// @desc scr_ext_sid_chunk() - runs 4 play calls and queues their audio
function scr_ext_sid_chunk() {
    for (var _f = 0; _f < 4; _f++) {
        var _r = scr_ext_sid_call(sid_play_addr, 0, EXT_SID_PLAY_STEPS);
        if (_r != "return") {
            status_text = "SID playback stopped: play $" + scr_ext_hex(sid_play_addr, 4) + " ended with " + _r + " at $" + scr_ext_hex(cpu.pc, 4) + ".";
            scr_ext_sid_stop();
            return false;
        }
        for (var _reg = 0; _reg < 25; _reg++) {
            buffer_poke(sid_fb, _f * 32 + _reg, buffer_u8, buffer_peek(sid_shadow, _reg, buffer_u8));
        }
    }
    var _buf = sid_ring[sid_ring_i];
    sid_ring_i = (sid_ring_i + 1) mod EXT_SID_RING;
    var _got = sid64_render_log(buffer_get_address(sid_fb), 4, buffer_get_address(_buf), sid_cap);
    if (_got <= 0) {
        status_text = "reSID produced no audio.";
        scr_ext_sid_stop();
        return false;
    }
    // reSID wrote the samples straight into the buffer's memory: tell GameMaker
    // how much of it is now in use, or the play queue sees an empty buffer
    buffer_set_used_size(_buf, _got * 2);
    audio_queue_sound(sid_queue, _buf, 0, _got * 2);
    sid_rendered += 4;
    return true;
}

/// @desc scr_ext_sid_update() - keeps the queue ~12 frames ahead (Step event)
function scr_ext_sid_update() {
    if (!sid_playing) {
        return;
    }
    var _period = EXT_SID_CYCLES * 1000000 / EXT_SID_CLOCK;
    var _played = floor((get_timer() - sid_start_time) / _period);
    var _deadline = get_timer() + 6000;
    while (sid_rendered < _played + 12) {
        if (!scr_ext_sid_chunk()) {
            return;
        }
        if (get_timer() > _deadline) {
            break;
        }
    }
    // Fell behind (e.g. a dialog was open): restart the clock rather than race
    if (sid_rendered < _played) {
        var _behind = sid_rendered - 12;
        if (_behind < 0) {
            _behind = 0;
        }
        sid_start_time = get_timer() - _behind * _period;
    }
}

/// @desc scr_ext_sid_stop()
function scr_ext_sid_stop() {
    if (sid_inst != -1) {
        audio_stop_sound(sid_inst);
        sid_inst = -1;
    }
    if (sid_queue != -1) {
        audio_free_play_queue(sid_queue);
        sid_queue = -1;
    }
    for (var _i = 0; _i < array_length(sid_ring); _i++) {
        if (buffer_exists(sid_ring[_i])) {
            buffer_delete(sid_ring[_i]);
        }
    }
    sid_ring = [];
    if (buffer_exists(sid_fb)) {
        buffer_delete(sid_fb);
    }
    sid_fb = -1;
    sid_playing = false;
}

/// @desc scr_ext_sid_pick() - the SID music finding to play: the one under the
/// cursor, else the most confident one in this file. Returns its index or -1.
function scr_ext_sid_pick() {
    var _best = -1;
    for (var _i = 0; _i < array_length(findings); _i++) {
        var _f = findings[_i];
        if (_f.kind != "SID music") {
            continue;
        }
        if (cursor_addr >= _f.addr && cursor_addr < _f.addr + _f.len) {
            return _i;
        }
        if (_best < 0) {
            _best = _i;
        }
    }
    return _best;
}

/// @desc scr_ext_sid_toggle(next_tune, swap_model) - the P key / Play SID button
function scr_ext_sid_toggle(_next, _swap_model) {
    if (_swap_model) {
        if (sid_model == 0) {
            sid_model = 1;
        }
        else {
            sid_model = 0;
        }
        if (sid_playing) {
            scr_ext_sid_start(sid_init_addr, sid_play_addr, sid_song);
        }
        else {
            status_text = "SID model: 6581";
            if (sid_model == 1) {
                status_text = "SID model: 8580";
            }
        }
        return;
    }
    if (_next) {
        if (sid_init_addr >= 0) {
            scr_ext_sid_start(sid_init_addr, sid_play_addr, (sid_song + 1) mod 32);
        }
        return;
    }
    if (sid_playing) {
        scr_ext_sid_stop();
        status_text = "SID stopped.";
        return;
    }
    var _i = scr_ext_sid_pick();
    if (_i < 0) {
        status_text = "No playable SID music here (needs a JMP init / JMP play table) - try R, then N.";
        return;
    }
    scr_ext_sid_start(findings[_i].init, findings[_i].play, 0);
}
