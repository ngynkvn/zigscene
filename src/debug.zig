const std = @import("std");
const rl = @import("raylib.zig");
const audio = @import("audio.zig");
const main = @import("main.zig");
const asF32 = @import("extras.zig").asF32;

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

pub fn input() void {
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

pub fn debug_thread() !void {
    const options = @import("options");
    if (!options.enable_ttyz) return;
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();
    const ttyz = @import("ttyz");
    var tty = ttyz.Terminal.init(allocator, .{ .ISIG = true }) catch |e| std.debug.panic("cannot init: {}", .{e});
    defer tty.deinit();
    while (!rl.WindowShouldClose()) {
        std.Thread.sleep(std.time.ns_per_s);
        _ = try tty.clear();
        try tty.goto(0, 0);
        const mp = rl.GetMousePosition();
        const delta = rl.GetMouseDelta();
        const pressed = rl.IsMouseButtonPressed(rl.MOUSE_LEFT_BUTTON);
        try tty.print("{} | {} | {}", .{ mp, delta, pressed });
        try tty.flush();
    }
}
