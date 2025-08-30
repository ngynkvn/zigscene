const std = @import("std");
const rl = @import("raylibz");

const tracy = @import("tracy");

const music = @import("../audio/playback.zig");
const processor = @import("../audio/processor.zig");
const graphics = @import("../graphics.zig");
const gui = @import("../gui.zig");
const shader = @import("../shader/shader.zig");
const Config = @import("config.zig");
pub var screenWidth: c_int = Config.Window.width;
pub var screenHeight: c_int = Config.Window.height;
const APP_NAME = Config.Window.title;
const debug = @import("debug.zig");
const event = @import("event.zig");
const input = @import("input.zig");

pub const App = struct {
    t: f32 = 0,
    // Init sequence for the GUI / Window
    pub fn init(_: std.mem.Allocator) !App {
        // TODO: Options menu
        rl.setConfigFlags(.{
            .window_resizable = true,
            .window_transparent = true,
            .window_topmost = true,
        });
        // Setup
        rl.Window.init(screenWidth, screenHeight, APP_NAME);
        rl.initAudioDevice();
        // rl.guiSetAlpha(0.8);
        // rl.RayguiDark();
        rl.setMasterVolume(Config.Audio.volume);

        if (try processArgs()) |path| {
            event.onFilenameInput(path);
        }
        shader.init();
        return .{};
    }
    pub fn deinit(_: App) void {
        rl.closeAudioDevice();
        rl.Window.close();
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
        const center = rl.getWorldToScreen(.{}, input.camera);
        const renderCtx = tracy.traceNamed(@src(), "Render");
        defer renderCtx.end();
        { // Begin texture rendering
            rl.beginTextureMode(shader.sceneTexture);
            defer rl.endTextureMode();
            rl.clearBackground(.{ .a = @intFromFloat(@round(Config.Shader.alpha_factor * 255)) });
            { // Draw 2D Graphics
                const ctx = tracy.traceNamed(@src(), "2d");
                defer ctx.end();
                const vs = processor.curr_buffer;
                var fvs: [2048]f32 = undefined;
                for (processor.curr_fft, fvs[0..processor.curr_fft.len]) |v, *fv| {
                    fv.* = v.magnitude();
                }
                graphics.WaveFormLine.render(center, vs);
                graphics.WaveFormBar.render(center, vs);
                graphics.WaveFormLine.render(center, &fvs);
                graphics.FFTSpectrum.render(center, &fvs);
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
            rl.beginDrawing();
            defer rl.endDrawing();
            // We need to double clear in case the background has transparency
            rl.clearBackground(.{ .a = @intFromFloat(@round(Config.Shader.alpha_factor * 255)) });
            { // Begin shader drawing
                const ctx = tracy.traceNamed(@src(), "draw shader");
                defer ctx.end();
                rl.beginShaderMode(shader.program);
                defer rl.endShaderMode();
                rl.setShaderValue(shader.program, shader.chromaFactorLoc, &Config.Shader.chroma_factor, rl.ShaderUniformDataType.float);
                rl.setShaderValue(shader.program, shader.noiseFactorLoc, &Config.Shader.noise_factor, rl.ShaderUniformDataType.float);
                rl.drawTextureRec(
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
