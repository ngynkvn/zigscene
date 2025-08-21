const std = @import("std");
const rl = @import("raylib_c");

pub const Color = extern struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 0,
    pub fn from(c: anytype) Color {
        switch (@TypeOf(c)) {
            [4]u8 => return .{ .r = c[0], .g = c[1], .b = c[2], .a = c[3] },
            [3]u8 => return .{ .r = c[0], .g = c[1], .b = c[2], .a = 255 },
            comptime_int => {
                const cc: u32 = c;
                return @bitCast(cc);
            },
            else => @compileError("Invalid type for Color.from: " ++ @typeName(@TypeOf(c))),
        }
    }

    pub const hsv = struct {
        /// Convert from Vector3 as .{.x = hue, .y = saturation, .z = value}
        pub fn vec3(v: anytype) Color {
            return Color.hsv.from(v.x, v.y, v.z);
        }
        pub fn from(hue: f32, saturation: f32, value: f32) Color {
            var color: Color = Color{ .r = 0, .g = 0, .b = 0, .a = 255 };
            var k: f32 = @mod(5.0 + (hue / 60.0), 6);
            var t: f32 = 4.0 - k;
            k = if (t < k) t else k;
            k = if (k < 1) k else 1;
            k = if (k > 0) k else 0;
            color.r = @as(u8, @intFromFloat((value - ((value * saturation) * k)) * 255.0));
            k = @mod(3.0 + (hue / 60.0), 6);
            t = 4.0 - k;
            k = if (t < k) t else k;
            k = if (k < 1) k else 1;
            k = if (k > 0) k else 0;
            color.g = @as(u8, @intFromFloat((value - ((value * saturation) * k)) * 255.0));
            k = @mod(1.0 + (hue / 60.0), 6);
            t = 4.0 - k;
            k = if (t < k) t else k;
            k = if (k < 1) k else 1;
            k = if (k > 0) k else 0;
            color.b = @as(u8, @intFromFloat((value - ((value * saturation) * k)) * 255.0));
            return color;
        }
    };
};

test "fromHSV conversion" {
    // Red (hue = 0, saturation = 1, value = 1)
    try std.testing.expectEqualDeep(Color{ .r = 255, .g = 0, .b = 0, .a = 255 }, Color.hsv.from(0.0, 1.0, 1.0));
    // Green (hue = 120, saturation = 1, value = 1)
    try std.testing.expectEqualDeep(Color{ .r = 0, .g = 255, .b = 0, .a = 255 }, Color.hsv.from(120.0, 1.0, 1.0));
    // Blue (hue = 240, saturation = 1, value = 1)
    try std.testing.expectEqualDeep(Color{ .r = 0, .g = 0, .b = 255, .a = 255 }, Color.hsv.from(240.0, 1.0, 1.0));
    // White (hue = any, saturation = 0, value = 1)
    try std.testing.expectEqualDeep(Color{ .r = 255, .g = 255, .b = 255, .a = 255 }, Color.hsv.from(0.0, 0.0, 1.0));
    // Black (hue = any, saturation = any, value = 0)
    try std.testing.expectEqualDeep(Color{ .r = 0, .g = 0, .b = 0, .a = 255 }, Color.hsv.from(180.0, 0.5, 0.0));
    // Gray (hue = any, saturation = 0, value = 0.5)
    try std.testing.expectEqualDeep(Color{ .r = 127, .g = 127, .b = 127, .a = 255 }, Color.hsv.from(300.0, 0.0, 0.5));
    // Intermediate color (hue = 60, saturation = 1, value = 0.5)
    try std.testing.expectEqualDeep(Color{ .r = 127, .g = 127, .b = 0, .a = 255 }, Color.hsv.from(60.0, 1.0, 0.5));
    // Hue wrapping around (hue = 360, saturation = 1, value = 1)
    try std.testing.expectEqualDeep(Color{ .r = 255, .g = 0, .b = 0, .a = 255 }, Color.hsv.from(360.0, 1.0, 1.0));
}

test "fromHSV = HsvToColor" {
    for (0..36) |x| {
        for (0..10) |y| {
            for (0..10) |z| {
                const h: f32 = @floatFromInt(x * 10);
                const s: f32 = @floatFromInt(y);
                const v: f32 = @floatFromInt(z);
                const raylib_hsv = rl.colorFromHSV(h, s / 10, v / 10);
                const color = Color.hsv.from(h, s / 10, v / 10);
                try std.testing.expectEqualDeep(raylib_hsv, color);

                // make sure layout is the same
                const rl_bytes = std.mem.asBytes(&raylib_hsv);
                const c_bytes = std.mem.asBytes(&color);
                try std.testing.expectEqualSlices(u8, rl_bytes, c_bytes);
                try std.testing.expectEqualDeep(raylib_hsv, Color.hsv.from(h, s / 10, v / 10));
                try std.testing.expectEqualDeep(color, Color.hsv.rl(.{ .x = h, .y = s / 10, .z = v / 10 }));
            }
        }
    }
}
