const std = @import("std");
const rl = @import("../raylib.zig");
const audio = @import("../audio.zig");
const main = @import("../main.zig");
const asF32 = @import("../ext/convert.zig").asF32;

var pos: rl.Rectangle = .{ .x = 300, .y = 300, .width = 10, .height = 10 };
var visible = false;
pub fn render() void {
    if (!visible) return;
    var txt = std.mem.zeroes([256]u8);
    const pressed = rl.IsMouseButtonPressed(rl.MOUSE_LEFT_BUTTON);
    const buf = std.fmt.bufPrintZ(txt[0..64], "{}", .{pressed}) catch txt[0..0];
    rl.DrawText(buf.ptr, main.screenWidth - 100, 200, 24, rl.RAYWHITE);
    pos.height = 10 + 100 * audio.rms_energy;
    rl.DrawRectangleRec(pos, rl.RED);
}

pub fn frame() void {
    if (rl.isKeyPressed(.D)) {
        visible = !visible;
    }
    const mp = rl.GetMousePosition();
    const delta = rl.GetMouseDelta();
    const dragging = rl.IsMouseButtonDown(rl.MOUSE_LEFT_BUTTON) and
        (rl.CheckCollisionPointRec(mp, pos) or rl.CheckCollisionPointRec(.{ .x = mp.x - delta.x, .y = mp.y - delta.y }, pos));
    if (dragging) {
        pos.x += delta.x;
        pos.y += delta.y;
    }
}
