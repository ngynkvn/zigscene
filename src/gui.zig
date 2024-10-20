const std = @import("std");
const rl = @import("raylib.zig");
const cdef = rl.c;

pub const Rectangle = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    pub fn R(x: f32, y: f32, width: f32, height: f32) Rectangle {
        return .{ .x = x, .y = y, .width = width, .height = height };
    }
    pub fn resize(self: Rectangle, width: f32, height: f32) Rectangle {
        return .{ .x = self.x, .y = self.y, .width = width, .height = height };
    }
    pub fn translate(self: Rectangle, dx: f32, dy: f32) Rectangle {
        return .{ .x = self.x + dx, .y = self.y + dy, .width = self.width, .height = self.height };
    }
    pub fn c(self: Rectangle) cdef.Rectangle {
        return .{ .x = self.x, .y = self.y, .width = self.width, .height = self.height };
    }
};
pub const R = Rectangle.R;

var open = true;
var value: f32 = 50.0;
var gs_buffer = std.mem.zeroes([6]u8);
pub fn frame() void {
    const base = R(5, 5, 16, 16);
    _ = cdef.GuiToggle(base.c(), std.fmt.comptimePrint("#{}#", .{cdef.ICON_FX}), &open);
    if (open) {
        const anchor = base.translate(0, 20).resize(500, 100);
        _ = cdef.GuiPanel(anchor.c(), "Controls");
        const buf = std.fmt.bufPrint(&gs_buffer, "{d:6.2}", .{value}) catch unreachable;
        _ = cdef.GuiLabel(anchor.resize(40, 8).translate(5, 28).c(), "V1");
        _ = cdef.GuiSlider(anchor.resize(200, 8).translate(5, 40).c(), "", buf.ptr, &value, 0, 100);
    }
}
