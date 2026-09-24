//! Logical UI dimensions, independent of display pixels and Raylib state.
const std = @import("std");

pub fn scaleForWindow(percent: f32, width: f32, height: f32) f32 {
    const requested = std.math.clamp(percent / 100, 0.75, 1.5);
    // Keep a complete, usable layout when a scaled window is made smaller.
    return @min(requested, @min(width / 640, height / 480));
}

pub const Size = struct { width: f32, height: f32 };

pub fn panelSize(requested_width: f32, requested_height: f32, window_width: f32, window_height: f32) Size {
    const max_height = @max(180, window_height - 268);
    return .{
        .width = std.math.clamp(requested_width, 280, @max(280, @min(640, window_width - 240))),
        .height = if (requested_height == 0) max_height else std.math.clamp(requested_height, 180, max_height),
    };
}

test "UI scale fits small windows and preserves requested size on larger ones" {
    try std.testing.expectEqual(@as(f32, 1.5), scaleForWindow(150, 1920, 1080));
    try std.testing.expectEqual(@as(f32, 1), scaleForWindow(150, 640, 480));
    try std.testing.expectEqual(@as(f32, 0.75), scaleForWindow(75, 1024, 768));
}

test "resizing panels respects available space and automatic height" {
    try std.testing.expectEqual(Size{ .width = 320, .height = 500 }, panelSize(320, 0, 1024, 768));
    try std.testing.expectEqual(Size{ .width = 400, .height = 212 }, panelSize(600, 900, 640, 480));
    try std.testing.expectEqual(Size{ .width = 280, .height = 180 }, panelSize(0, 1, 1024, 768));
    try std.testing.expectEqual(Size{ .width = 500, .height = 350 }, panelSize(500, 350, 1024, 768));
}
