/// @desc Free buffers and surfaces

buffer_delete(mem_buf);
buffer_delete(loaded_buf);
buffer_delete(cls_buf);
buffer_delete(istart_buf);
buffer_delete(entry_buf);
buffer_delete(cpu_mem);
buffer_delete(cpu_w);
buffer_delete(cpu_execd);
if (buffer_exists(d64_buf)) {
    buffer_delete(d64_buf);
}
if (surface_exists(map_surf)) {
    surface_free(map_surf);
}
if (buffer_exists(gfx_buf)) {
    buffer_delete(gfx_buf);
}
if (surface_exists(gfx_surf)) {
    surface_free(gfx_surf);
}
scr_ext_cache_clear();
