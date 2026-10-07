/// @desc scr_ext_cls_colour(cls)
function scr_ext_cls_colour(_c) {
    switch (_c) {
        case EXT_CLS_NONE:    return make_colour_rgb(18, 18, 22);
        case EXT_CLS_UNKNOWN: return make_colour_rgb(90, 90, 90);
        case EXT_CLS_SURE:    return make_colour_rgb(60, 200, 80);
        case EXT_CLS_LIKELY:  return make_colour_rgb(230, 210, 60);
        case EXT_CLS_DOUBT:   return make_colour_rgb(240, 140, 40);
        case EXT_CLS_NOT:     return make_colour_rgb(190, 50, 50);
        case EXT_CLS_GFX:     return make_colour_rgb(60, 120, 230);
        case EXT_CLS_MUSIC:   return make_colour_rgb(170, 90, 220);
        case EXT_CLS_TEXT:    return make_colour_rgb(60, 200, 220);
        case EXT_CLS_PACKED:  return make_colour_rgb(220, 70, 170);
    }
    return c_white;
}

/// @desc scr_ext_cls_name(cls)
function scr_ext_cls_name(_c) {
    switch (_c) {
        case EXT_CLS_NONE:    return "Not loaded";
        case EXT_CLS_UNKNOWN: return "Unknown";
        case EXT_CLS_SURE:    return "Code (sure)";
        case EXT_CLS_LIKELY:  return "Code (likely)";
        case EXT_CLS_DOUBT:   return "Code (doubtful)";
        case EXT_CLS_NOT:     return "Not code";
        case EXT_CLS_GFX:     return "Graphics";
        case EXT_CLS_MUSIC:   return "Music / SID";
        case EXT_CLS_TEXT:    return "Text";
        case EXT_CLS_PACKED:  return "Packed";
    }
    return "?";
}

/// @desc scr_ext_build_map()
/// Redraws the 256x256 memory map surface: one pixel per byte, one row per page.
function scr_ext_build_map() {
    if (!surface_exists(map_surf)) {
        map_surf = surface_create(256, 256);
    }
    var _cols = array_create(EXT_CLS_COUNT, 0);
    for (var _i = 0; _i < EXT_CLS_COUNT; _i++) {
        _cols[_i] = scr_ext_cls_colour(_i);
    }

    surface_set_target(map_surf);
    draw_clear(_cols[EXT_CLS_NONE]);

    for (var _y = 0; _y < 256; _y++) {
        var _base = _y * 256;
        if (map_shaded) {
            // Brightness follows the byte value, so structure inside a class is visible
            for (var _xs = 0; _xs < 256; _xs++) {
                var _cs = buffer_peek(cls_buf, _base + _xs, buffer_u8);
                if (_cs != EXT_CLS_NONE) {
                    var _v = buffer_peek(mem_buf, _base + _xs, buffer_u8);
                    var _col = merge_colour(c_black, _cols[_cs], 0.35 + 0.65 * (_v / 255));
                    draw_point_colour(_xs, _y, _col);
                }
            }
        }
        else {
            // Run-length rectangles; every run is drawn (including NONE) so any
            // 1px overdraw from draw_rectangle is corrected by the next run / row
            var _run_start = 0;
            var _run_cls = buffer_peek(cls_buf, _base, buffer_u8);
            for (var _x = 1; _x <= 256; _x++) {
                var _c = -1;
                if (_x < 256) {
                    _c = buffer_peek(cls_buf, _base + _x, buffer_u8);
                }
                if (_c != _run_cls) {
                    draw_set_colour(_cols[_run_cls]);
                    draw_rectangle(_run_start, _y, _x, _y + 1, false);
                    _run_start = _x;
                    _run_cls = _c;
                }
            }
        }
    }

    surface_reset_target();
    draw_set_colour(c_white);
    map_dirty = false;
}
