//! Value rows and sliders shared by every panel, with the pointer and keyboard
//! ownership they need: one slider drag and one numeric edit at a time.
const std = @import("std");
const rl = @import("raylib");
const State = @import("../editor/State.zig");
const Scene = @import("../scripting/Scene.zig");
const controls = @import("controls.zig");
const geometry = @import("geometry.zig");
const ui = @import("theme.zig");

/// Ids of the gestures that are not value rows.
pub const seek_id = 1000;
pub const volume_id = 1001;

/// The control that owns the current mouse drag, if any.
pub var active_slider: ?usize = null;
/// The value row whose number is being typed, if any.
pub var editing: ?usize = null;
var editing_buffer: [128]u8 = @splat(0);
/// The scene whose Lua-owned settings are locked; set each frame.
pub var script: ?*Scene = null;

fn rowVisible(y: f32, view: rl.Rectangle) bool {
    return y >= view.y and y + geometry.slider_top + geometry.slider_height <= view.y + view.height;
}

pub fn field(id: usize, label: [:0]const u8, value: *f32, range: [2]f32, view: rl.Rectangle, y: f32, hue: bool) void {
    const was_editing = editing == id;
    const locked = if (script) |scene| State.locked(value, scene) else false;
    const row_enabled = rowVisible(y, view) and !locked;
    if (!row_enabled and editing == id) editing = null;
    if (locked and active_slider == id) active_slider = null;
    var fitted_buffer: [256]u8 = undefined;
    ui.label(ui.fitted(label, 13, view.width - 116, &fitted_buffer), view.x + 8, y + 5, 13, if (locked) ui.faint else ui.secondary);
    if (row_enabled) ui.tooltip(ui.rect(view.x, y, view.width - 106, 24), label);
    if (!locked and State.changed(value)) rl.DrawCircleV(.{ .x = view.x + 2, .y = y + 11 }, 2, ui.accent);
    const box = ui.rect(view.x + view.width - 98, y, 64, 24);
    const focused = ui.focusable(0x10000000 + id, box, row_enabled);
    if (focused and editing == null) {
        const step = (range[1] - range[0]) / (if (rl.IsKeyDown(rl.KEY_LEFT_SHIFT) or rl.IsKeyDown(rl.KEY_RIGHT_SHIFT)) @as(f32, 1000) else 100);
        if (rl.IsKeyPressed(rl.KEY_LEFT) or rl.IsKeyPressedRepeat(rl.KEY_LEFT)) value.* -= step;
        if (rl.IsKeyPressed(rl.KEY_RIGHT) or rl.IsKeyPressedRepeat(rl.KEY_RIGHT)) value.* += step;
        if (rl.IsKeyPressed(rl.KEY_HOME)) value.* = range[0];
        if (rl.IsKeyPressed(rl.KEY_END)) value.* = range[1];
    }
    if (editing == id) {
        if (ui.valueBox(box, &editing_buffer, value) or rl.IsKeyPressed(rl.KEY_TAB) or
            (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT) and !ui.hovered(box))) editing = null;
    } else {
        var buf: [32]u8 = undefined;
        const number = if (locked) "Lua" else if (range[1] <= 2)
            std.mem.printSentinel(&buf, "{d:.3}", .{value.*}, 0) catch unreachable
        else
            std.mem.printSentinel(&buf, "{d:.1}", .{value.*}, 0) catch unreachable;
        const over_box = row_enabled and ui.hovered(box);
        ui.framed(box, 3, ui.field, if (over_box) ui.muted else ui.divider);
        ui.label(number, box.x + box.width - 8 - ui.textWidth(number, 12), box.y + 6, 12, if (locked) ui.faint else ui.text);
        if (over_box) {
            ui.requestCursor(rl.MOUSE_CURSOR_IBEAM);
            if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
                editing = id;
                @memset(&editing_buffer, 0);
                _ = std.mem.printSentinel(&editing_buffer, "{d:.3}", .{value.*}, 0) catch unreachable;
            }
        }
    }
    if (focused and !was_editing and editing == null and rl.IsKeyPressed(rl.KEY_ENTER)) {
        editing = id;
        @memset(&editing_buffer, 0);
        _ = std.mem.printSentinel(&editing_buffer, "{d:.3}", .{value.*}, 0) catch unreachable;
    }
    // The reset icon appears only once a value differs from its default.
    const reset = ui.rect(view.x + view.width - 28, y, 24, 24);
    if (row_enabled and State.changed(value) and ui.iconButton(reset, .reset, "Reset this value to its default", false, true)) {
        if (script) |scene| State.reset(value, scene);
    }
    if (row_enabled) {
        ui.tooltip(box, "Enter a value; arrow keys adjust; Shift for finer steps");
        ui.tooltip(reset, "Reset this value to its default");
    }
    if (row_enabled and ui.hovered(ui.rect(view.x, y, view.width, geometry.row_height)) and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_RIGHT)) {
        if (script) |scene| State.reset(value, scene);
        editing = null;
    }
    _ = slider(id, ui.rect(view.x + 8, y + geometry.slider_top, view.width - 16, geometry.slider_height), value, range[0], range[1], row_enabled, hue);
    controls.constrainScalar(.{ label, value, .{ range[0], range[1] } });
}

/// A generous hit area around a slim track; drag ownership survives leaving it.
pub fn slider(id: usize, bounds: rl.Rectangle, value: *f32, min: f32, max: f32, enabled: bool, hue: bool) bool {
    // Host fields already register their numeric box. Standalone sliders
    // (volume and Lua parameters) need their own keyboard target.
    if ((id == volume_id or (id >= 4000 and id < 5000)) and ui.focusable(0x20000000 + id, bounds, enabled) and !ui.typing) {
        const step = (max - min) / (if (rl.IsKeyDown(rl.KEY_LEFT_SHIFT) or rl.IsKeyDown(rl.KEY_RIGHT_SHIFT)) @as(f32, 1000) else 100);
        if (rl.IsKeyPressed(rl.KEY_LEFT) or rl.IsKeyPressedRepeat(rl.KEY_LEFT)) value.* -= step;
        if (rl.IsKeyPressed(rl.KEY_RIGHT) or rl.IsKeyPressedRepeat(rl.KEY_RIGHT)) value.* += step;
        if (rl.IsKeyPressed(rl.KEY_HOME)) value.* = min;
        if (rl.IsKeyPressed(rl.KEY_END)) value.* = max;
        value.* = std.math.clamp(value.*, min, max);
    }
    const over = enabled and ui.hovered(bounds);
    if (over and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT) and active_slider == null) {
        active_slider = id;
        editing = null;
    }
    const dragging = active_slider == id;
    if (dragging and rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) {
        value.* = min + std.math.clamp((ui.mousePosition().x - bounds.x) / bounds.width, 0, 1) * (max - min);
    }
    if (over or dragging) ui.requestCursor(rl.MOUSE_CURSOR_POINTING_HAND);
    const ratio = if (max > min) std.math.clamp((value.* - min) / (max - min), 0, 1) else 0;
    const cy = bounds.y + bounds.height / 2;
    if (hue) {
        for (0..6) |i| {
            const x = bounds.x + @as(f32, @floatFromInt(i)) * bounds.width / 6;
            const a = rl.ColorFromHSV(@as(f32, @floatFromInt(i)) * 60, 0.7, 0.92);
            const b = rl.ColorFromHSV(@as(f32, @floatFromInt(i + 1)) * 60, 0.7, 0.92);
            rl.DrawRectangleGradientEx(ui.rect(x, cy - 2, bounds.width / 6 + 1, 4), a, a, b, b);
        }
    } else {
        ui.rounded(ui.rect(bounds.x, cy - 1.5, bounds.width, 3), 1.5, ui.selection);
        if (ratio > 0) ui.rounded(ui.rect(bounds.x, cy - 1.5, @max(3, bounds.width * ratio), 3), 1.5, if (enabled) ui.accent else ui.faint);
    }
    // A white knob with a dark ring stays legible over both track colors.
    const center = rl.Vector2{ .x = bounds.x + ratio * bounds.width, .y = cy };
    const radius: f32 = if (over or dragging) 6.5 else 5.5;
    if (dragging) rl.DrawCircleV(center, 11, rl.Fade(ui.accent, 0.2));
    rl.DrawCircleV(center, radius + 1, ui.hairline);
    rl.DrawCircleV(center, radius, if (enabled or dragging) ui.text else ui.muted);
    return dragging;
}
