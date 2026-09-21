//! Configurables. These are picked up and set in the UI
const std = @import("std");

/// name, value, range
pub const Scalar = struct { []const u8, *f32, struct { f32, f32 } };
pub fn constrainScalar(scalar: Scalar) void {
    const value = scalar[1];
    const range = scalar[2];
    value.* = if (std.math.isFinite(value.*))
        std.math.clamp(value.*, range[0], range[1])
    else
        range[0];
}
pub const ScalarList = struct { name: []const []const u8, value: []f32, range: []struct { f32, f32 } };
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
