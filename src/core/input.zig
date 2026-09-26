const std = @import("std");
const gui = @import("../gui.zig");

const ScriptScene = @import("../scripting/Scene.zig");
const AudioSession = @import("../audio/Session.zig");
pub const rl = @import("../raylib.zig");
pub const Config = @import("config.zig");
pub const debug = @import("debug.zig");
pub const event = @import("event.zig");

pub const Resize = struct { width: i32, height: i32 };

pub const State = struct {
    previous_blend: ?f32 = null,
    rotation_offset: f32 = 0,
    camera: rl.Camera3D = .{
        .position = Config.Camera.initial_position,
        .target = Config.Camera.initial_target,
        .up = .{ .x = 0, .y = 1, .z = 0 },
        .fovy = Config.Camera.fov,
        .projection = rl.CAMERA_PERSPECTIVE,
    },

    fn smoothingHold(self: *State, pressed: bool, released: bool, editing: bool) void {
        if (pressed and !editing and self.previous_blend == null) {
            self.previous_blend = Config.Audio.wave_blend;
            Config.Audio.wave_blend = 0.98;
        } else if (released) {
            if (self.previous_blend) |previous| Config.Audio.wave_blend = previous;
            self.previous_blend = null;
        }
    }
};

pub fn process(state: *State, audio: *AudioSession, script: *ScriptScene) ?Resize {
    const ctx = @import("tracy").traceNamed(@src(), "input_processing");
    defer ctx.end();
    if (rl.IsFileDropped()) {
        const files = rl.LoadDroppedFiles();
        defer rl.UnloadDroppedFiles(files);
        var last_audio_path: ?[]const u8 = null;
        for (0..files.count) |i| {
            const path = std.mem.span(files.paths[i]);
            if (std.ascii.endsWithIgnoreCase(path, ".lua")) {
                script.loadFile(path);
                event.onTabChange(.scene);
            } else last_audio_path = path;
        }
        if (last_audio_path) |path| audio.playFile(path);
    }

    if (!gui.editingValue()) {
        if (rl.isKeyPressed(.C)) state.camera.projection = switch (state.camera.projection) {
            rl.CAMERA_PERSPECTIVE => rl.CAMERA_ORTHOGRAPHIC,
            rl.CAMERA_ORTHOGRAPHIC => rl.CAMERA_PERSPECTIVE,
            else => unreachable,
        };

        if (rl.rl.IsKeyPressed(rl.rl.KEY_F5)) script.reload();

        if (rl.isKeyPressed(.M)) audio.toggleSystemCapture();

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
        } else if (rl.isKeyPressed(.SIX)) {
            event.onTabChange(.settings);
        }

        if (rl.isKeyPressed(.F)) {
            if (!rl.IsWindowState(rl.FLAG_BORDERLESS_WINDOWED_MODE)) rl.SetWindowPosition(0, 0);
            rl.ToggleBorderlessWindowed();
        }
        if (rl.isKeyPressed(.P)) audio.togglePlayback();
        if (rl.isKeyDown(.LEFT)) state.rotation_offset -= 100 * rl.GetFrameTime();
        if (rl.isKeyDown(.RIGHT)) state.rotation_offset += 100 * rl.GetFrameTime();
    }

    state.smoothingHold(rl.isKeyPressed(.SPACE), rl.isKeyReleased(.SPACE), gui.editingValue());

    var resize: ?Resize = null;
    if (rl.IsWindowResized()) {
        resize = .{ .width = rl.GetScreenWidth(), .height = rl.GetScreenHeight() };
        event.onWindowResize(resize.?.width, resize.?.height);
    }
    const wheelMove = rl.GetMouseWheelMoveV();
    if (@abs(wheelMove.x) > @abs(wheelMove.y)) {
        event.onSwipe(.horizontal, wheelMove.x);
        if (!gui.pointerOverUi()) state.rotation_offset += wheelMove.x;
    } else {
        event.onSwipe(.vertical, wheelMove.y);
        if (!gui.pointerOverUi()) state.camera.position.z += wheelMove.y;
    }

    debug.frame();
    return resize;
}

test "space smoothing ignores editing and restores only an applied hold" {
    const original = Config.Audio.wave_blend;
    defer Config.Audio.wave_blend = original;
    Config.Audio.wave_blend = 0.4;
    var state: State = .{};
    state.smoothingHold(true, false, true);
    try std.testing.expectEqual(@as(f32, 0.4), Config.Audio.wave_blend);
    // Releasing after editing ends must not write a stale/default value.
    state.smoothingHold(false, true, false);
    try std.testing.expectEqual(@as(f32, 0.4), Config.Audio.wave_blend);
    state.smoothingHold(true, false, false);
    try std.testing.expectEqual(@as(f32, 0.98), Config.Audio.wave_blend);
    // An applied hold must still restore if editing starts before release.
    state.smoothingHold(false, true, true);
    try std.testing.expectEqual(@as(f32, 0.4), Config.Audio.wave_blend);
    Config.Audio.wave_blend = 0.6;
    state.smoothingHold(false, true, false);
    try std.testing.expectEqual(@as(f32, 0.6), Config.Audio.wave_blend);
}
