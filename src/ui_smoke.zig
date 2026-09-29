//! Render the editor at representative window sizes for visual QA.
const std = @import("std");
const rl = @import("raylib");
const App = @import("App.zig");
const config = @import("core/config.zig");
const gui = @import("gui.zig");
const State = @import("editor/State.zig");
const Presets = @import("editor/Presets.zig");

pub fn main() !void {
    State.initDefaults();
    config.Window.fps_limit = 60;
    config.Window.always_on_top = false;
    config.Audio.volume = 0;
    var app = App.create(.{});
    defer app.destroy();
    const io = std.Io.Threaded.global_single_threaded.io();
    try std.Io.Dir.cwd().createDirPath(io, ".tmp/ui-review");
    _ = try Presets.store.put(try Presets.Preset.capture(&app.script, "Studio baseline"), false);
    app.script.loadExample(.orbit);
    _ = try Presets.store.put(try Presets.Preset.capture(&app.script, "Spectral orbit"), false);
    app.script.unload();
    const sizes = .{ .{ 1024, 768, 100 }, .{ 640, 480, 100 }, .{ 1024, 768, 150 } };
    inline for (sizes) |size| {
        rl.SetWindowSize(size[0], size[1]);
        config.Interface.scale_percent = size[2];
        for ([_]gui.Tab{ .scalar, .color, .motion, .scene, .presets, .inspector, .settings }) |tab| {
            gui.onTabChange(tab);
            for (0..4) |_| app.frame();
            var path: [256]u8 = undefined;
            const filename = try std.fmt.bufPrintZ(&path, ".tmp/ui-review/{s}-{d}-{d}.png", .{ @tagName(tab), size[0], size[2] });
            rl.TakeScreenshot(filename.ptr);
        }
    }
}
