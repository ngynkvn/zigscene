pub const Color = extern struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 0,
    pub fn from(arr: [4]u8) Color {
        return .{ .r = arr[0], .g = arr[1], .b = arr[2], .a = arr[3] };
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
