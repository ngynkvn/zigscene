pub const Color = extern struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 0,
    pub fn from(arr: [4]u8) Color {
        return .{ .r = arr[0], .g = arr[1], .b = arr[2], .a = arr[3] };
    }
    pub fn ColorFromHSV(arg_hue: f32, arg_saturation: f32, arg_value: f32) Color {
        var hue = arg_hue;
        _ = &hue;
        var saturation = arg_saturation;
        _ = &saturation;
        var value = arg_value;
        _ = &value;
        var color: Color = Color{
            .r = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .g = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .b = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .a = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
        };
        _ = &color;
        var k: f32 = @mod(5.0 + (hue / 60.0), @as(f32, @floatFromInt(@as(c_int, 6))));
        _ = &k;
        var t: f32 = 4.0 - k;
        _ = &t;
        k = if (t < k) t else k;
        k = if (k < @as(f32, @floatFromInt(@as(c_int, 1)))) k else @as(f32, @floatFromInt(@as(c_int, 1)));
        k = if (k > @as(f32, @floatFromInt(@as(c_int, 0)))) k else @as(f32, @floatFromInt(@as(c_int, 0)));
        color.r = @as(u8, @intFromFloat((value - ((value * saturation) * k)) * 255.0));
        k = @mod(3.0 + (hue / 60.0), @as(f32, @floatFromInt(@as(c_int, 6))));
        t = 4.0 - k;
        k = if (t < k) t else k;
        k = if (k < @as(f32, @floatFromInt(@as(c_int, 1)))) k else @as(f32, @floatFromInt(@as(c_int, 1)));
        k = if (k > @as(f32, @floatFromInt(@as(c_int, 0)))) k else @as(f32, @floatFromInt(@as(c_int, 0)));
        color.g = @as(u8, @intFromFloat((value - ((value * saturation) * k)) * 255.0));
        k = @mod(1.0 + (hue / 60.0), @as(f32, @floatFromInt(@as(c_int, 6))));
        t = 4.0 - k;
        k = if (t < k) t else k;
        k = if (k < @as(f32, @floatFromInt(@as(c_int, 1)))) k else @as(f32, @floatFromInt(@as(c_int, 1)));
        k = if (k > @as(f32, @floatFromInt(@as(c_int, 0)))) k else @as(f32, @floatFromInt(@as(c_int, 0)));
        color.b = @as(u8, @intFromFloat((value - ((value * saturation) * k)) * 255.0));
        return color;
    }
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
