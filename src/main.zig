const tracy = @import("tracy");

const music = @import("audio/playback.zig");
const processor = @import("audio/processor.zig");
const Config = @import("core/config.zig");
const debug = @import("core/debug.zig");
const apprt = @import("core/apprt.zig");
const shader = @import("shader/shader.zig");
const input = @import("core/input.zig");
const graphics = @import("graphics.zig");
const gui = @import("gui.zig");
const rl = @import("raylib.zig");

pub var isFullScreen = false;

pub fn main() !void {
    var t: f32 = 0.0;

    var app = try apprt.App.init();
    defer app.deinit();

    // Init shader
    shader.init();

    // Main loop
    // Detects window close button or ESC key
    while (!rl.WindowShouldClose()) {
        defer tracy.frameMarkNamed("zigscene");
        app.processMusic();
        app.processInput();
        const center = rl.GetWorldToScreen(.{}, input.camera3d);

        {
            const renderCtx = tracy.traceNamed(@src(), "Render");
            defer renderCtx.end();
            { // Begin texture rendering
                rl.BeginTextureMode(shader.sceneTexture);
                defer rl.EndTextureMode();
                rl.ClearBackground(.{});
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
                    graphics.Bubble.render(input.camera3d, input.rot_offset, t);
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
                        rl.WHITE,
                    );
                }
                { // Begin Gui Render
                    const ctx = tracy.traceNamed(@src(), "gui render");
                    defer ctx.end();
                    debug.render();
                    gui.frame();
                }
            }
            t += rl.GetFrameTime();
        }
    }
}

test "root" {
    _ = music;
    _ = processor;
    _ = graphics;
    _ = gui;
    _ = debug;
    _ = Config;
}
