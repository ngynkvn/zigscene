const std = @import("std");
const tracy = @import("tracy");

pub const rl = @import("raylib.zig");
pub const music = @import("audio/playback.zig");
pub const processor = @import("audio/processor.zig");
pub const graphics = @import("graphics.zig");
pub const shader = @import("shader/shader.zig");
pub const gui = @import("gui.zig");
pub const debug = @import("core/debug.zig");
pub const Config = @import("core/config.zig");
pub const init = @import("core/init.zig");
pub const event = @import("core/event.zig");

pub var isFullScreen = false;
var prevValue: f32 = 0;
var rot_offset: f32 = 0.0;
var camera3d: rl.Camera3D = .{
    // zig fmt: off
    .position   = Config.Camera.initial_position,       // Camera position
    .target     = Config.Camera.initial_target,         // Camera looking at point
    .up         = .{ .x = 0.0, .y = 1.0, .z = 0.0  },   // Camera up vector (rotation towards target)
    .fovy       = Config.Camera.fov,                    // Camera field-of-view Y
    .projection = rl.CAMERA_PERSPECTIVE,                // Camera projection type
    // zig fmt: on
};

pub fn main() !void {
    var t: f32 = 0.0;

    try init.startup();
    defer init.shutdown();

    // Init shader
    shader.init();

    // Main loop
    // Detects window close button or ESC key
    while (!rl.WindowShouldClose()) {
        defer tracy.frameMarkNamed("zigscene");
        if (music.IsMusicStreamPlaying()) music.UpdateMusicStream();
        processInput();
        const center = rl.GetWorldToScreen(.{}, camera3d);

        {
            const ctx = tracy.traceNamed(@src(), "Renders");
            defer ctx.end();

            // Drawing
            rl.BeginTextureMode(shader.sceneTexture);
            rl.ClearBackground(rl.BLACK);
            const ctx_2d = tracy.traceNamed(@src(), "2d");
            for (processor.curr_buffer, processor.curr_fft, 0..) |v, fv, i| {
                graphics.WaveFormLine.render(.{ .y = center.y - 80 }, i, v);
                graphics.WaveFormBar.render(center, i, v);
                graphics.WaveFormLine.render(.{ .y = center.y * 2 }, i, fv.magnitude() * 0.15);
                graphics.FFTSpectrum.render(center, i, fv.magnitude());
            }
            ctx_2d.end();
            graphics.Bubble.render(camera3d, rot_offset, t);
            rl.EndTextureMode();
            rl.BeginDrawing();
            rl.BeginShaderMode(shader.program);
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
            rl.EndShaderMode();
            debug.render();
            gui.frame();
            rl.EndDrawing();
            t += rl.GetFrameTime();
        }
    }
}

fn processInput() void {
    if (rl.IsFileDropped()) {
        const files = rl.LoadDroppedFiles();
        defer rl.UnloadDroppedFiles(files);
        const file = files.paths[0];
        const len = std.mem.len(file);
        event.onFilenameInput(file[0..len]);
    }

    if (rl.isKeyPressed(.C)) camera3d.projection = switch (camera3d.projection) {
        rl.CAMERA_PERSPECTIVE => rl.CAMERA_ORTHOGRAPHIC,
        rl.CAMERA_ORTHOGRAPHIC => rl.CAMERA_PERSPECTIVE,
        else => unreachable,
    };

    if (rl.isKeyPressed(.ONE)) {
        event.onTabChange(.none);
    } else if (rl.isKeyPressed(.TWO)) {
        event.onTabChange(.audio);
    } else if (rl.isKeyPressed(.THREE)) {
        event.onTabChange(.scalar);
    } else if (rl.isKeyPressed(.FOUR)) {
        event.onTabChange(.color);
    }

    // The key was not pressed before but it's down now
    if (rl.isKeyPressed(.SPACE)) {
        // :)
        prevValue = Config.Audio.release;
        Config.Audio.release = 1.0;
        // The key was pressed before but it's up now
    } else if (rl.isKeyReleased(.SPACE)) Config.Audio.release = prevValue;

    if (rl.isKeyPressed(.F)) {
        if (!rl.IsWindowState(rl.FLAG_BORDERLESS_WINDOWED_MODE)) rl.SetWindowPosition(0, 0);
        rl.ToggleBorderlessWindowed();
    }
    if (rl.isKeyDown(.LEFT)) rot_offset -= 100 * rl.GetFrameTime();
    if (rl.isKeyDown(.RIGHT)) rot_offset += 100 * rl.GetFrameTime();

    // TODO: Should think about an event system
    if (rl.IsWindowResized()) {
        event.onWindowResize(rl.GetScreenWidth(), rl.GetScreenHeight());
    }
    const wheelMove = rl.GetMouseWheelMoveV();
    if (@abs(wheelMove.x) > @abs(wheelMove.y)) {
        rot_offset += wheelMove.x;
    } else camera3d.position.z += wheelMove.y;

    debug.frame();
}

test "root" {
    _ = music;
    _ = processor;
    _ = graphics;
    _ = gui;
    _ = debug;
    _ = Config;
}
