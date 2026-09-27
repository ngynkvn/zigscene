const std = @import("std");
const gui = @import("../gui.zig");

const ScriptScene = @import("../scripting/Scene.zig");
const AudioSession = @import("../audio/Session.zig");
const processor = @import("../audio/processor.zig");
pub const rl = @import("../raylib.zig");
pub const Config = @import("config.zig");
pub const debug = @import("debug.zig");
pub const event = @import("event.zig");

pub const Resize = struct { width: i32, height: i32 };

pub const State = struct {
    rotation_offset: f32 = 0,
    camera: rl.Camera3D = .{
        .position = Config.Camera.initial_position,
        .target = Config.Camera.initial_target,
        .up = .{ .x = 0, .y = 1, .z = 0 },
        .fovy = Config.Camera.fov,
        .projection = rl.CAMERA_PERSPECTIVE,
    },
};

/// A press while editing a value is typing, not a shortcut. Release always ends the hold.
fn smoothingHold(held: *bool, pressed: bool, released: bool, editing: bool) void {
    if (pressed and !editing) held.* = true else if (released) held.* = false;
}

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

        if (rl.isKeyPressed(.M)) audio.toggleCapture();

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

    smoothingHold(&processor.smoothing_held, rl.isKeyPressed(.SPACE), rl.isKeyReleased(.SPACE), gui.editingValue());

    var resize: ?Resize = null;
    if (rl.IsWindowResized()) {
        resize = .{ .width = rl.GetScreenWidth(), .height = rl.GetScreenHeight() };
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

test "space smoothing ignores editing and never writes the saved setting" {
    const original = Config.Audio.wave_blend;
    defer Config.Audio.wave_blend = original;
    Config.Audio.wave_blend = 0.4;
    var held = false;
    smoothingHold(&held, true, false, true);
    try std.testing.expect(!held);
    smoothingHold(&held, true, false, false);
    try std.testing.expect(held);
    // Editing may start mid-hold; release still ends it.
    smoothingHold(&held, false, true, true);
    try std.testing.expect(!held);
    // The user's setting is untouched throughout, so preferences save it as-is.
    try std.testing.expectEqual(@as(f32, 0.4), Config.Audio.wave_blend);
}
