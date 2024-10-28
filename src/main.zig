const std = @import("std");
const rl = @import("raylib.zig");
const music = @import("music.zig");
const audio = @import("audio.zig");
const graphics = @import("graphics.zig");
const gui = @import("gui.zig");
const debug = @import("debug.zig");
const options = @import("options");
const tracy = @import("tracy");

pub const defaultScreenWidth = 1024;
pub const defaultScreenHeight = 768;

pub var isFullScreen = false;
pub var screenWidth: c_int = defaultScreenWidth;
pub var screenHeight: c_int = defaultScreenHeight;

const APP_NAME = "zigscene";

var pressed: bool = false;
var prevValue: f32 = 0;

pub fn main() !void {
    var t: f32 = 0.0;

    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE);

    // Setup
    rl.InitWindow(screenWidth, screenHeight, APP_NAME);
    defer rl.CloseWindow(); // Close window and OpenGL context

    rl.InitAudioDevice();
    defer rl.CloseAudioDevice();

    rl.GuiSetAlpha(0.6);
    rl.RayguiDark();
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
    rl.SetTargetFPS(90);

    // Main loop
    // Detects window close button or ESC key
    while (!rl.WindowShouldClose()) {
        defer tracy.frameMarkNamed("zigscene");
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
        if (!pressed and rl.isKeyDown(.SPACE)) {
            // :)
            pressed = true;
            prevValue = audio.Release;
            audio.Release = 1.0;
        } else if (pressed and rl.IsKeyUp(.SPACE)) {
            audio.Release = prevValue;
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
            const ctx = tracy.traceNamed(@src(), "Renders");
            defer ctx.end();

            const center = rl.GetWorldToScreen(.{ .x = 0, .y = 0 }, camera3d);
            debug.render();

            rl.ClearBackground(rl.BLACK);
            // Drawing
            graphics.Bubble.render(camera3d, rot_offset, t);
            const ctx_2d = tracy.traceNamed(@src(), "2d");
            for (audio.curr_buffer, audio.curr_fft, 0..) |v, fv, i| {
                graphics.WaveFormLine.render(.{ .y = center.y - 80 }, i, v);
                graphics.WaveFormBar.render(center, i, v);
                graphics.WaveFormLine.render(.{ .y = center.y * 2 }, i, fv.magnitude() * 0.15);
                graphics.FFT.render(center, i, fv.magnitude());
            }
            ctx_2d.end();
            gui.frame();
            t += rl.GetFrameTime();
        }
    }
}

test "root" {
    std.testing.refAllDecls(@This());
    _ = @import("ext/color.zig");
}
