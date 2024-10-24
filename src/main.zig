const std = @import("std");
const rl = @import("raylib.zig");
const c = rl.c;
const music = @import("music.zig");
const audio = @import("audio.zig");
const graphics = @import("graphics.zig");
const gui = @import("gui.zig");
const debug = @import("debug.zig");
const imgui = @import("cimgui");

pub const defaultScreenWidth = 1200;
pub const defaultScreenHeight = 800;

pub var isFullScreen = false;
pub var screenWidth: c_int = defaultScreenWidth;
pub var screenHeight: c_int = defaultScreenHeight;

const APP_NAME = "zigscene";

var filename_buffer = std.mem.zeroes([128:0]u8);
pub fn main() !void {
    var t: f32 = 0.0;

    c.SetConfigFlags(c.FLAG_WINDOW_RESIZABLE);

    // Setup
    c.InitWindow(screenWidth, screenHeight, APP_NAME);
    defer c.CloseWindow(); // Close window and OpenGL context

    c.InitAudioDevice();
    defer c.CloseAudioDevice();

    _ = imgui.igCreateContext(0);

    var rot_offset: f32 = 0.0;
    c.SetMasterVolume(0.10);

    var camera3d: c.Camera3D = .{
        .position = .{ .x = 0.0, .y = 0, .z = 10.0 }, // Camera position
        .target = .{ .x = 0.0, .y = 0.0, .z = 0.0 }, // Camera looking at point
        .up = .{ .x = 0.0, .y = 1.0, .z = 0.0 }, // Camera up vector (rotation towards target)
        .fovy = 65.0, // Camera field-of-view Y
        .projection = c.CAMERA_PERSPECTIVE, // Camera projection type
    };
    c.SetTargetFPS(60); // Set our game to run at 60 frames-per-second

    // Main game loop
    // Detects window close button or ESC key
    while (!c.WindowShouldClose()) {
        if (c.IsFileDropped()) {
            try music.handleFile();
        }
        if (music.IsMusicStreamPlaying()) {
            music.UpdateMusicStream();
        }
        if (rl.IsKeyPressed(.C)) {
            camera3d.projection = switch (camera3d.projection) {
                c.CAMERA_PERSPECTIVE => c.CAMERA_ORTHOGRAPHIC,
                c.CAMERA_ORTHOGRAPHIC => c.CAMERA_PERSPECTIVE,
                else => unreachable,
            };
        }
        if (rl.IsKeyPressed(.F)) {
            if (c.IsWindowState(c.FLAG_BORDERLESS_WINDOWED_MODE)) {
                screenWidth = defaultScreenWidth;
                screenHeight = defaultScreenHeight;
            } else {
                const display = c.GetCurrentMonitor();
                screenWidth = c.GetMonitorWidth(display);
                screenHeight = c.GetMonitorHeight(display);
                c.SetWindowPosition(0, 0);
            }
            c.SetWindowSize(screenWidth, screenHeight);
            c.ToggleBorderlessWindowed();
        }
        if (c.IsWindowResized()) {
            const display = c.GetCurrentMonitor();
            screenWidth = c.GetMonitorWidth(display);
            screenHeight = c.GetMonitorHeight(display);
        }
        // Debug related controls
        debug.input();

        if (rl.IsKeyDown(.LEFT)) {
            rot_offset -= 1;
        }
        if (rl.IsKeyDown(.RIGHT)) {
            rot_offset += 1;
        }
        const wheelMove = c.GetMouseWheelMoveV();
        if (@abs(wheelMove.x) > @abs(wheelMove.y)) {
            rot_offset += wheelMove.x;
        } else {
            camera3d.position.z += wheelMove.y;
        }
        {
            c.BeginDrawing();
            defer c.EndDrawing();
            const center = c.GetWorldToScreen(.{ .x = 0, .y = 0 }, camera3d);

            debug.render();

            c.ClearBackground(c.BLACK);
            // Drawing
            const mtp = music.GetMusicTimePlayed();
            graphics.Bubble.render(camera3d, rot_offset, mtp, t);
            for (audio.curr_buffer, audio.curr_fft, 0..) |v, fv, i| {
                graphics.WaveFormLine.render(.{ .y = center.y - 80 }, i, v);
                graphics.WaveFormBar.render(center, i, v);
                graphics.WaveFormLine.render(.{ .y = center.y * 2 }, i, fv.magnitude() * 0.15);
                graphics.FFT.render(center, i, fv.magnitude());
                //graphics.draw_bubbles(center, i, v, t);
            }
            t += 0.01;
        }
        gui.frame();
    }
}

test "root" {
    std.testing.refAllDecls(@This());
}
