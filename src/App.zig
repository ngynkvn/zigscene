const App = @This();
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

input: input_mod.State = .{},
renderer: Renderer,
elapsed: f32 = 0,

pub fn create(options: cli.Options) App {
    init.startup();
    var app: App = .{ .renderer = .init() };
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
    if (playback.IsMusicStreamPlaying()) playback.UpdateMusicStream();
    if (input_mod.process(&self.input)) |size| self.renderer.resize(size.width, size.height);
    processor.update();
    const center = rl.GetWorldToScreen(.{}, self.input.camera);

    const render_context = tracy.traceNamed(@src(), "Render");
    defer render_context.end();
    self.renderScene(center);
    self.renderWindow();
    self.elapsed += rl.GetFrameTime();
}

fn renderScene(self: *App, center: rl.Vector2) void {
    rl.BeginTextureMode(self.renderer.scene_texture);
    defer rl.EndTextureMode();
    rl.ClearBackground(.{});

    {
        const context = tracy.traceNamed(@src(), "2d");
        defer context.end();
        for (processor.curr_buffer, processor.curr_fft, 0..) |value, frequency, i| {
            graphics.WaveFormLine.render(.{ .y = center.y - 80 }, i, value);
            graphics.WaveFormBar.render(center, i, value);
            graphics.WaveFormLine.render(.{ .y = center.y * 2 }, i, frequency.magnitude() * 0.15);
            graphics.FFTSpectrum.render(center, i, frequency.magnitude());
        }
    }
    {
        const context = tracy.traceNamed(@src(), "3d");
        defer context.end();
        graphics.Bubble.render(self.input.camera, self.input.rotation_offset, self.elapsed);
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
