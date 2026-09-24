//! Configurable frame counter and optional diagnostics, toggled with D.
const std = @import("std");
const processor = @import("../audio/processor.zig");
const config = @import("config.zig");
const ui = @import("../gui/theme.zig");
const rl = @import("../raylib.zig");

const panel_width: f32 = 280;
const panel_height: f32 = 186;
const panel_margin: f32 = 16;
var visible = false;

pub const Timings = struct {
    audio: f64 = 0,
    scene: f64 = 0,
    ui: f64 = 0,
    present: f64 = 0,
};
pub var latest: Timings = .{};
var displayed: Timings = .{};
var accumulated: Timings = .{};
var frame_count: usize = 0;
var elapsed: f64 = 0;

/// Seconds measured on the CPU; presentation includes the frame-limit wait.
pub fn record(timings: Timings) void {
    latest = timings;
    inline for (std.meta.fields(Timings)) |field| {
        @field(accumulated, field.name) += @field(timings, field.name);
    }
    frame_count += 1;
    elapsed += timings.audio + timings.scene + timings.ui + timings.present;
    if (elapsed >= 0.25) {
        inline for (std.meta.fields(Timings)) |field| {
            @field(displayed, field.name) = @field(accumulated, field.name) * 1000 / @as(f64, @floatFromInt(frame_count));
        }
        accumulated = .{};
        frame_count = 0;
        elapsed = 0;
    }
}

fn badgeBounds() rl.Rectangle {
    return ui.rect(ui.width() - 212, 88, 196, 30);
}

fn panelBounds() rl.Rectangle {
    return ui.rect(@max(panel_margin, ui.width() - panel_width - panel_margin), 126, panel_width, panel_height);
}

pub fn pointerOverUi() bool {
    return ((config.Interface.show_fps or visible) and ui.hovered(badgeBounds())) or (visible and ui.hovered(panelBounds()));
}

pub fn frame() void {
    if (rl.isKeyPressed(.D)) visible = !visible;
}

pub fn render() void {
    if (!config.Interface.show_fps and !visible) return;
    const badge = badgeBounds();
    ui.card(badge);
    var counter_buffer: [64]u8 = undefined;
    const counter = std.fmt.bufPrintZ(&counter_buffer, "{d} FPS   {d:.1} ms   / D", .{ rl.GetFPS(), rl.GetFrameTime() * 1000 }) catch return;
    if (ui.button(badge, counter, visible, true)) visible = !visible;
    if (!visible) return;
    const panel = panelBounds();
    ui.card(panel);
    ui.label("Debug  /  D to close", panel.x + 12, panel.y + 12, 14, ui.text);

    const mouse = rl.GetMousePosition();
    const delta = rl.GetMouseDelta();
    const wheel = rl.GetMouseWheelMoveV();
    drawLine(panel, 38, "Audio / update: {d:.2} ms", .{displayed.audio});
    drawLine(panel, 60, "Scene: {d:.2} ms  UI: {d:.2} ms", .{ displayed.scene, displayed.ui });
    drawLine(panel, 82, "Present / wait: {d:.2} ms", .{displayed.present});
    drawLine(panel, 104, "Mouse: {d:.0}, {d:.0}  Move: {d:.0}, {d:.0}", .{ mouse.x, mouse.y, delta.x, delta.y });
    drawLine(panel, 126, "Wheel: {d:.1}, {d:.1}  Left: {}", .{ wheel.x, wheel.y, rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT) });
    drawLine(panel, 148, "Audio RMS: {d:.3}  Beat: {}", .{ processor.rms_energy, processor.on_beat });
    ui.label("CPU timings; wait includes the FPS limit", panel.x + 12, panel.y + 172, 10, ui.muted);
}

fn drawLine(panel: rl.Rectangle, y: f32, comptime format: []const u8, args: anytype) void {
    var buffer: [128]u8 = undefined;
    const line = std.fmt.bufPrintZ(&buffer, format, args) catch return;
    ui.label(line, panel.x + 12, panel.y + y, 12, ui.text);
}
