const gui = @import("../gui.zig");

pub inline fn onTabChange(tab: gui.Tab) void {
    const modules = .{gui};
    inline for (modules) |module| {
        module.onTabChange(tab);
    }
}

pub const Direction = enum { horizontal, vertical };
pub inline fn onSwipe(dir: Direction, amount: f32) void {
    gui.onSwipe(dir, amount);
}
