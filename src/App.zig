const App = @This();
const std = @import("std");
const tracy = @import("tracy");

const AudioSession = @import("audio/Session.zig");
const processor = @import("audio/processor.zig");
const Config = @import("core/config.zig");
const cli = @import("core/cli.zig");
const debug = @import("core/debug.zig");
const init = @import("core/init.zig");
const input_mod = @import("core/input.zig");
const graphics = @import("graphics.zig");
const gui = @import("gui.zig");
const rl = @import("raylib.zig");
const Renderer = @import("shader/shader.zig").Renderer;
const Highlight = @import("graphics/Highlight.zig");
const Motion = @import("graphics/Motion.zig");
const ScriptScene = @import("scripting/Scene.zig");
const audio_hold_seconds: f32 = 0.12;

input: input_mod.State = .{},
audio: AudioSession = .{},
script: ScriptScene = .{},
spectrum: [Config.Audio.buffer_size / 2]f32 = @splat(0),
renderer: Renderer,
elapsed: f32 = 0,
seconds_since_audio: f32 = 0,
motion: Motion = .{},
halo: graphics.Halo = .{},
wave_bars: graphics.WaveFormBar = .{},
applied_window_opacity: f32 = -1,
applied_fps_limit: i32 = -1,
applied_always_on_top: ?bool = null,

pub fn create(options: cli.Options) App {
    init.startup();
    var app: App = .{ .renderer = .init() };
    app.applyWindowOpacity();
    app.applyFpsLimit();
    app.applyOptions(options);
    return app;
}

pub fn destroy(self: *App) void {
    self.script.deinit();
    self.audio.shutdown();
    self.renderer.deinit();
    gui.deinit();
    init.shutdown();
    self.* = undefined;
}

pub fn run(self: *App) void {
    while (!rl.WindowShouldClose()) self.frame();
}

fn applyOptions(self: *App, options: cli.Options) void {
    if (options.scene_path) |path| {
        self.script.loadFile(path);
        gui.onTabChange(.scene);
    }
    if (options.list_audio_devices) AudioSession.listDevices();
    if (options.file) |path| self.audio.playFile(path);
    if (options.capture_mode) |mode| {
        self.audio.startCapture(mode, options.capture_device) catch {};
    }
}

pub fn frame(self: *App) void {
    defer tracy.frameMarkNamed("zigscene");
    const frame_start = rl.rl.GetTime();
    const dt = rl.GetFrameTime();
    self.audio.update();
    @import("gui/theme.zig").updateScale();
    if (input_mod.process(&self.input, &self.audio, &self.script)) |size| self.renderer.resize(size.width, size.height);
    if (processor.update()) self.seconds_since_audio = 0 else self.seconds_since_audio += dt;
    self.motion.update(dt, if (self.seconds_since_audio < audio_hold_seconds) processor.rms_energy else 0, processor.on_beat);
    for (&self.spectrum, processor.curr_fft[0..self.spectrum.len]) |*value, frequency| value.* = frequency.magnitude() / @as(f32, @floatFromInt(Config.Audio.buffer_size));
    const mouse = rl.GetMousePosition();
    const over_ui = gui.pointerOverUi();
    self.script.update(.{
        .width = @floatFromInt(rl.GetScreenWidth()),
        .height = @floatFromInt(rl.GetScreenHeight()),
        .time = self.elapsed,
        .dt = dt,
        .rms = processor.rms_energy,
        .energy = self.motion.energy,
        .pulse = self.motion.pulse,
        .beat = @intFromBool(processor.on_beat),
        .playing = @intFromBool(self.audio.isFilePlaying()),
        .capturing = @intFromBool(self.audio.captureActive()),
        .progress = if (self.audio.hasFile() and !self.audio.captureActive() and self.audio.timeLength() > 0) std.math.clamp(self.audio.timePlayed() / self.audio.timeLength(), 0, 1) else 0,
        .samples = processor.curr_buffer.ptr,
        .sample_count = processor.curr_buffer.len,
        .spectrum = &self.spectrum,
        .spectrum_count = self.spectrum.len,
        .mouse_x = mouse.x,
        .mouse_y = mouse.y,
        .wheel = if (over_ui) 0 else rl.GetMouseWheelMoveV().y,
        .mouse_down = @intFromBool(!over_ui and rl.IsMouseButtonDown(rl.rl.MOUSE_BUTTON_LEFT)),
    });
    gui.prepareScene(&self.script);
    if (self.script.usesBuiltin()) {
        self.halo.update(dt, processor.curr_fft);
        self.wave_bars.advance(dt);
    }
    const center = rl.GetWorldToScreen(.{}, self.input.camera);

    const render_context = tracy.traceNamed(@src(), "Render");
    defer render_context.end();
    const audio_end = rl.rl.GetTime();
    self.renderScene(center);
    const scene_end = rl.rl.GetTime();
    const ui_end = self.renderWindow();
    debug.record(.{ .audio = audio_end - frame_start, .scene = scene_end - audio_end, .ui = ui_end - scene_end, .present = rl.rl.GetTime() - ui_end });
    self.applyWindowOpacity();
    self.applyFpsLimit();
    self.applyAlwaysOnTop();
    self.elapsed += dt;
}

fn applyAlwaysOnTop(self: *App) void {
    if (@import("builtin").os.tag == .emscripten) return;
    if (self.applied_always_on_top == Config.Window.always_on_top) return;
    if (Config.Window.always_on_top) rl.rl.SetWindowState(rl.FLAG_WINDOW_TOPMOST) else rl.rl.ClearWindowState(rl.FLAG_WINDOW_TOPMOST);
    self.applied_always_on_top = Config.Window.always_on_top;
}

fn applyFpsLimit(self: *App) void {
    const limit: i32 = @intFromFloat(@round(std.math.clamp(Config.Window.fps_limit, 0, 360)));
    if (limit == self.applied_fps_limit) return;
    rl.SetTargetFPS(limit);
    self.applied_fps_limit = limit;
}

fn applyWindowOpacity(self: *App) void {
    const opacity = std.math.clamp(Config.Window.opacity, 0.15, 1.0);
    Config.Window.opacity = opacity;
    if (opacity == self.applied_window_opacity) return;
    rl.SetWindowOpacity(opacity);
    self.applied_window_opacity = opacity;
}

fn renderScene(self: *App, center: rl.Vector2) void {
    const focus = Highlight.init(gui.hoveredElement());
    rl.BeginTextureMode(self.renderer.scene_texture);
    defer rl.EndTextureMode();
    rl.ClearBackground(.{});
    if (self.script.usesBuiltin()) self.renderBuiltin(center, focus);
    self.script.render(self.input.camera);
}

fn renderBuiltin(self: *App, center: rl.Vector2, focus: Highlight) void {
    if (Config.Scene.halo) self.halo.render(center, self.motion.energy, self.motion.pulse, focus);

    {
        const context = tracy.traceNamed(@src(), "2d");
        defer context.end();
        for (processor.curr_buffer, processor.curr_fft, 0..) |value, frequency, i| {
            if (Config.Scene.wave_lines) {
                graphics.WaveFormLine.render(.{ .y = center.y - 80 }, i, value, focus);
                graphics.WaveFormLine.render(
                    .{ .y = center.y * 2 },
                    i,
                    frequency.magnitude() / @as(f32, @floatFromInt(processor.curr_fft.len)) * 1.2,
                    focus,
                );
            }
            if (Config.Scene.wave_bars) self.wave_bars.render(center, i, value, focus);
            if (Config.Scene.spectrum) graphics.FFTSpectrum.render(center, i, frequency.magnitude(), focus);
        }
    }
    {
        const context = tracy.traceNamed(@src(), "3d");
        defer context.end();
        if (Config.Scene.bubble) graphics.Bubble.render(self.input.camera, self.input.rotation_offset, self.elapsed, self.motion.energy, self.motion.pulse, focus);
    }
}

fn renderWindow(self: *App) f64 {
    rl.BeginDrawing();
    var background = @import("gui/theme.zig").background;
    background.a = @intFromFloat(@round(Config.Shader.alpha_factor * 255));
    rl.ClearBackground(background);

    rl.BeginShaderMode(self.renderer.program);
    rl.SetShaderValue(self.renderer.program, self.renderer.chroma_factor_location, &Config.Shader.chroma_factor, rl.RL_SHADER_UNIFORM_FLOAT);
    rl.SetShaderValue(self.renderer.program, self.renderer.noise_factor_location, &Config.Shader.noise_factor, rl.RL_SHADER_UNIFORM_FLOAT);
    rl.DrawTextureRec(
        self.renderer.scene_texture.texture,
        .{
            .width = @floatFromInt(self.renderer.scene_texture.texture.width),
            .height = @floatFromInt(-self.renderer.scene_texture.texture.height),
        },
        .{},
        rl.WHITE,
    );
    rl.EndShaderMode();

    @import("gui/theme.zig").beginDrawing();
    gui.frame(&self.audio, &self.script);
    debug.render();
    @import("gui/theme.zig").endDrawing();
    const present_start = rl.rl.GetTime();
    rl.EndDrawing();
    return present_start;
}
