const std = @import("std");

pub const float3 = extern struct {
    v: [3]f32,
};

pub fn feql(x: f32, y: f32) bool {
    return std.math.approxEqAbs(f32, x, y, std.math.floatEps(f32));
}
