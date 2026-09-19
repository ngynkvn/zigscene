const App = @This();
const std = @import("std");
const tracy = @import("tracy");

const capture = @import("audio/capture.zig");
const playback = @import("audio/playback.zig");
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
const Motion = @import("graphics/Motion.zig");

input: input_mod.State = .{},
renderer: Renderer,
elapsed: f32 = 0,
seconds_since_audio: f32 = 0,
motion: Motion = .{},
halo: graphics.Halo = .{},
wave_bars: graphics.WaveFormBar = .{},
applied_window_opacity: f32 = -1,

pub fn create(options: cli.Options) App {
    init.startup();
    var app: App = .{ .renderer = .init() };
    app.applyWindowOpacity();
    app.applyOptions(options);
    return app;
}

pub fn destroy(self: *App) void {
    self.renderer.deinit();
    init.shutdown();
    self.* = undefined;
}

pub fn run(self: *App) void {
    while (!rl.WindowShouldClose()) self.frame();
}

fn applyOptions(self: *App, options: cli.Options) void {
    _ = self;
    if (options.list_audio_devices) capture.listDevices();
    if (options.file) |path| playback.onFilenameInput(path);
    if (options.capture_mode) |mode| {
        if (rl.IsMusicValid(playback.music)) rl.PauseMusicStream(playback.music);
        capture.start(mode, options.capture_device) catch {
            if (rl.IsMusicValid(playback.music)) rl.ResumeMusicStream(playback.music);
        };
    }
}

fn frame(self: *App) void {
    defer tracy.frameMarkNamed("zigscene");
    const dt = rl.GetFrameTime();
    if (playback.IsMusicStreamPlaying()) playback.UpdateMusicStream();
    if (input_mod.process(&self.input)) |size| self.renderer.resize(size.width, size.height);
    if (processor.update()) self.seconds_since_audio = 0 else self.seconds_since_audio += dt;
    self.motion.update(dt, if (self.seconds_since_audio < 0.12) processor.rms_energy else 0, processor.on_beat);
    self.halo.update(dt, processor.curr_fft);
    self.wave_bars.advance(dt);
    const center = rl.GetWorldToScreen(.{}, self.input.camera);

    const render_context = tracy.traceNamed(@src(), "Render");
    defer render_context.end();
    self.renderScene(center);
    self.renderWindow();
    self.applyWindowOpacity();
    self.elapsed += dt;
}

fn applyWindowOpacity(self: *App) void {
    const opacity = std.math.clamp(Config.Window.opacity, 0.15, 1.0);
    Config.Window.opacity = opacity;
    if (opacity == self.applied_window_opacity) return;
    rl.SetWindowOpacity(opacity);
    self.applied_window_opacity = opacity;
}

fn renderScene(self: *App, center: rl.Vector2) void {
    rl.BeginTextureMode(self.renderer.scene_texture);
    defer rl.EndTextureMode();
    rl.ClearBackground(.{});
    if (Config.Scene.halo) self.halo.render(center, self.motion.energy, self.motion.pulse);

    {
        const context = tracy.traceNamed(@src(), "2d");
        defer context.end();
        for (processor.curr_buffer, processor.curr_fft, 0..) |value, frequency, i| {
            if (Config.Scene.wave_lines) {
                graphics.WaveFormLine.render(.{ .y = center.y - 80 }, i, value);
                graphics.WaveFormLine.render(
                    .{ .y = center.y * 2 },
                    i,
                    frequency.magnitude() / @as(f32, @floatFromInt(processor.curr_fft.len)) * 1.2,
                );
            }
            if (Config.Scene.wave_bars) self.wave_bars.render(center, i, value);
            if (Config.Scene.spectrum) graphics.FFTSpectrum.render(center, i, frequency.magnitude());
        }
    }
    {
        const context = tracy.traceNamed(@src(), "3d");
        defer context.end();
        if (Config.Scene.bubble) graphics.Bubble.render(self.input.camera, self.input.rotation_offset, self.elapsed, self.motion.energy, self.motion.pulse);
    }
}

fn renderWindow(self: *App) void {
    rl.BeginDrawing();
    defer rl.EndDrawing();
    rl.ClearBackground(.{ .a = @intFromFloat(@round(Config.Shader.alpha_factor * 255)) });

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

    debug.render();
    gui.frame();
}
