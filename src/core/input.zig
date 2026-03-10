const std = @import("std");
const tracy = @import("tracy");
const rl = @import("raylibz");

pub const playback = @import("../audio/playback.zig");
pub const Config = @import("config.zig");
pub const debug = @import("debug.zig");
pub const event = @import("event.zig");
pub const apprt = @import("apprt.zig");

var prevValue: f32 = 0;
pub var rot_offset: f32 = 0.0;

pub var camera: rl.Camera3D = .{
    // zig fmt: off
    .position   = Config.Camera.initial_position,       // Camera position
    .target     = Config.Camera.initial_target,         // Camera looking at point
    .up         = .{ .x = 0.0, .y = 1.0, .z = 0.0  },   // Camera up vector (rotation towards target)
    .fovy       = Config.Camera.fov,                    // Camera field-of-view Y
    .projection = rl.CameraProjection.perspective,                // Camera projection type
    // zig fmt: on
};

pub const MouseState = struct {
    pub var LeftDown: bool = false;
    pub var RightDown: bool = false;
    pub var Position: rl.Vector2 = undefined;
    pub var Delta: rl.Vector2 = undefined;
    pub var PrevDelta: rl.Vector2 = undefined;
    pub var MouseWheel: rl.Vector2 = undefined;
    pub var PrevMouseWheel: rl.Vector2 = undefined;
    var _buf = std.mem.zeroes([256]u8);
    const fmt =
        \\M-LeftDown: {}
        \\M-RightDown: {}
        \\Position:
        \\  x: {d:4.2}
        \\  y: {d:4.2}
        \\Delta:
        \\  x: {d:4.2}
        \\  y: {d:4.2}
        \\Scroll:
        \\  x: {d:4.2}
        \\  y: {d:4.2}
    ;
    pub fn state() []const u8 {
        const buf = std.fmt.bufPrintZ(&_buf, fmt, .{
            LeftDown,
            RightDown,
            Position.x,
            Position.y,
            PrevDelta.x,
            PrevDelta.y,
            PrevMouseWheel.x,
            PrevMouseWheel.y,
        }) catch _buf[0..0];
        return buf;
    }
};

pub fn processInput(self: *apprt.App) void {
    const t = tracy.traceNamed(@src(), "input_processing");
    defer t.end();

    MouseState.LeftDown = rl.isMouseButtonDown(rl.MouseButton.left);
    MouseState.RightDown = rl.isMouseButtonDown(rl.MouseButton.right);
    MouseState.Position = rl.getMousePosition();
    MouseState.Delta = rl.getMouseDelta();
    if (MouseState.Delta.x != 0 or MouseState.Delta.y != 0) {
        MouseState.PrevDelta = MouseState.Delta;
    }
    MouseState.MouseWheel = rl.getMouseWheelMoveV();
    if (MouseState.MouseWheel.x != 0 or MouseState.MouseWheel.y != 0) {
        MouseState.PrevMouseWheel = MouseState.MouseWheel;
    }

    if (rl.isFileDropped()) {
        const files = rl.loadDroppedFiles();
        defer rl.unloadDroppedFiles(files);
        const file = files.paths[0];
        const len = std.mem.len(file);
        event.emit(self, .{ .filename_input = file[0..len] }) catch unreachable;
    }

    if (rl.isKeyPressed(.C)) camera.projection = switch (camera.projection) {
        .perspective => .orthographic,
        .orthographic => .perspective,
    };

    if (rl.isKeyPressed(.ONE)) {
        event.emit(self, .{ .tab_change = .none }) catch unreachable;
    } else if (rl.isKeyPressed(.TWO)) {
        event.emit(self, .{ .tab_change = .scalar }) catch unreachable;
    } else if (rl.isKeyPressed(.THREE)) {
        event.emit(self, .{ .tab_change = .color }) catch unreachable;
    }

    // The key was not pressed before but it's down now
    if (rl.isKeyPressed(.SPACE)) {
        // :)
        prevValue = Config.Audio.release;
        Config.Audio.release = 1.0;
        // The key was pressed before but it's up now
    } else if (rl.isKeyReleased(.SPACE)) Config.Audio.release = prevValue;

    if (rl.isKeyPressed(.M)) {
        event.emit(self, .toggle_capture) catch unreachable;
    }
    if (rl.isKeyPressed(.F)) {
        if (!rl.Window.isState(.{ .borderless_windowed_mode = true })) rl.Window.setPosition(0, 0);
        rl.Window.toggleBorderless();
    }
    if (rl.isKeyPressed(.P)) {
        if (rl.isMusicValid(playback.music)) {
            if (rl.isMusicStreamPlaying(playback.music)) {
                rl.pauseMusicStream(playback.music);
            } else {
                rl.playMusicStream(playback.music);
            }
        }
    }
    if (rl.isKeyDown(.LEFT)) rot_offset -= 100 * rl.getFrameTime();
    if (rl.isKeyDown(.RIGHT)) rot_offset += 100 * rl.getFrameTime();

    if (rl.Window.isResized()) {
        event.emit(self, .{ .window_resize = .{ .width = rl.Window.getScreenWidth(), .height = rl.Window.getScreenHeight() } }) catch unreachable;
    }
    const wheelMove = rl.getMouseWheelMoveV();
    const amx = @abs(wheelMove.x);
    const amy = @abs(wheelMove.y);
    if (amx > amy) {
        event.emit(self, .{ .swipe = .{ .direction = .horizontal, .amount = wheelMove.x } }) catch unreachable;
        rot_offset += wheelMove.x;
    } else if (amy > amx) {
        event.emit(self, .{ .swipe = .{ .direction = .vertical, .amount = wheelMove.y } }) catch unreachable;
        camera.position.z += wheelMove.y;
    }

    debug.frame();
}
