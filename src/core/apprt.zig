const std = @import("std");
const rl = @import("raylibz");

const tracy = @import("tracy");

const music = @import("../audio/playback.zig");
const processor = @import("../audio/processor.zig");
const capture = @import("../audio/capture.zig");
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
const N = Config.Audio.buffer_size;
const deque = @import("../deque.zig");
const Deque = deque.Deque;

pub const App = struct {
    t: f32 = 0,
    allocator: std.mem.Allocator,
    events: Deque(event.Event),
    // Init sequence for the GUI / Window
    pub fn init(allocator: std.mem.Allocator) !App {
        // TODO: Options menu
        rl.setConfigFlags(.{
            .window_resizable = true,
            .window_transparent = true,
            // .window_topmost = true,
        });
        var app = App{
            .allocator = allocator,
            .events = Deque(event.Event).empty,
        };
        // Setup
        rl.Window.init(screenWidth, screenHeight, APP_NAME);
        rl.initAudioDevice();
        rl.rlc.RayguiDark();
        // rl.guiSetAlpha(0.8);
        // rl.RayguiDark();
        rl.setMasterVolume(Config.Audio.volume);

        if (try processArgs()) |path| {
            try app.events.pushBack(allocator, .{ .filename_input = path });
        }
        shader.init();
        return app;
    }

    pub fn executeCallbacks(self: *App) void {
        while (self.events.popFront()) |callback| {
            std.log.debug("callback: {any}", .{callback});
            switch (callback) {
                .filename_input => |path| {
                    music.onFilenameInput(path);
                },
                .tab_change => |tab| {
                    gui.onTabChange(tab);
                },
                .window_resize => |size| {
                    graphics.onWindowResize(size.width, size.height);
                },
                .toggle_capture => {
                    if (!capture.active) {
                        capture.init(0) catch {
                            std.log.err("Failed to init capture device", .{});
                            continue;
                        };
                        capture.start() catch {
                            std.log.err("Failed to start capture", .{});
                            continue;
                        };
                    } else {
                        capture.deinit();
                    }
                },
                .swipe => |swipe| {
                    _ = swipe;
                },
            }
        }
    }

    pub fn deinit(self: *App) void {
        if (capture.active) capture.deinit();
        rl.closeAudioDevice();
        rl.Window.close();
        self.events.deinit(self.allocator);
    }

    fn processArgs() !?[]const u8 {
        var buffer: [256]u8 = @splat(0);
        var fba = std.heap.FixedBufferAllocator.init(&buffer);
        const allocator = fba.allocator();
        var args = try std.process.argsWithAllocator(allocator);
        return if (!args.skip()) null else args.next();
    }
    pub fn processInput(self: *App) void {
        input.processInput(self);
    }
    pub fn processMusic(self: *App) void {
        _ = self;
        if (music.isMusicStreamPlaying()) music.updateMusicStream();
    }
    pub fn render(self: *App) void {
        const center = rl.getWorldToScreen(.{}, input.camera);
        const t = tracy.traceNamed(@src(), "Render");
        defer t.end();
        { // Begin texture rendering
            rl.beginTextureMode(shader.sceneTexture);
            defer rl.endTextureMode();
            rl.clearBackground(.{ .a = @intFromFloat(@round(Config.Shader.alpha_factor * 255)) });
            { // Draw 2D Graphics
                const t2 = tracy.traceNamed(@src(), "2d");
                defer t2.end();
                const vs = processor.curr_buffer;
                {
                    const t3 = tracy.traceNamed(@src(), "vs");
                    defer t3.end();
                    for (0..vs.len) |i| {
                        const v = vs[i];
                        graphics.WaveFormLine.render(center, i, v);
                        graphics.WaveFormBar.render(center, i, v);
                    }
                }
                for (0..processor.curr_fft.len) |i| {
                    const fv = processor.curr_fft[i].magnitude();
                    graphics.FFTSpectrum.render(center, i, fv);
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
            rl.beginDrawing();
            defer rl.endDrawing();
            // We need to double clear in case the background has transparency
            rl.clearBackground(.{ .a = @intFromFloat(@round(Config.Shader.alpha_factor * 255)) });
            { // Begin shader drawing
                const ctx = tracy.traceNamed(@src(), "draw shader");
                defer ctx.end();
                rl.beginShaderMode(shader.program);
                defer rl.endShaderMode();
                rl.setShaderValue(shader.program, shader.chromaFactorLoc, &Config.Shader.chroma_factor, .float);
                rl.setShaderValue(shader.program, shader.noiseFactorLoc, &Config.Shader.noise_factor, .float);
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
