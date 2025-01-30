const rl = @import("../../raylib.zig");

// @floatFromInt shortcut
pub inline fn ffi(T: type, x: anytype) T {
    return @as(T, @floatFromInt(x));
}
// @intFromFloat shortcut
pub inline fn iff(T: type, x: anytype) T {
    return @as(T, @intFromFloat(x));
}

pub inline fn rgb(r: u8, g: u8, b: u8) rl.Color {
    return .{ .r = r, .g = g, .b = b, .a = 255 };
}
