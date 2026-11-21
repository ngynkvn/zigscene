//! Session-only window state for projecting the scene.
const Performance = @This();
const builtin = @import("builtin");
const rl = @import("raylib");

pub const supported = builtin.os.tag != .emscripten;

active: bool = false,
blackout: bool = false,
restore_windowed: bool = false,

pub fn enter(self: *Performance) bool {
    if (!supported) return false;
    const was_borderless = rl.IsWindowState(rl.FLAG_BORDERLESS_WINDOWED_MODE);
    if (!was_borderless) rl.ToggleBorderlessWindowed();
    if (!rl.IsWindowState(rl.FLAG_BORDERLESS_WINDOWED_MODE)) return false;
    self.* = .{ .active = true, .restore_windowed = !was_borderless };
    rl.SetExitKey(rl.KEY_NULL);
    rl.HideCursor();
    return true;
}

pub fn leave(self: *Performance) void {
    if (!supported) return;
    if (self.restore_windowed and rl.IsWindowState(rl.FLAG_BORDERLESS_WINDOWED_MODE)) rl.ToggleBorderlessWindowed();
    rl.ShowCursor();
    rl.SetExitKey(rl.KEY_ESCAPE);
    self.* = .{};
}
