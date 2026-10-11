//! Logical UI dimensions, independent of display pixels and Raylib state.
const std = @import("std");

pub fn scaleForWindow(percent: f32, width: f32, height: f32) f32 {
    const requested = std.math.clamp(percent / 100, 0.75, 1.5);
    // Keep a complete, usable layout when a scaled window is made smaller.
    return @min(requested, @min(width / 640, height / 480));
}

// Shared by drawing, scrolling and hit testing so compact spacing stays aligned.
// Bars and panels dock flush to the window edges and meet at one-pixel seams.
pub const header_height: f32 = 40;
pub const panel_top: f32 = header_height;
/// The side panel's tab strip, above its scrolling content.
pub const panel_header: f32 = 32;
pub const status_height: f32 = 24;
pub const dock_height: f32 = 100;
pub fn compact(window_width: f32, window_height: f32) bool {
    return window_width < 820 or window_height < 620;
}
pub fn dockHeight(window_width: f32, window_height: f32) f32 {
    return if (compact(window_width, window_height)) 80 else dock_height;
}
pub const group_height: f32 = 30;
pub const row_height: f32 = 44;
pub const slider_top: f32 = 24;
pub const slider_height: f32 = 18;
pub const scene_actions_height: f32 = 40;
pub const scene_card_height: f32 = 58;
pub const scene_row_height: f32 = 66;

pub const Size = struct { width: f32, height: f32 };

/// The side panel fills the height between the header and the player, or the
/// status bar when the player is hidden, until it is manually resized.
pub fn panelSize(requested_width: f32, requested_height: f32, window_width: f32, window_height: f32, player: bool) Size {
    const floor = window_height - status_height - (if (player) dockHeight(window_width, window_height) else 0);
    const max_height = @max(180, floor - panel_top);
    const maximum_width: f32 = if (compact(window_width, window_height)) 280 else 640;
    return .{
        .width = std.math.clamp(requested_width, 280, @max(280, @min(maximum_width, window_width - 240))),
        .height = if (requested_height == 0) max_height else std.math.clamp(requested_height, 180, max_height),
    };
}

test "UI scale fits small windows and preserves requested size on larger ones" {
    try std.testing.expectEqual(@as(f32, 1.5), scaleForWindow(150, 1920, 1080));
    try std.testing.expectEqual(@as(f32, 1), scaleForWindow(150, 640, 480));
    try std.testing.expectEqual(@as(f32, 0.75), scaleForWindow(75, 1024, 768));
}

test "resizing panels respects available space and automatic height" {
    try std.testing.expectEqual(Size{ .width = 320, .height = 604 }, panelSize(320, 0, 1024, 768, true));
    try std.testing.expectEqual(Size{ .width = 320, .height = 704 }, panelSize(320, 0, 1024, 768, false));
    try std.testing.expectEqual(Size{ .width = 280, .height = 336 }, panelSize(600, 900, 640, 480, true));
    try std.testing.expectEqual(Size{ .width = 280, .height = 180 }, panelSize(0, 1, 1024, 768, true));
    try std.testing.expectEqual(Size{ .width = 500, .height = 350 }, panelSize(500, 350, 1024, 768, true));
}
