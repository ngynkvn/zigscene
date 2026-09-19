const std = @import("std");

pub const playback = @import("../audio/playback.zig");
pub const rl = @import("../raylib.zig");
pub const Config = @import("config.zig");
pub const debug = @import("debug.zig");
pub const event = @import("event.zig");
const capture = @import("../audio/capture.zig");

pub const Resize = struct { width: i32, height: i32 };

pub const State = struct {
    previous_blend: f32 = 0,
    rotation_offset: f32 = 0,
    camera: rl.Camera3D = .{
        .position = Config.Camera.initial_position,
        .target = Config.Camera.initial_target,
        .up = .{ .x = 0, .y = 1, .z = 0 },
        .fovy = Config.Camera.fov,
        .projection = rl.CAMERA_PERSPECTIVE,
    },
};

pub fn process(state: *State) ?Resize {
    const ctx = @import("tracy").traceNamed(@src(), "input_processing");
    defer ctx.end();
    if (rl.IsFileDropped()) {
        const files = rl.LoadDroppedFiles();
        defer rl.UnloadDroppedFiles(files);
        const file = files.paths[0];
        const len = std.mem.len(file);
        event.onFilenameInput(file[0..len]);
    }

    if (rl.isKeyPressed(.C)) state.camera.projection = switch (state.camera.projection) {
        rl.CAMERA_PERSPECTIVE => rl.CAMERA_ORTHOGRAPHIC,
        rl.CAMERA_ORTHOGRAPHIC => rl.CAMERA_PERSPECTIVE,
        else => unreachable,
    };

    if (rl.isKeyPressed(.M)) {
        if (capture.active) {
            capture.stop();
        } else {
            if (rl.IsMusicValid(playback.music)) rl.PauseMusicStream(playback.music);
            capture.start(.system, -1) catch {
                if (rl.IsMusicValid(playback.music)) rl.ResumeMusicStream(playback.music);
            };
        }
    }

    if (rl.isKeyPressed(.ONE)) {
        event.onTabChange(.none);
    } else if (rl.isKeyPressed(.TWO)) {
        event.onTabChange(.scalar);
    } else if (rl.isKeyPressed(.THREE)) {
        event.onTabChange(.color);
    } else if (rl.isKeyPressed(.FOUR)) {
        event.onTabChange(.motion);
    } else if (rl.isKeyPressed(.FIVE)) {
        event.onTabChange(.scene);
    }

    // The key was not pressed before but it's down now
    if (rl.isKeyPressed(.SPACE)) {
        // :)
        state.previous_blend = Config.Audio.wave_blend;
        Config.Audio.wave_blend = 0.98;
        // The key was pressed before but it's up now
    } else if (rl.isKeyReleased(.SPACE)) Config.Audio.wave_blend = state.previous_blend;

    if (rl.isKeyPressed(.F)) {
        if (!rl.IsWindowState(rl.FLAG_BORDERLESS_WINDOWED_MODE)) rl.SetWindowPosition(0, 0);
        rl.ToggleBorderlessWindowed();
    }
    if (rl.isKeyPressed(.P) and !capture.active) {
        if (rl.IsMusicValid(playback.music)) {
            if (rl.IsMusicStreamPlaying(playback.music)) {
                rl.PauseMusicStream(playback.music);
            } else {
                rl.PlayMusicStream(playback.music);
            }
        }
    }
    if (rl.isKeyDown(.LEFT)) state.rotation_offset -= 100 * rl.GetFrameTime();
    if (rl.isKeyDown(.RIGHT)) state.rotation_offset += 100 * rl.GetFrameTime();

    var resize: ?Resize = null;
    if (rl.IsWindowResized()) {
        resize = .{ .width = rl.GetScreenWidth(), .height = rl.GetScreenHeight() };
        event.onWindowResize(resize.?.width, resize.?.height);
    }
    const wheelMove = rl.GetMouseWheelMoveV();
    if (@abs(wheelMove.x) > @abs(wheelMove.y)) {
        event.onSwipe(.horizontal, wheelMove.x);
        state.rotation_offset += wheelMove.x;
    } else {
        event.onSwipe(.vertical, wheelMove.y);
        state.camera.position.z += wheelMove.y;
    }

    debug.frame();
    return resize;
}
