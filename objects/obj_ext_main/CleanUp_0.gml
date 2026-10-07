/// @desc Free buffers and surfaces

buffer_delete(mem_buf);
buffer_delete(loaded_buf);
buffer_delete(cls_buf);
buffer_delete(istart_buf);
buffer_delete(entry_buf);
if (buffer_exists(d64_buf)) {
    buffer_delete(d64_buf);
}
if (surface_exists(map_surf)) {
    surface_free(map_surf);
}
