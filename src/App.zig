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
const pet = @import("core/desktop_pet.zig");
const graphics = @import("graphics.zig");
const gui = @import("gui.zig");
const rl = @import("raylib.zig");
const Renderer = @import("shader/shader.zig").Renderer;
const Highlight = graphics.Highlight;
const Motion = @import("graphics/Motion.zig");
const ScriptScene = @import("scripting/Scene.zig");
const Viewport = graphics.Viewport;
/// Time constant for the scene sliding clear of the side panel.
const viewport_slide_seconds: f32 = 0.12;

preferences_path: ?[]const u8 = null,
input: input_mod.State = .{},
audio: AudioSession = .{},
script: ScriptScene = .{},
renderer: Renderer,
elapsed: f32 = 0,
/// Animated left inset of the scene viewport, in window pixels.
scene_left: f32 = 0,
motion: Motion = .{},
layers: graphics.Builtin = .{},
applied_window_opacity: f32 = -1,
applied_fps_limit: i32 = -1,
applied_always_on_top: ?bool = null,

pub fn create(options: cli.Options) App {
    // Normal launches start opaque even if the previous session was translucent.
    if (!options.desktop_pet) Config.Shader.alpha_factor = 1;
    init.startup(options.desktop_pet);
    var app: App = .{ .renderer = .init() };
    app.applyWindowOpacity();
    app.applyFpsLimit();
    app.applyOptions(options);
    if (pet.enabled and app.audio.notice != null) {
        pet.openControls();
        gui.onTabChange(.audio);
    }
    return app;
}

pub fn destroy(self: *App) void {
    self.script.deinit();
    @import("core/preferences.zig").save(self.preferences_path);
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
    if (gui.takeSettingsReset()) self.resetSettings();
    if (gui.takeFitRequest()) self.input = .{};
    const frame_start = rl.rl.GetTime();
    const dt = rl.GetFrameTime();
    self.audio.update();
    @import("gui/theme.zig").updateScale();
    if (pet.process(!pet.compact() and gui.pointerOverUi())) {
        gui.cancelInteraction(&self.audio, &self.script);
        processor.smoothing_held = false;
        if (pet.compact()) @import("gui/theme.zig").resetCursor();
        @import("gui/theme.zig").updateScale();
    }
    if (input_mod.process(&self.input, &self.audio, &self.script)) |size| self.renderer.resize(size.width, size.height);
    _ = processor.update(dt);
    self.motion.update(dt, processor.rms_energy, processor.on_beat);
    const viewport = self.updateViewport(dt);
    const mouse = rl.GetMousePosition();
    const over_ui = pet.compact() or gui.pointerOverUi();
    self.script.update(.{
        .width = viewport.width(),
        .height = viewport.height(),
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
        .spectrum = processor.spectrum.ptr,
        .spectrum_count = processor.spectrum.len,
        .mouse_x = mouse.x - viewport.left,
        .mouse_y = mouse.y - viewport.top,
        .wheel = if (over_ui) 0 else rl.GetMouseWheelMoveV().y,
        .mouse_down = @intFromBool(!over_ui and rl.IsMouseButtonDown(rl.rl.MOUSE_BUTTON_LEFT)),
    });
    gui.prepareScene(&self.script);
    const scene: graphics.Frame = .{
        .dt = dt,
        .time = self.elapsed,
        .samples = processor.curr_buffer,
        .spectrum = processor.spectrum,
        .energy = self.motion.energy,
        .pulse = self.motion.pulse,
        .viewport = viewport,
        .center = viewport.center(),
        .camera = self.input.camera,
        .rotation = self.input.rotation_offset,
        .halo_tilt = self.input.halo_tilt,
        .focus = Highlight.init(if (pet.compact()) null else gui.hoveredElement()),
    };
    if (self.script.usesBuiltin()) self.layers.update(scene);

    const render_context = tracy.traceNamed(@src(), "Render");
    defer render_context.end();
    const audio_end = rl.rl.GetTime();
    self.renderScene(scene);
    const scene_end = rl.rl.GetTime();
    const ui_end = self.renderWindow(viewport, scene.focus);
    debug.record(.{ .audio = audio_end - frame_start, .scene = scene_end - audio_end, .ui = ui_end - scene_end, .present = rl.rl.GetTime() - ui_end });
    self.applyWindowOpacity();
    self.applyFpsLimit();
    self.applyAlwaysOnTop();
    self.elapsed += dt;
}

fn resetSettings(self: *App) void {
    @import("editor/State.zig").resetAll(&self.script);
    self.input = .{};
    self.audio.endSeek();
    processor.smoothing_held = false;
    gui.resetWorkspace();
    @import("core/preferences.zig").save(self.preferences_path);
}

fn applyAlwaysOnTop(self: *App) void {
    if (@import("builtin").os.tag == .emscripten) return;
    const topmost = pet.compact() or Config.Window.always_on_top;
    if (self.applied_always_on_top == topmost) return;
    if (topmost) rl.rl.SetWindowState(rl.FLAG_WINDOW_TOPMOST) else rl.rl.ClearWindowState(rl.FLAG_WINDOW_TOPMOST);
    self.applied_always_on_top = topmost;
}

fn applyFpsLimit(self: *App) void {
    const requested = if (pet.compact() and Config.Window.fps_limit == 0) @as(f32, 60) else Config.Window.fps_limit;
    const limit: i32 = @intFromFloat(@round(std.math.clamp(requested, 0, 360)));
    if (limit == self.applied_fps_limit) return;
    rl.SetTargetFPS(limit);
    self.applied_fps_limit = limit;
}

fn applyWindowOpacity(self: *App) void {
    const opacity = if (pet.compact()) 1 else std.math.clamp(Config.Window.opacity, 0.15, 1.0);
    if (!pet.compact()) Config.Window.opacity = opacity;
    if (opacity == self.applied_window_opacity) return;
    rl.SetWindowOpacity(opacity);
    self.applied_window_opacity = opacity;
}

/// Slides the scene clear of the side panel; frame-rate independent.
fn updateViewport(self: *App, dt: f32) Viewport {
    const ui = @import("gui/theme.zig");
    const bounds = gui.sceneBounds();
    const target = bounds.x * ui.scale_factor;
    self.scene_left = if (pet.compact()) 0 else Viewport.slide(self.scene_left, target, dt, viewport_slide_seconds);
    return .{
        .left = self.scene_left,
        .top = if (pet.compact()) 0 else bounds.y * ui.scale_factor,
        .bottom = if (pet.compact()) 0 else (@as(f32, @floatFromInt(rl.GetScreenHeight())) - (bounds.y + bounds.height) * ui.scale_factor),
        .right = if (pet.compact()) 0 else @max(0, @as(f32, @floatFromInt(rl.GetScreenWidth())) - (bounds.x + bounds.width) * ui.scale_factor),
        .target_width = @floatFromInt(self.renderer.scene_texture.texture.width),
        .target_height = @floatFromInt(self.renderer.scene_texture.texture.height),
    };
}

fn renderScene(self: *App, scene: graphics.Frame) void {
    const viewport = scene.viewport;
    rl.BeginTextureMode(self.renderer.scene_texture);
    defer rl.EndTextureMode();
    rl.ClearBackground(.{});
    rl.rl.BeginScissorMode(@intFromFloat(viewport.left), @intFromFloat(viewport.top), @intFromFloat(viewport.width()), @intFromFloat(viewport.height()));
    defer rl.rl.EndScissorMode();
    viewport.begin();
    defer viewport.end();
    if (self.script.usesBuiltin()) self.layers.render(scene);
    self.script.render(scene.camera, viewport);
}

fn renderWindow(self: *App, viewport: Viewport, focus: Highlight) f64 {
    rl.BeginDrawing();
    var background = @import("gui/theme.zig").background;
    background.a = if (pet.compact()) 0 else @intFromFloat(@round(Config.Shader.alpha_factor * 255));
    rl.ClearBackground(background);

    if (!pet.compact() and self.script.usesBuiltin() and Highlight.Element.marbling.visible()) {
        const tint = focus.tint(.marbling, .{ .r = 255, .g = 255, .b = 255, .a = background.a });
        self.renderer.drawMarbling(viewport, self.motion, tint);
    }

    rl.BeginShaderMode(self.renderer.program);
    const noise: f32 = if (pet.compact()) 0 else Config.Shader.noise_factor;
    self.renderer.setUniforms(self.elapsed, noise);
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

    if (pet.compact()) {
        pet.drawHint();
    } else {
        @import("gui/theme.zig").beginDrawing();
        gui.frame(&self.audio, &self.script);
        debug.render();
        @import("gui/theme.zig").endDrawing();
    }
    const present_start = rl.rl.GetTime();
    rl.EndDrawing();
    return present_start;
}
