const c = struct {
    extern fn fade(a: c_uint, alpha: f32) u8;
};
const zig = struct {
    pub fn fade(a: u8, alpha: f32) u8 {
        return @as(u8, @intFromFloat(@as(f32, @floatFromInt(a)) * alpha));
    }
};

test "Equivalence" {
    const std = @import("std");
    const n = std.math.maxInt(u8);
    const incr: f32 = 1.0 / @as(f32, @floatFromInt(n));
    comptime {
        try std.testing.expectEqual(1, n * incr);
    }

    var c_values = std.mem.zeroes([n * n]u8);
    var z_values = std.mem.zeroes([n * n]u8);
    for (0..n) |i| {
        var alpha: f32 = @floatFromInt(i);
        alpha *= incr;
        for (0..std.math.maxInt(u8)) |j| {
            const a: u8 = @intCast(j);
            z_values[a + i * n] = zig.fade(a, alpha);
            c_values[a + i * n] = c.fade(a, alpha);
        }
    }
    try std.testing.expectEqualSlices(u8, &z_values, &c_values);
}
