const c = @import("raylib.zig");

pub fn asF32(v: anytype) f32 {
    return @floatFromInt(v);
}
pub fn fromHSV(col: c.Vector3) c.Color {
    return c.ColorFromHSV(col.x, col.y, col.z);
}
