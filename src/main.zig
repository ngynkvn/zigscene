const std = @import("std");
const rl = @import("raylib.zig");
const music = @import("music.zig");
const audio = @import("audio.zig");
const graphics = @import("graphics.zig");
const gui = @import("gui.zig");
const debug = @import("debug.zig");

pub const defaultScreenWidth = 1200;
pub const defaultScreenHeight = 800;

pub var isFullScreen = false;
pub var screenWidth: c_int = defaultScreenWidth;
pub var screenHeight: c_int = defaultScreenHeight;

const APP_NAME = "zigscene";

pub fn main() !void {
    var t: f32 = 0.0;

    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE);

    // Setup
    rl.InitWindow(screenWidth, screenHeight, APP_NAME);
    defer rl.CloseWindow(); // Close window and OpenGL context

    rl.InitAudioDevice();
    defer rl.CloseAudioDevice();

    rl.GuiSetAlpha(0.8);
    rl.GuiLoadStyleDark();
    //try music.startMusic("./sounds/willix.mp3");

    var rot_offset: f32 = 0.0;
    rl.SetMasterVolume(0.10);

    var camera3d: rl.Camera3D = .{
        .position = .{ .x = 0.0, .y = 0, .z = 10.0 }, // Camera position
        .target = .{ .x = 0.0, .y = 0.0, .z = 0.0 }, // Camera looking at point
        .up = .{ .x = 0.0, .y = 1.0, .z = 0.0 }, // Camera up vector (rotation towards target)
        .fovy = 65.0, // Camera field-of-view Y
        .projection = rl.CAMERA_PERSPECTIVE, // Camera projection type
    };
    rl.SetTargetFPS(60);

    // Main game loop
    // Detects window close button or ESC key
    while (!rl.WindowShouldClose()) {
        if (rl.IsFileDropped()) {
            try music.handleFile();
        }
        if (music.IsMusicStreamPlaying()) {
            music.UpdateMusicStream();
        }
        if (rl.isKeyPressed(.C)) {
            camera3d.projection = switch (camera3d.projection) {
                rl.CAMERA_PERSPECTIVE => rl.CAMERA_ORTHOGRAPHIC,
                rl.CAMERA_ORTHOGRAPHIC => rl.CAMERA_PERSPECTIVE,
                else => unreachable,
            };
        }
        if (rl.isKeyPressed(.F)) {
            if (rl.IsWindowState(rl.FLAG_BORDERLESS_WINDOWED_MODE)) {
                screenWidth = defaultScreenWidth;
                screenHeight = defaultScreenHeight;
            } else {
                const display = rl.GetCurrentMonitor();
                screenWidth = rl.GetMonitorWidth(display);
                screenHeight = rl.GetMonitorHeight(display);
                rl.SetWindowPosition(0, 0);
            }
            rl.SetWindowSize(screenWidth, screenHeight);
            rl.ToggleBorderlessWindowed();
        }
        if (rl.IsWindowResized()) {
            const display = rl.GetCurrentMonitor();
            screenWidth = rl.GetMonitorWidth(display);
            screenHeight = rl.GetMonitorHeight(display);
        }
        // Debug related controls
        debug.input();

        if (rl.isKeyDown(.LEFT)) {
            rot_offset -= 1;
        }
        if (rl.isKeyDown(.RIGHT)) {
            rot_offset += 1;
        }
        const wheelMove = rl.GetMouseWheelMoveV();
        if (@abs(wheelMove.x) > @abs(wheelMove.y)) {
            rot_offset += wheelMove.x;
        } else {
            camera3d.position.z += wheelMove.y;
        }
        {
            rl.BeginDrawing();
            defer rl.EndDrawing();
            const center = rl.GetWorldToScreen(.{ .x = 0, .y = 0 }, camera3d);

            debug.render();

            rl.ClearBackground(rl.BLACK);
            // Drawing
            const mtp = music.GetMusicTimePlayed();
            graphics.Bubble.render(camera3d, rot_offset, mtp, t);
            var it = std.mem.window(f32, &audio.ringbuffer, 256, 128);
            while (it.next()) |w| {
                for (w, audio.bi..) |v, bi| {
                    const i = bi % w.len;
                    graphics.WaveFormLine.render(.{ .y = center.y - 80 }, i, v);
                    graphics.WaveFormBar.render(center, i, v);
                    //graphics.WaveFormLine.render(.{ .y = center.y * 2 }, i, fv.magnitude() * 0.15);
                    //graphics.FFT.render(center, i, fv.magnitude());
                    //graphics.draw_bubbles(center, i, v, t);
                }
            }
            // for (0..audio.ringbuffer.len) |bi| {
            //     const i = bi % audio.RB_LEN;
            //     const v = audio.ringbuffer[i];
            //     graphics.WaveFormLine.render(.{ .y = center.y - 80 }, i, v);
            //     graphics.WaveFormBar.render(center, i, v);
            //     //graphics.WaveFormLine.render(.{ .y = center.y * 2 }, i, fv.magnitude() * 0.15);
            //     //graphics.FFT.render(center, i, fv.magnitude());
            //     //graphics.draw_bubbles(center, i, v, t);
            // }
            t += rl.GetFrameTime();
        }
        gui.frame();
    }
}

test "root" {
    std.testing.refAllDecls(@This());
}
