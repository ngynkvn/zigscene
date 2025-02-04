const std = @import("std");

const tracy = @import("tracy");

const music = @import("../audio/playback.zig");
const processor = @import("../audio/processor.zig");
const graphics = @import("../graphics.zig");
const gui = @import("../gui.zig");
const rl = @import("../raylib.zig");
const shader = @import("../shader/shader.zig");
const Config = @import("config.zig");
pub var screenWidth: c_int = Config.Window.width;
pub var screenHeight: c_int = Config.Window.height;
const APP_NAME = Config.Window.title;
const debug = @import("debug.zig");
const event = @import("event.zig");
const input = @import("input.zig");
const rgs = @embedFile("rgs");

pub const App = struct {
    t: f32 = 0,
    // Init sequence for the GUI / Window
    pub fn init(_: std.mem.Allocator) !App {
        // TODO: Options menu
        rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE | rl.FLAG_WINDOW_TRANSPARENT | rl.FLAG_WINDOW_TOPMOST);

        // Setup
        rl.InitWindow(screenWidth, screenHeight, APP_NAME);

        rl.InitAudioDevice();

        rl.GuiSetAlpha(0.8);
        rl.RayguiLoadStyle(rgs, rgs.len);
        if (try processArgs()) |path| {
            event.onFilenameInput(path);
        }

        rl.SetMasterVolume(Config.Audio.volume);
        // Init shader
        shader.init();
        return .{};
    }
    pub fn deinit(self: App) void {
        _ = self;
        rl.CloseAudioDevice();
        rl.CloseWindow(); // Close window and OpenGL context
    }

    fn processArgs() !?[]const u8 {
        var buffer: [256]u8 = @splat(0);
        var fba = std.heap.FixedBufferAllocator.init(&buffer);
        const allocator = fba.allocator();
        var args = try std.process.argsWithAllocator(allocator);
        return if (!args.skip()) null else args.next();
    }
    pub fn processInput(self: *App) void {
        _ = self;
        input.processInput();
    }
    pub fn processMusic(self: *App) void {
        _ = self;
        if (music.IsMusicStreamPlaying()) music.UpdateMusicStream();
    }
    pub fn render(self: *App) void {
        const center = rl.GetWorldToScreen(.{}, input.camera);
        const renderCtx = tracy.traceNamed(@src(), "Render");
        defer renderCtx.end();
        { // Begin texture rendering
            rl.BeginTextureMode(shader.sceneTexture);
            defer rl.EndTextureMode();
            rl.ClearBackground(.{ .a = @intFromFloat(@round(Config.Shader.alpha_factor * 255)) });
            { // Draw 2D Graphics
                const ctx = tracy.traceNamed(@src(), "2d");
                defer ctx.end();
                for (processor.curr_buffer, processor.curr_fft, 0..) |v, fv, i| {
                    graphics.WaveFormLine.render(.{ .y = center.y - 80 }, i, v);
                    graphics.WaveFormBar.render(center, i, v);
                    graphics.WaveFormLine.render(.{ .y = center.y * 2 }, i, fv.magnitude() * 0.15);
                    graphics.FFTSpectrum.render(center, i, fv.magnitude());
                }
            }
            { // Draw 3D graphics
                const ctx = tracy.traceNamed(@src(), "bubble");
                defer ctx.end();
                graphics.Bubble.render(input.camera, input.rot_offset, self.t);
            }
        }
        { // Begin draw
            const drawCtx = tracy.traceNamed(@src(), "draw");
            defer drawCtx.end();
            rl.BeginDrawing();
            defer rl.EndDrawing();
            // We need to double clear in case the background has transparency
            rl.ClearBackground(.{ .a = @intFromFloat(@round(Config.Shader.alpha_factor * 255)) });
            { // Begin shader drawing
                const ctx = tracy.traceNamed(@src(), "draw shader");
                defer ctx.end();
                rl.BeginShaderMode(shader.program);
                defer rl.EndShaderMode();
                rl.SetShaderValue(shader.program, shader.chromaFactorLoc, &Config.Shader.chroma_factor, rl.RL_SHADER_UNIFORM_FLOAT);
                rl.SetShaderValue(shader.program, shader.noiseFactorLoc, &Config.Shader.noise_factor, rl.RL_SHADER_UNIFORM_FLOAT);
                rl.DrawTextureRec(
                    shader.sceneTexture.texture,
                    .{
                        .width = @floatFromInt(shader.sceneTexture.texture.width),
                        .height = @floatFromInt(-shader.sceneTexture.texture.height),
                    },
                    .{},
                    .{},
                );
            }
            self.render_ui();
        }
    }
    pub fn render_ui(self: *App) void {
        _ = self;
        const ctx = tracy.traceNamed(@src(), "gui render");
        defer ctx.end();
        debug.render();
        gui.frame();
    }
};
