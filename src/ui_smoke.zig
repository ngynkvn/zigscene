//! Render the editor at representative window sizes for visual QA.
const std = @import("std");
const rl = @import("raylib");
const App = @import("App.zig");
const config = @import("core/config.zig");
const gui = @import("gui.zig");
const State = @import("editor/State.zig");
const Presets = @import("editor/Presets.zig");
const Looks = @import("editor/Looks.zig");

fn key(app: *App, code: c_int) void {
    rl.PlayAutomationEvent(.{ .type = 1, .params = .{ code, 0, 0, 0 } });
    app.frame();
    rl.PlayAutomationEvent(.{ .type = 2, .params = .{ code, 0, 0, 0 } });
    app.frame();
    rl.PlayAutomationEvent(.{ .type = 1, .params = .{ code, 0, 0, 0 } });
    app.frame();
}

fn click(app: *App, x: f32, y: f32) void {
    rl.PlayAutomationEvent(.{ .type = 7, .params = .{ @intFromFloat(x), @intFromFloat(y), 0, 0 } });
    rl.PlayAutomationEvent(.{ .type = 5, .params = .{ 0, 0, 0, 0 } });
    app.frame();
    rl.PlayAutomationEvent(.{ .type = 6, .params = .{ 0, 0, 0, 0 } });
    app.frame();
    rl.PlayAutomationEvent(.{ .type = 5, .params = .{ 0, 0, 0, 0 } });
    app.frame();
}

fn drag(app: *App, from: rl.Vector2, to: rl.Vector2) void {
    rl.PlayAutomationEvent(.{ .type = 7, .params = .{ @intFromFloat(from.x), @intFromFloat(from.y), 0, 0 } });
    rl.PlayAutomationEvent(.{ .type = 5, .params = .{ 0, 0, 0, 0 } });
    app.frame();
    rl.PlayAutomationEvent(.{ .type = 6, .params = .{ 0, 0, 0, 0 } });
    app.frame();
    for (1..9) |step| {
        const t = @as(f32, @floatFromInt(step)) / 8;
        rl.PlayAutomationEvent(.{ .type = 7, .params = .{ @intFromFloat(from.x + (to.x - from.x) * t), @intFromFloat(from.y + (to.y - from.y) * t), 0, 0 } });
        app.frame();
    }
    rl.PlayAutomationEvent(.{ .type = 5, .params = .{ 0, 0, 0, 0 } });
    app.frame();
}

fn screenshot(path: [*:0]const u8) !void {
    const pixels = rl.LoadImageFromScreen();
    defer rl.UnloadImage(pixels);
    if (!rl.ExportImage(pixels, path)) return error.ScreenshotFailed;
}

fn checkPerformance(app: *App) !void {
    // Restart the test track so editor QA cannot exhaust it before this check.
    app.audio.playFile(".tmp/ui-review/test-sweep.wav");
    config.Window.opacity = 0.6;
    const width = rl.GetScreenWidth();
    const height = rl.GetScreenHeight();
    gui.onTabChange(.presets);
    app.frame();
    key(app, rl.KEY_PAGE_DOWN);
    click(app, 136, 560); // Select the saved Orbit look.
    click(app, 122, 400); // Assign it to F2.
    if (Presets.store.cues[1] != Presets.store.find("Spectral orbit").?) return error.CueAssignmentFailed;
    try screenshot(".tmp/ui-review/performance-cues.png");
    click(app, 136, 490); // Restore the built-in look for the start of the set.
    if (app.script.runtime != null) return error.StartingLookDidNotLoad;
    config.Shader.alpha_factor = 0.4;
    var broken = Presets.store.items[0];
    broken.name_buffer = @splat(0);
    @memcpy(broken.name_buffer[0..11], "Missing Lua");
    const missing = ".tmp/ui-review/missing-cue.lua";
    @memcpy(broken.path_buffer[0..missing.len], missing);
    Presets.store.cues[2] = try Presets.store.put(broken, false);

    key(app, rl.KEY_F11);
    if (!app.performance.active or !app.script.watch_paused or !rl.IsCursorHidden() or app.applied_window_opacity != 1) return error.PresentationDidNotStart;
    if (config.Shader.alpha_factor != 0.4 or config.Window.opacity != 0.6) return error.PresentationChangedPreferences;
    if (app.script.last_frame.width != @as(f32, @floatFromInt(rl.GetScreenWidth())) or
        app.script.last_frame.height != @as(f32, @floatFromInt(rl.GetScreenHeight()))) return error.PresentationViewportClipped;

    key(app, rl.KEY_B);
    if (!app.performance.blackout) return error.BlackoutDidNotStart;
    key(app, rl.KEY_TWO);
    if (app.script.example != .orbit or app.script.runtime == null) return error.CueDidNotLoad;
    const orbit_alpha = config.Shader.alpha_factor;
    const orbit_revision = app.script.revision;
    key(app, rl.KEY_F3);
    if (app.script.revision != orbit_revision or app.script.runtime == null) return error.CueFailureReplacedLook;
    key(app, rl.KEY_P);
    if (!app.audio.isFilePlaying() or !app.performance.blackout) return error.PresentationChangedPlayback;
    const image = rl.LoadImageFromScreen();
    defer rl.UnloadImage(image);
    const pixels = rl.LoadImageColors(image);
    defer rl.UnloadImageColors(pixels);
    for (pixels[0..@intCast(image.width * image.height)]) |pixel| {
        if (pixel.r != 0 or pixel.g != 0 or pixel.b != 0) return error.BlackoutLeakedPixels;
    }
    try screenshot(".tmp/ui-review/performance-blackout.png");

    key(app, rl.KEY_B);
    if (app.performance.blackout) return error.BlackoutDidNotEnd;
    try screenshot(".tmp/ui-review/performance-orbit.png");
    key(app, rl.KEY_ESCAPE);
    if (app.performance.active or app.script.watch_paused or rl.IsCursorHidden()) return error.PresentationDidNotEnd;
    if (rl.WindowShouldClose() or rl.IsWindowState(rl.FLAG_BORDERLESS_WINDOWED_MODE)) return error.EditorWindowDidNotReturn;
    if (rl.GetScreenWidth() != width or rl.GetScreenHeight() != height or app.applied_window_opacity != 0.6 or
        config.Shader.alpha_factor != orbit_alpha) return error.PresentationChangedPreferences;
}

fn reviewCaptureMeter(app: *App) !void {
    // Feed the capture queue directly so QA never opens the microphone.
    const capture = @import("audio/capture.zig");
    const processor = @import("audio/processor.zig");
    app.audio.togglePlayback();
    capture.active = true;
    defer capture.active = false;
    processor.selectSource(.capture);
    defer processor.selectSource(.none);
    const sample_count = config.Audio.buffer_size * config.Audio.channels;
    const signal: [sample_count]f32 = @splat(0.25);
    for (0..4) |_| {
        processor.submitCapture(&signal);
        app.frame();
    }
    try screenshot(".tmp/ui-review/capture-meter.png");
    const full_scale: [sample_count]f32 = @splat(-1);
    rl.SetWindowSize(640, 480);
    for (0..4) |_| {
        processor.submitCapture(&full_scale);
        app.frame();
    }
    try screenshot(".tmp/ui-review/capture-meter-clipping.png");
}

// Generate audio only for this QA executable; the application bundles no audio.
fn writeTestTrack(path: [*:0]const u8) !void {
    const sample_rate = 22050;
    const samples = try std.heap.page_allocator.alloc(i16, sample_rate * 8);
    defer std.heap.page_allocator.free(samples);
    for (samples, 0..) |*sample, i| {
        const t = @as(f64, @floatFromInt(i)) / sample_rate;
        const envelope = @exp(-5 * @mod(t, 0.5));
        sample.* = @intFromFloat(6000 * envelope * @sin(2 * std.math.pi * (110 * t + 40 * t * t)));
    }
    const wave: rl.Wave = .{ .frameCount = @intCast(samples.len), .sampleRate = sample_rate, .sampleSize = 16, .channels = 1, .data = samples.ptr };
    if (!rl.ExportWave(wave, path)) return error.TestTrackFailed;
}

pub fn main() !void {
    State.initDefaults();
    config.Window.fps_limit = 60;
    if (config.Window.always_on_top) return error.TopmostDefaultFailed;
    config.Shader.alpha_factor = 0.3; // Simulate a saved translucent background.
    config.Audio.volume = 0;
    var app = App.create(.{});
    defer app.destroy();
    if (config.Shader.alpha_factor != 1 or rl.IsWindowState(rl.FLAG_WINDOW_TOPMOST)) return error.StartupPresentationFailed;
    const io = std.Io.Threaded.global_single_threaded.io();
    try std.Io.Dir.cwd().createDirPath(io, ".tmp/ui-review");
    for (0..30) |_| app.frame();
    try screenshot(".tmp/ui-review/welcome.png");
    if (app.audio.hasFile() or app.audio.isFilePlaying()) return error.UnexpectedStartupAudio;
    try writeTestTrack(".tmp/ui-review/test-sweep.wav");
    app.audio.playFile(".tmp/ui-review/test-sweep.wav");
    for (0..120) |_| {
        app.frame();
        if (app.audio.waveform().len > 0) break;
    }
    if (!app.audio.hasFile() or !app.audio.isFilePlaying() or app.audio.waveform().len == 0) return error.FilePlaybackFailed;
    key(&app, rl.KEY_SPACE);
    if (app.audio.isFilePlaying()) return error.PlaybackShortcutFailed;
    key(&app, rl.KEY_SPACE);
    if (!app.audio.isFilePlaying()) return error.PlaybackShortcutFailed;
    gui.onTabChange(.presets);
    app.frame();
    click(&app, 160, 222); // Pulse starter card.
    if (!config.Scene.wave_lines or config.Scene.halo) return error.StarterLookFailed;
    State.history.undo(&app.script);
    if (!config.Scene.halo or config.Scene.wave_lines) return error.LookUndoFailed;
    click(&app, 700, 150); // Canvas clears keyboard focus.
    key(&app, rl.KEY_TAB);
    if (!@import("gui/theme.zig").keyboardActive()) return error.KeyboardFocusFailed;
    key(&app, rl.KEY_SPACE); // Activates the focused control, without pausing audio.
    if (!app.audio.isFilePlaying()) return error.KeyboardFocusFailed;
    try Looks.preset(.calm).apply(&app.script);
    @import("gui/StudioPanel.zig").resetWorkspace();
    click(&app, 700, 150);
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
            const filename = try std.mem.printSentinel(&path, ".tmp/ui-review/{s}-{d}-{d}.png", .{ @tagName(tab), size[0], size[2] }, 0);
            try screenshot(filename.ptr);
        }
        inline for (.{ Looks.Kind.pulse, Looks.Kind.sculpture }) |kind| {
            try Looks.preset(kind).apply(&app.script);
            gui.onTabChange(.presets);
            for (0..8) |_| app.frame();
            var path: [256]u8 = undefined;
            const filename = try std.mem.printSentinel(&path, ".tmp/ui-review/{s}-{d}-{d}.png", .{ @tagName(kind), size[0], size[2] }, 0);
            try screenshot(filename.ptr);
        }
        app.script.loadExample(.sculpture);
        gui.onTabChange(.scene);
        for (0..8) |_| app.frame();
        var path: [256]u8 = undefined;
        const filename = try std.mem.printSentinel(&path, ".tmp/ui-review/lua-{d}-{d}.png", .{ size[0], size[2] }, 0);
        try screenshot(filename.ptr);
        try Looks.preset(.calm).apply(&app.script);
    }
    rl.SetWindowSize(1024, 768);
    config.Interface.scale_percent = 100;
    gui.onTabChange(.inspector);
    for (0..4) |_| app.frame();
    if (app.input.halo_tilt.w != 1) return error.HaloTiltFailed; // Canvas clicks alone must not turn it.
    drag(&app, .{ .x = 640, .y = 420 }, .{ .x = 720, .y = 340 });
    if (app.input.halo_tilt.w > 0.95 or app.input.halo_drag) return error.HaloTiltFailed;
    try screenshot(".tmp/ui-review/halo-tilt.png");
    click(&app, 970, 63); // Fit scene.
    app.frame();
    if (app.input.halo_tilt.w != 1) return error.HaloTiltFailed;
    try checkPerformance(&app);
    try reviewCaptureMeter(&app);
    std.debug.print("Editor, playback, cue assignment and switching, fullscreen and blackout checks passed.\n", .{});
}
