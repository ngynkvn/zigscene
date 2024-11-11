const std = @import("std");

pub const playback = @import("../audio/playback.zig");
pub const rl = @import("../raylib.zig");
pub const Config = @import("config.zig");
pub const debug = @import("debug.zig");
pub const event = @import("event.zig");

var prevValue: f32 = 0;
pub var rot_offset: f32 = 0.0;

// TODO: Move to Camera namespace
pub var camera3d: rl.Camera3D = .{
    // zig fmt: off
    .position   = Config.Camera.initial_position,       // Camera position
    .target     = Config.Camera.initial_target,         // Camera looking at point
    .up         = .{ .x = 0.0, .y = 1.0, .z = 0.0  },   // Camera up vector (rotation towards target)
    .fovy       = Config.Camera.fov,                    // Camera field-of-view Y
    .projection = rl.CAMERA_PERSPECTIVE,                // Camera projection type
    // zig fmt: on
};

pub fn processInput() void {
    const ctx = @import("tracy").traceNamed(@src(), "input_processing");
    defer ctx.end();
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
        event.onTabChange(.scalar);
    } else if (rl.isKeyPressed(.THREE)) {
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
    if (rl.isKeyPressed(.P)) {
        if (rl.IsMusicValid(playback.music)) {
            if (rl.IsMusicStreamPlaying(playback.music)) {
                rl.PauseMusicStream(playback.music);
            } else {
                rl.PlayMusicStream(playback.music);
            }
        }
    }
    if (rl.isKeyDown(.LEFT)) rot_offset -= 100 * rl.GetFrameTime();
    if (rl.isKeyDown(.RIGHT)) rot_offset += 100 * rl.GetFrameTime();

    if (rl.IsWindowResized()) {
        event.onWindowResize(rl.GetScreenWidth(), rl.GetScreenHeight());
    }
    const wheelMove = rl.GetMouseWheelMoveV();
    if (@abs(wheelMove.x) > @abs(wheelMove.y)) {
        rot_offset += wheelMove.x;
    } else camera3d.position.z += wheelMove.y;

    debug.frame();
}
