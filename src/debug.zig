const std = @import("std");
const rl = @import("raylib.zig");
const c = rl;
const audio = @import("audio.zig");
const main = @import("main.zig");
const asF32 = @import("extras.zig").asF32;

var pos: c.Rectangle = .{ .x = 300, .y = 300, .width = 10, .height = 10 };
var visible = false;
pub fn render() void {
    if (!visible) return;

    var txt = std.mem.zeroes([128]u8);
    const spacing = asF32(main.screenWidth) / asF32(audio.curr_buffer.len);
    const buf = std.fmt.bufPrintZ(txt[0..64], "{d}", .{spacing}) catch txt[0..0];
    c.DrawText(buf.ptr, main.screenWidth - 100, 200, 24, c.RAYWHITE);
    pos.height = 10 + 100 * audio.avg_intensity;
    c.DrawRectangleRec(pos, c.RED);
}

pub fn input() void {
    if (rl.isKeyPressed(.D)) {
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
