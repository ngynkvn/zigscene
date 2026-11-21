//! Configurables. These are picked up and set in the UI
const std = @import("std");

/// label, value, range. The range is f64 so the settings registry, which
/// validates script writes in doubles, sees the bounds exactly as written.
pub const Scalar = struct { [:0]const u8, *f32, struct { f64, f64 } };
pub fn constrainScalar(scalar: Scalar) void {
    const value = scalar[1];
    const range = scalar[2];
    value.* = if (std.math.isFinite(value.*))
        std.math.clamp(value.*, @as(f32, @floatCast(range[0])), @as(f32, @floatCast(range[1])))
    else
        @floatCast(range[0]);
}
pub const Color = struct { []const u8, *f32 };

test "scalar inputs stay within their supported range" {
    var value: f32 = 2;
    const scalar: Scalar = .{ "Opacity", &value, .{ 0.15, 1.0 } };
    constrainScalar(scalar);
    try std.testing.expectEqual(@as(f32, 1.0), value);

    value = -1;
    constrainScalar(scalar);
    try std.testing.expectEqual(@as(f32, 0.15), value);

    value = std.math.nan(f32);
    constrainScalar(scalar);
    try std.testing.expectEqual(@as(f32, 0.15), value);
}
