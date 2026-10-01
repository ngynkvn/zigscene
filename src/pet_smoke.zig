//! Exercise pet/editor transitions with raylib input events, without preferences.
const std = @import("std");
const rl = @import("raylib");
const App = @import("App.zig");
const config = @import("core/config.zig");
const pet = @import("core/desktop_pet.zig");
const gui = @import("gui.zig");
const State = @import("editor/State.zig");
const StudioPanel = @import("gui/StudioPanel.zig");

// Event IDs are raylib's AutomationEventType in rcore.c.
fn click(app: *App, x: i32, y: i32, button: c_int) void {
    rl.PlayAutomationEvent(.{ .type = 7, .params = .{ x, y, 0, 0 } });
    rl.PlayAutomationEvent(.{ .type = 6, .params = .{ button, 0, 0, 0 } });
    app.frame();
    rl.PlayAutomationEvent(.{ .type = 7, .params = .{ x, y, 0, 0 } });
    rl.PlayAutomationEvent(.{ .type = 5, .params = .{ button, 0, 0, 0 } });
    app.frame();
    for (0..4) |_| app.frame();
}

fn expect(condition: bool, description: []const u8) !void {
    if (!condition) {
        std.debug.print("Pet check failed: {s}\n", .{description});
        return error.PetCheckFailed;
    }
}

fn screenshot(path: [*:0]const u8) !void {
    // TakeScreenshot applies DPI twice in the current raylib revision.
    const pixels = rl.LoadImageFromScreen();
    defer rl.UnloadImage(pixels);
    if (!rl.ExportImage(pixels, path)) return error.ScreenshotFailed;
}

pub fn main() !void {
    State.initDefaults();
    config.Audio.volume = 0;
    config.Window.fps_limit = 0;
    config.Window.always_on_top = false;
    config.Window.opacity = 0.55;
    config.Shader.alpha_factor = 0.4;
    config.Shader.noise_factor = 0.2;
    config.Visualizer.WaveFormLine.amplitude = 81;
    var app = App.create(.{ .desktop_pet = true });
    defer app.destroy();
    const io = std.Io.Threaded.global_single_threaded.io();
    try std.Io.Dir.cwd().createDirPath(io, ".tmp/pet-check");
    for (0..4) |_| app.frame();
    try expect(pet.compact(), "start compact");
    try expect(app.renderer.scene_texture.texture.width == 400, "match initial render texture to pet");
    try expect(app.applied_fps_limit == 60 and config.Window.fps_limit == 0, "cap the pet without changing preferences");
    try expect(rl.IsWindowState(rl.FLAG_WINDOW_TOPMOST), "keep compact pet on top");
    try expect(app.applied_window_opacity == 1 and config.Window.opacity == 0.55, "preserve window opacity preference");
    try screenshot(".tmp/pet-check/compact.png");

    // This point covers the amplitude row after the controls expand. Opening
    // must not dispatch the same press to that row's right-click reset.
    click(&app, 100, 180, rl.MOUSE_BUTTON_RIGHT);
    try expect(!pet.compact(), "open controls with right-click");
    try expect(config.Visualizer.WaveFormLine.amplitude == 81, "opening must not reset an exposed control");
    try expect(app.renderer.scene_texture.texture.width == rl.GetScreenWidth(), "resize render texture with controls");
    try expect(!rl.IsWindowState(rl.FLAG_WINDOW_TOPMOST), "restore topmost preference in controls");
    try expect(app.applied_fps_limit == 0 and app.applied_window_opacity == 0.55, "restore presentation preferences");

    click(&app, 100, 180, rl.MOUSE_BUTTON_RIGHT);
    try expect(!pet.compact(), "right-click over controls must not close them");
    try expect(config.Visualizer.WaveFormLine.amplitude == 60, "right-click still resets the amplitude");
    gui.onTabChange(.presets);
    StudioPanel.text_editing = true;
    click(&app, 700, 200, rl.MOUSE_BUTTON_RIGHT);
    try expect(pet.compact() and !gui.editingValue(), "close controls and end text editing");
    try expect(config.Shader.alpha_factor == 0.4 and config.Shader.noise_factor == 0.2, "preserve shader preferences");
    click(&app, 100, 180, rl.MOUSE_BUTTON_RIGHT);
    try expect(!pet.compact(), "reopen controls");
    try screenshot(".tmp/pet-check/controls.png");

    gui.onTabChange(.settings);
    click(&app, 160, 146, rl.MOUSE_BUTTON_LEFT);
    try expect(config.Window.opacity == 1 and config.Shader.noise_factor == 0.005, "hard reset restores defaults");
    try expect(pet.enabled and !pet.compact(), "hard reset keeps the controls usable");
    click(&app, 700, 200, rl.MOUSE_BUTTON_RIGHT);
    try expect(pet.compact(), "return to pet after hard reset");
    std.debug.print("Desktop pet transitions, right-click resets, and preference isolation passed.\n", .{});
}
