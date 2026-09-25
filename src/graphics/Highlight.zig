//! Transient drawing emphasis. Never changes scene visibility or saved colors.
const std = @import("std");
const rl = @import("../raylib.zig");
const Scene = @import("../core/config.zig").Scene;
const Highlight = @This();

pub const Element = enum {
    wave_lines,
    wave_bars,
    spectrum,
    bubble,
    halo,

    pub fn visible(self: Element) bool {
        return switch (self) {
            .wave_lines => Scene.wave_lines,
            .wave_bars => Scene.wave_bars,
            .spectrum => Scene.spectrum,
            .bubble => Scene.bubble,
            .halo => Scene.halo,
        };
    }

    /// Anchored to the bottom edge, where the player dock covers most of it.
    pub fn underDock(self: Element) bool {
        return switch (self) {
            .wave_bars, .spectrum => true,
            .wave_lines, .bubble, .halo => false,
        };
    }
};

target: ?Element = null,

pub fn init(target: ?Element) Highlight {
    // Hovering a hidden layer must not dim the entire scene or reveal the layer.
    return .{ .target = if (target) |element| (if (element.visible()) element else null) else null };
}

pub fn selected(self: Highlight, element: Element) bool {
    return self.target == element;
}

pub fn tint(self: Highlight, element: Element, color: rl.Color) rl.Color {
    if (self.target == null) return color;
    if (self.selected(element)) {
        return .{
            .r = @intFromFloat(std.math.lerp(@as(f32, @floatFromInt(color.r)), 160, 0.8)),
            .g = @intFromFloat(std.math.lerp(@as(f32, @floatFromInt(color.g)), 255, 0.8)),
            .b = @intFromFloat(std.math.lerp(@as(f32, @floatFromInt(color.b)), 229, 0.8)),
            .a = color.a,
        };
    }
    // Recede strongly so the one affected layer is unambiguous.
    return .{ .r = color.r / 5, .g = color.g / 5, .b = color.b / 5, .a = color.a };
}

test "hover emphasis leaves normal colors and hidden layers unchanged" {
    const color = rl.Color{ .r = 90, .g = 180, .b = 240, .a = 210 };
    try std.testing.expectEqual(color, (Highlight{}).tint(.bubble, color));
    const original = Scene.bubble;
    defer Scene.bubble = original;
    Scene.bubble = false;
    try std.testing.expectEqual(@as(?Element, null), init(.bubble).target);
    try std.testing.expectEqual(color, init(.bubble).tint(.halo, color));
    Scene.bubble = true;
    const focus = init(.bubble);
    try std.testing.expect(focus.tint(.bubble, color).g > color.g);
    try std.testing.expect(focus.tint(.halo, color).g < color.g);
    try std.testing.expectEqual(color.a, focus.tint(.bubble, color).a);
    try std.testing.expect(Scene.bubble);
}
