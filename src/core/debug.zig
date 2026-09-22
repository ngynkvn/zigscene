//! Optional runtime diagnostics, toggled with D.
const std = @import("std");
const processor = @import("../audio/processor.zig");
const Rectangle = @import("../ext/structs.zig").Rectangle;
const rl = @import("../raylib.zig");

const panel_width: f32 = 280;
const panel_height: f32 = 166;
const panel_margin: f32 = 12;
var screen_width: i32 = @import("config.zig").Window.width;
var visible = false;

pub fn onWindowResize(width: i32, _: i32) void {
    screen_width = width;
}

pub fn frame() void {
    if (rl.isKeyPressed(.D)) visible = !visible;
}

pub fn render() void {
    if (!visible) return;
    const x = @max(panel_margin, @as(f32, @floatFromInt(screen_width)) - panel_width - panel_margin);
    const panel = Rectangle.from(x, 32, panel_width, panel_height);
    _ = rl.GuiPanel(panel.into(), "Debug");

    const mouse = rl.GetMousePosition();
    const delta = rl.GetMouseDelta();
    const wheel = rl.GetMouseWheelMoveV();
    drawLine(panel, 30, "FPS: {d}  Frame: {d:.1} ms", .{ rl.GetFPS(), rl.GetFrameTime() * 1000 });
    drawLine(panel, 54, "Mouse: {d:.0}, {d:.0}", .{ mouse.x, mouse.y });
    drawLine(panel, 78, "Move: {d:.1}, {d:.1}", .{ delta.x, delta.y });
    drawLine(panel, 102, "Wheel: {d:.1}, {d:.1}  Left: {}", .{ wheel.x, wheel.y, rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT) });
    drawLine(panel, 126, "Audio RMS: {d:.3}  Beat: {}", .{ processor.rms_energy, processor.on_beat });
}

fn drawLine(panel: Rectangle, y: f32, comptime format: []const u8, args: anytype) void {
    var buffer: [128]u8 = undefined;
    const line = std.fmt.bufPrintZ(&buffer, format, args) catch return;
    _ = rl.GuiLabel(panel.resize(panel.width - 24, 18).translate(12, y).into(), line.ptr);
}
