const std = @import("std");

const rl = @import("../../raylib.zig");
const cnv = @import("convert.zig");
const iff = cnv.iff;
const Vector3 = rl.Vector3;

const M = @This();

pub const Color = extern struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 0,
    pub fn from(arr: [4]u8) Color {
        return .{ .r = arr[0], .g = arr[1], .b = arr[2], .a = arr[3] };
    }

    pub const hsv = struct {
        /// Convert from Vector3 as .{.x = hue, .y = saturation, .z = value}
        pub fn vec3(v: Vector3) Color {
            return Color.hsv.from(v.x, v.y, v.z);
        }
        /// Convert from raylib
        pub fn rl(v: M.rl.Vector3) Color {
            return Color.hsv.from(v.x, v.y, v.z);
        }
        pub fn from(hue: f32, saturation: f32, value: f32) Color {
            var color: Color = Color{ .r = 0, .g = 0, .b = 0, .a = 255 };
            var k: f32 = @mod(5.0 + (hue / 60.0), 6);
            var t: f32 = 4.0 - k;
            k = if (t < k) t else k;
            k = if (k < 1) k else 1;
            k = if (k > 0) k else 0;
            color.r = iff(u8, (value - ((value * saturation) * k)) * 255.0);
            k = @mod(3.0 + (hue / 60.0), 6);
            t = 4.0 - k;
            k = if (t < k) t else k;
            k = if (k < 1) k else 1;
            k = if (k > 0) k else 0;
            color.g = iff(u8, (value - ((value * saturation) * k)) * 255.0);
            k = @mod(1.0 + (hue / 60.0), 6);
            t = 4.0 - k;
            k = if (t < k) t else k;
            k = if (k < 1) k else 1;
            k = if (k > 0) k else 0;
            color.b = iff(u8, (value - ((value * saturation) * k)) * 255.0);
            return color;
        }
    };
};
pub const LIGHTGRAY: Color = .from(.{ 200, 200, 200, 255 });
pub const GRAY: Color = .from(.{ 130, 130, 130, 255 });
pub const DARKGRAY: Color = .from(.{ 80, 80, 80, 255 });
pub const YELLOW: Color = .from(.{ 253, 249, 0, 255 });
pub const GOLD: Color = .from(.{ 255, 203, 0, 255 });
pub const ORANGE: Color = .from(.{ 255, 161, 0, 255 });
pub const PINK: Color = .from(.{ 255, 109, 194, 255 });
pub const RED: Color = .from(.{ 230, 41, 55, 255 });
pub const MAROON: Color = .from(.{ 190, 33, 55, 255 });
pub const GREEN: Color = .from(.{ 0, 228, 48, 255 });
pub const LIME: Color = .from(.{ 0, 158, 47, 255 });
pub const DARKGREEN: Color = .from(.{ 0, 117, 44, 255 });
pub const SKYBLUE: Color = .from(.{ 102, 191, 255, 255 });
pub const BLUE: Color = .from(.{ 0, 121, 241, 255 });
pub const DARKBLUE: Color = .from(.{ 0, 82, 172, 255 });
pub const PURPLE: Color = .from(.{ 200, 122, 255, 255 });
pub const VIOLET: Color = .from(.{ 135, 60, 190, 255 });
pub const DARKPURPLE: Color = .from(.{ 112, 31, 126, 255 });
pub const BEIGE: Color = .from(.{ 211, 176, 131, 255 });
pub const BROWN: Color = .from(.{ 127, 106, 79, 255 });
pub const DARKBROWN: Color = .from(.{ 76, 63, 47, 255 });
pub const WHITE: Color = .from(.{ 255, 255, 255, 255 });
pub const BLACK: Color = .from(.{ 0, 0, 0, 255 });
pub const BLANK: Color = .from(.{ 0, 0, 0, 0 });
pub const MAGENTA: Color = .from(.{ 255, 0, 255, 255 });
pub const RAYWHITE: Color = .from(.{ 245, 245, 245, 255 });

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
    const ColorFromHSV = @import("../../raylib.zig").ColorFromHSV;
    for (0..36) |x| {
        for (0..10) |y| {
            for (0..10) |z| {
                const h: f32 = @floatFromInt(x * 10);
                const s: f32 = @floatFromInt(y);
                const v: f32 = @floatFromInt(z);
                const raylib_hsv = ColorFromHSV(h, s / 10, v / 10);
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
