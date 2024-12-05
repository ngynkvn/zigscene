const music = @import("../audio/playback.zig");
const graphics = @import("../graphics.zig");
const gui = @import("../gui.zig");
const shader = @import("../shader/shader.zig");
const debug = @import("debug.zig");

pub inline fn onFilenameInput(filename: []const u8) void {
    const modules = .{music};
    inline for (modules) |module| {
        module.onFilenameInput(filename);
    }
}

pub inline fn onTabChange(tab: gui.Tab) void {
    const modules = .{gui};
    inline for (modules) |module| {
        module.onTabChange(tab);
    }
}

pub inline fn onWindowResize(width: i32, height: i32) void {
    const modules = .{ graphics, shader, debug };
    inline for (modules) |module| {
        module.onWindowResize(width, height);
    }
}

pub const Direction = enum { horizontal, vertical };
pub inline fn onSwipe(dir: Direction, amount: f32) void {
    gui.onSwipe(dir, amount);
}
