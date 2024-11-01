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
var rot_offset: f32 = 0.0;
var camera3d: rl.Camera3D = .{
    // zig fmt: off
    .position   = .{ .x = 0.0, .y = 0.0, .z = 10.0 }, // Camera position
    .target     = .{ .x = 0.0, .y = 0.0, .z = 0.0  }, // Camera looking at point
    .up         = .{ .x = 0.0, .y = 1.0, .z = 0.0  }, // Camera up vector (rotation towards target)
    .fovy       = 65.0,                               // Camera field-of-view Y
    .projection = rl.CAMERA_PERSPECTIVE,              // Camera projection type
    // zig fmt: on
};

pub fn main() !void {
    var t: f32 = 0.0;

    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE);

    // Setup
    rl.InitWindow(screenWidth, screenHeight, APP_NAME);
    defer rl.CloseWindow(); // Close window and OpenGL context

    rl.InitAudioDevice();
    defer rl.CloseAudioDevice();

    rl.GuiSetAlpha(0.8);
    rl.RayguiDark();
    if (try processArgs()) |path| {
        try music.startMusic(path.ptr);
    }

    rl.SetMasterVolume(0.40);

    // Main loop
    // Detects window close button or ESC key
    while (!rl.WindowShouldClose()) {
        defer tracy.frameMarkNamed("zigscene");
        if (music.IsMusicStreamPlaying()) music.UpdateMusicStream();
        processInput();

        {
            rl.BeginDrawing();
            defer rl.EndDrawing();
            // Debug related visuals + controls
            debug.frame();
            const ctx = tracy.traceNamed(@src(), "Renders");
            defer ctx.end();

            const center = rl.GetWorldToScreen(.{}, camera3d);
            debug.render();

            rl.ClearBackground(rl.BLACK);
            // Drawing
            const ctx_2d = tracy.traceNamed(@src(), "2d");
            for (audio.curr_buffer, audio.curr_fft, 0..) |v, fv, i| {
                graphics.WaveFormLine.render(.{ .y = center.y - 80 }, i, v);
                graphics.WaveFormBar.render(center, i, v);
                graphics.WaveFormLine.render(.{ .y = center.y * 2 }, i, fv.magnitude() * 0.15);
                graphics.FFT.render(center, i, fv.magnitude());
            }
            ctx_2d.end();
            graphics.Bubble.render(camera3d, rot_offset, t);
            gui.frame();
            t += rl.GetFrameTime();
        }
    }
}

fn processInput() void {
    if (rl.IsFileDropped()) try music.handleFile();

    if (rl.isKeyPressed(.C)) camera3d.projection = switch (camera3d.projection) {
        rl.CAMERA_PERSPECTIVE => rl.CAMERA_ORTHOGRAPHIC,
        rl.CAMERA_ORTHOGRAPHIC => rl.CAMERA_PERSPECTIVE,
        else => unreachable,
    };

    if (rl.isKeyPressed(.ONE)) {
        gui.to(.none);
    } else if (rl.isKeyPressed(.TWO)) {
        gui.to(.audio);
    } else if (rl.isKeyPressed(.THREE)) {
        gui.to(.scalar);
    } else if (rl.isKeyPressed(.FOUR)) {
        gui.to(.color);
    }

    // The key was not pressed before but it's down now
    if (rl.isKeyPressed(.SPACE)) {
        // :)
        prevValue = audio.Release;
        audio.Release = 1.0;
        // The key was pressed before but it's up now
    } else if (rl.isKeyReleased(.SPACE)) audio.Release = prevValue;

    if (rl.isKeyPressed(.F)) {
        if (!rl.IsWindowState(rl.FLAG_BORDERLESS_WINDOWED_MODE)) rl.SetWindowPosition(0, 0);
        rl.ToggleBorderlessWindowed();
    }
    if (rl.isKeyDown(.LEFT)) rot_offset -= 100 * rl.GetFrameTime();
    if (rl.isKeyDown(.RIGHT)) rot_offset += 100 * rl.GetFrameTime();
    if (rl.IsWindowResized()) {
        const display = rl.GetCurrentMonitor();
        screenWidth = rl.GetMonitorWidth(display);
        screenHeight = rl.GetMonitorHeight(display);
    }
    const wheelMove = rl.GetMouseWheelMoveV();
    if (@abs(wheelMove.x) > @abs(wheelMove.y)) {
        rot_offset += wheelMove.x;
    } else camera3d.position.z += wheelMove.y;
}
fn processArgs() !?[]const u8 {
    var buffer: [256]u8 = @splat(0);
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    var args = try std.process.argsWithAllocator(allocator);
    return if (!args.skip()) null else args.next();
}

test "root" {
    std.testing.refAllDeclsRecursive(@This());
}
