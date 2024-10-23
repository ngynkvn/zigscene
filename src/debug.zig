const std = @import("std");
const rl = @import("raylib.zig");
const c = rl.c;
const audio = @import("audio.zig");

var pos: c.Rectangle = .{ .x = 300, .y = 300, .width = 10, .height = 10 };
var visible = false;
pub fn render() void {
    if (!visible) return;

    pos.height = 10 + 100 * audio.avg_intensity;
    c.DrawRectangleRec(pos, c.RED);
}

pub fn input() void {
    if (rl.IsKeyPressed(.D)) {
        visible = !visible;
    }
    const mp = c.GetMousePosition();
    const delta = c.GetMouseDelta();
    const pressed = c.IsMouseButtonPressed(c.MOUSE_LEFT_BUTTON);
    if (pressed) {
        std.log.info("click: {}", .{mp});
    }
    const dragging = c.IsMouseButtonDown(c.MOUSE_LEFT_BUTTON) and
        (c.CheckCollisionPointRec(mp, pos) or c.CheckCollisionPointRec(.{ .x = mp.x - delta.x, .y = mp.y - delta.y }, pos));
    if (dragging) {
        pos.x += delta.x;
        pos.y += delta.y;
    }
}
