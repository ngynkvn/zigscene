//! Native system chooser, with the browser chooser supplied by picker.c.
const std = @import("std");
const builtin = @import("builtin");
extern fn tinyfd_openFileDialog([*:0]const u8, [*:0]const u8, c_int, [*]const [*:0]const u8, [*:0]const u8, c_int) ?[*:0]const u8;
extern fn zigscene_pick_audio() void;
extern fn zigscene_picked_audio() ?[*:0]const u8;

pub fn open() error{Unavailable}!?[]const u8 {
    if (builtin.os.tag == .emscripten) {
        zigscene_pick_audio();
        return null;
    }
    const filters = [_][*:0]const u8{ "*.mp3", "*.wav", "*.ogg" };
    // Never fall through to a terminal prompt in a graphical application.
    if (tinyfd_openFileDialog("tinyfd_query", "", filters.len, &filters, "Audio files", 0) == null) return error.Unavailable;
    const rl = @import("raylib");
    const topmost = rl.IsWindowState(rl.FLAG_WINDOW_TOPMOST);
    if (topmost) rl.ClearWindowState(rl.FLAG_WINDOW_TOPMOST);
    defer if (topmost) rl.SetWindowState(rl.FLAG_WINDOW_TOPMOST);
    const result = tinyfd_openFileDialog("Open audio", "", filters.len, &filters, "Audio files (MP3, WAV, OGG)", 0) orelse return null;
    return std.mem.span(result);
}
pub fn poll() ?[]const u8 {
    if (builtin.os.tag != .emscripten) return null;
    return if (zigscene_picked_audio()) |path| std.mem.span(path) else null;
}
