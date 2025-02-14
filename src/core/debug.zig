const std = @import("std");

const processor = @import("../audio/processor.zig");
const cnv = @import("../ext/convert.zig");
const ffi = cnv.ffi;
const Rectangle = @import("../ext/structs.zig").Rectangle;
const rl = @import("../raylib.zig");
var screenWidth: c_int = @import("config.zig").Window.width;

pub fn onWindowResize(width: i32, _: i32) void {
    screenWidth = width;
}

var pos: rl.Rectangle = .{ .x = 300, .y = 300, .width = 10, .height = 10 };
var visible = false;
pub fn render() void {
    if (!visible) return;
    var txt = std.mem.zeroes([256]u8);
    const buf = std.fmt.bufPrintZ(txt[0..64], "{d:4}", .{rl.GetFPS()}) catch txt[0..0];
    rl.DrawText(buf.ptr, screenWidth - 100, 200, 24, rl.RAYWHITE);
    pos.height = 10 + 100 * processor.rms_energy;
    rl.DrawRectangleRec(pos, rl.RED);
    // timeseries beats
    const tsbeats = Rectangle.from(10, 64, 1, 10);
    // Go past last written and scan from there
    const bi = processor.bi;
    for (1..processor.past_beats.len + 1) |b| {
        const i = (bi + b) % processor.past_beats.len;
        const value = processor.past_beats[i];
        rl.DrawRectangleRec(tsbeats.translate(ffi(f32, b * 2), 0).into(), if (!value) rl.BLUE else rl.RED);
    }
}

pub fn frame() void {
    if (rl.isKeyPressed(.D)) visible = !visible;
    const mp = rl.GetMousePosition();
    const delta = rl.GetMouseDelta();
    const dragging = rl.IsMouseButtonDown(rl.MOUSE_LEFT_BUTTON) and
        (rl.CheckCollisionPointRec(mp, pos) or rl.CheckCollisionPointRec(.{ .x = mp.x - delta.x, .y = mp.y - delta.y }, pos));
    if (dragging) {
        pos.x += delta.x;
        pos.y += delta.y;
    }
}

// TODO: enum
pub const RL_TEXTURE_FILTER_NEAREST = @as(c_int, 0x2600);
pub const RL_TEXTURE_FILTER_LINEAR = @as(c_int, 0x2601);
pub const RL_TEXTURE_FILTER_MIP_NEAREST = @as(c_int, 0x2700);
pub const RL_TEXTURE_FILTER_NEAREST_MIP_LINEAR = @as(c_int, 0x2702);
pub const RL_TEXTURE_FILTER_LINEAR_MIP_NEAREST = @as(c_int, 0x2701);
pub const RL_TEXTURE_FILTER_MIP_LINEAR = @as(c_int, 0x2703);
pub const RL_TEXTURE_FILTER_ANISOTROPIC = @as(c_int, 0x3000);
