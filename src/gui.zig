const std = @import("std");
const graphics = @import("graphics.zig");
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
var Options = .{
    graphics.WaveFormLine,
    graphics.WaveFormBar,
};
var value_buffer = std.mem.zeroes([128]u8);
pub fn frame() void {
    const base = R(5, 5, 16, 16);
    _ = cdef.GuiToggle(base.c(), std.fmt.comptimePrint("#{}#", .{cdef.ICON_FX}), &open);
    if (open) {
        const anchor = base.translate(0, 20).resize(500, 400);
        _ = cdef.GuiPanel(anchor.c(), "Controls");
        // _ = cdef.GuiLabel(anchor.resize(200, 8).translate(5, 28).c(), "Bubble.R");
        // _ = cdef.GuiSlider(anchor.resize(200, 8).translate(5, 40).c(), "", buf.ptr, &graphics.Bubble.R, 0, 10);

        comptime var yoff: f32 = 0;
        comptime var i: usize = 0;
        inline for (&Options) |info| {
            const name = @typeName(info);
            _ = cdef.GuiLabel(anchor.resize(200, 8).translate(5, 40 + yoff).c(), name.ptr);
            yoff += 20;
            const cfg = @field(info, "CFG");
            inline for (cfg) |optinfo| {
                const fname = optinfo.name;
                const fval = optinfo.field_value;
                const buf = std.fmt.bufPrint(value_buffer[i * 7 .. i * 7 + 7], "{d:6.2}", .{fval.*}) catch unreachable;
                _ = cdef.GuiSlider(anchor.resize(200, 8).translate(160, 40 + yoff).c(), fname.ptr, buf.ptr, fval, optinfo.range[0], optinfo.range[1]);
                yoff += 20;
                i += 1;
            }
            yoff += 20;
        }
    }
}
