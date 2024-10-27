const rl = @import("../raylib.zig");

pub fn asF32(v: anytype) f32 {
    return @floatFromInt(v);
}
