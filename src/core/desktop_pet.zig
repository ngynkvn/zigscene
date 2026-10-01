//! Session-only presentation mode. It never overwrites saved host settings.
const std = @import("std");
const builtin = @import("builtin");
const rl = @import("../raylib.zig").rl;
const ui = @import("../gui/theme.zig");
const win = struct {
    const POINT = extern struct { x: i32, y: i32 };
    extern "user32" fn GetCursorPos(point: *POINT) callconv(.winapi) i32;
};
const glfw = struct {
    const Window = opaque {};
    extern fn glfwGetCurrentContext() ?*Window;
    extern fn glfwGetCursorPos(window: *Window, x: *f64, y: *f64) void;
};

pub const size = 400;
pub var enabled = false;
var controls_open = false;
var pet_position: rl.Vector2 = .{};
var control_size: rl.Vector2 = .{ .x = 1024, .y = 768 };
var drag_mouse: ?rl.Vector2 = null;
var drag_window: rl.Vector2 = .{};
var toggle_on_release = false;

pub fn init(requested: bool) void {
    enabled = requested and builtin.os.tag != .emscripten;
    controls_open = false;
    drag_mouse = null;
    toggle_on_release = false;
}

pub fn compact() bool {
    return enabled and !controls_open;
}

pub fn place() void {
    if (!enabled) return;
    const monitor = rl.GetCurrentMonitor();
    const origin = rl.GetMonitorPosition(monitor);
    move(.{
        .x = origin.x + @as(f32, @floatFromInt(rl.GetMonitorWidth(monitor))) - size - 32,
        .y = origin.y + @as(f32, @floatFromInt(rl.GetMonitorHeight(monitor))) - size - 72,
    });
    rl.SetWindowTitle("zigscene pet - Right-click: controls / Esc: quit");
}

fn move(position: rl.Vector2) void {
    rl.SetWindowPosition(@intFromFloat(@round(position.x)), @intFromFloat(@round(position.y)));
}

pub fn openControls() void {
    if (!compact()) return;
    pet_position = rl.GetWindowPosition();
    drag_mouse = null;
    controls_open = true;
    rl.ClearWindowState(rl.FLAG_WINDOW_UNDECORATED);
    rl.SetWindowState(rl.FLAG_WINDOW_RESIZABLE);
    rl.SetWindowMinSize(640, 480);
    const monitor = rl.GetCurrentMonitor();
    const origin = rl.GetMonitorPosition(monitor);
    const available = rl.Vector2{ .x = @floatFromInt(rl.GetMonitorWidth(monitor)), .y = @floatFromInt(rl.GetMonitorHeight(monitor)) };
    control_size.x = @min(control_size.x, available.x);
    control_size.y = @min(control_size.y, @max(480, available.y - 80));
    rl.SetWindowSize(@intFromFloat(control_size.x), @intFromFloat(control_size.y));
    move(fitPosition(pet_position, control_size, origin, available));
    rl.SetWindowTitle("zigscene controls - Right-click the scene to return to pet");
}

fn closeControls() void {
    if (rl.IsWindowState(rl.FLAG_BORDERLESS_WINDOWED_MODE)) rl.ToggleBorderlessWindowed();
    if (rl.IsWindowMaximized()) rl.RestoreWindow();
    control_size = .{ .x = @floatFromInt(rl.GetScreenWidth()), .y = @floatFromInt(rl.GetScreenHeight()) };
    controls_open = false;
    drag_mouse = null;
    rl.SetWindowMinSize(size, size);
    rl.ClearWindowState(rl.FLAG_WINDOW_RESIZABLE);
    rl.SetWindowState(rl.FLAG_WINDOW_UNDECORATED);
    rl.SetWindowSize(size, size);
    move(pet_position);
    rl.SetWindowTitle("zigscene pet - Right-click: controls / Esc: quit");
}

/// Returns true when the controls window changes state.
pub fn process(over_controls: bool) bool {
    if (!enabled) return false;
    // Controls use right-click for resets and saving swatches. Only the scene
    // background closes the controls; the compact pet can be clicked anywhere.
    if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_RIGHT)) toggle_on_release = compact() or !over_controls;
    if (rl.IsMouseButtonReleased(rl.MOUSE_BUTTON_RIGHT)) {
        const toggle = toggle_on_release;
        toggle_on_release = false;
        if (toggle) {
            // Open on release so the same press cannot reset a newly exposed
            // control or overwrite a swatch underneath the cursor.
            if (controls_open) closeControls() else openControls();
            return true;
        }
    }
    if (!compact()) return false;
    if (!rl.IsWindowFocused() or !rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) {
        drag_mouse = null;
        return false;
    }
    const position = rl.GetWindowPosition();
    const global = screenMouse(position) orelse {
        drag_mouse = null;
        return false;
    };
    if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
        drag_mouse = global;
        drag_window = position;
    }
    if (drag_mouse) |start| move(.{ .x = drag_window.x + global.x - start.x, .y = drag_window.y + global.y - start.y });
    return false;
}

fn screenMouse(position: rl.Vector2) ?rl.Vector2 {
    if (builtin.os.tag == .windows) {
        // Window movement can leave raylib's last mouse event stale. Query the
        // screen position directly so a stationary cursor cannot repeat a drag.
        var point: win.POINT = undefined;
        if (win.GetCursorPos(&point) == 0) return null;
        return .{ .x = @floatFromInt(point.x), .y = @floatFromInt(point.y) };
    }
    const window = glfw.glfwGetCurrentContext() orelse return null;
    var x: f64 = 0;
    var y: f64 = 0;
    glfw.glfwGetCursorPos(window, &x, &y);
    return .{ .x = position.x + @as(f32, @floatCast(x)), .y = position.y + @as(f32, @floatCast(y)) };
}

pub fn drawHint() void {
    if (!rl.IsCursorOnScreen() or drag_mouse != null) return;
    const bounds = ui.rect(16, size - 42, size - 32, 26);
    ui.rounded(bounds, 7, ui.surface);
    ui.centered("Drag to move  /  Right-click: controls", bounds, 13, ui.muted);
}

fn fitPosition(position: rl.Vector2, window: rl.Vector2, origin: rl.Vector2, monitor: rl.Vector2) rl.Vector2 {
    return .{
        .x = std.math.clamp(position.x, origin.x, origin.x + @max(0, monitor.x - window.x)),
        .y = std.math.clamp(position.y, origin.y + 32, origin.y + @max(32, monitor.y - window.y - 48)),
    };
}

test "expanded controls fit the monitor, including monitors left of the primary" {
    const position = fitPosition(.{ .x = -100, .y = 1000 }, .{ .x = 1024, .y = 768 }, .{ .x = -1920, .y = 0 }, .{ .x = 1920, .y = 1080 });
    try std.testing.expectEqual(@as(f32, -1024), position.x);
    try std.testing.expectEqual(@as(f32, 264), position.y);
}
