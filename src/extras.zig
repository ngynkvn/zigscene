const rl = @import("raylib.zig");

pub fn asF32(v: anytype) f32 {
    return @floatFromInt(v);
}
pub fn fromHSV(col: rl.Vector3) rl.Color {
    return rl.ColorFromHSV(col.x, col.y, col.z);
}
