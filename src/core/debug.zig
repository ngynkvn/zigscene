const std = @import("std");

const processor = @import("../audio/processor.zig");
const input = @import("../core/input.zig");
const cnv = @import("../raylib/ext/convert.zig");
const ffi = cnv.ffi;
const Rectangle = @import("../raylib/ext/structs.zig").Rectangle;
const rl = @import("../raylib.zig");
const Window = @import("../ui/window.zig").Window;
var screenWidth: c_int = @import("config.zig").Window.width;

pub fn onWindowResize(width: i32, _: i32) void {
    screenWidth = width;
}

var pos: rl.Rectangle = .{ .x = 300, .y = 300, .width = 10, .height = 10 };
var visible = true;
var txt = std.mem.zeroes([256]u8);
var debug_window = Window.init(700, 400, 400, 300, "Debug Info");
pub var debug_window2 = Window.init(500, 200, 200, 200, "Debug2");

pub fn render() void {
    if (!visible) return;

    if (debug_window.begin()) |ctx| {
        const bounds = ctx.bounds();
        const buf = std.fmt.bufPrintZ(txt[0..64], "FPS: {d:4} ({d:4.2})", .{
            rl.GetFPS(),
            std.fmt.fmtDuration(@intFromFloat(rl.GetFrameTime() * std.time.ns_per_ms)),
        }) catch txt[0..0];
        _ = rl.GuiLabel(rl.Rectangle{ .x = bounds.x, .y = bounds.y, .width = bounds.width, .height = 24 }, buf.ptr);
        _ = rl.GuiLabel(rl.Rectangle{ .x = bounds.x, .y = bounds.y + 80, .width = bounds.width, .height = 120 }, input.MouseState.state().ptr);
        rl.DrawRay(.{ .position = .{ .x = bounds.x, .y = bounds.y }, .direction = rl.Vector3.from(input.MouseState.PrevDelta) }, rl.RED);
    }
    if (debug_window2.begin()) |ctx| {
        _ = ctx;
    }

    // pos.height = 10 + 100 * processor.rms_energy;
    // rl.DrawRectangleRec(pos, rl.RED);
    // // timeseries beats
    // const tsbeats = Rectangle.from(10, 64, 1, 10);
    // // Go past last written and scan from there
    // const bi = processor.bi;
    // for (1..processor.past_beats.len + 1) |b| {
    //     const i = (bi + b) % processor.past_beats.len;
    //     const value = processor.past_beats[i];
    //     rl.DrawRectangleRec(tsbeats.translate(ffi(f32, b * 2), 0), if (!value) rl.BLUE else rl.RED);
    // }
}

pub fn frame() void {
    if (rl.isKeyPressed(.D)) debug_window.toggle();
}

// TODO: enum
pub const RL_TEXTURE_FILTER_NEAREST = @as(c_int, 0x2600);
pub const RL_TEXTURE_FILTER_LINEAR = @as(c_int, 0x2601);
pub const RL_TEXTURE_FILTER_MIP_NEAREST = @as(c_int, 0x2700);
pub const RL_TEXTURE_FILTER_NEAREST_MIP_LINEAR = @as(c_int, 0x2702);
pub const RL_TEXTURE_FILTER_LINEAR_MIP_NEAREST = @as(c_int, 0x2701);
pub const RL_TEXTURE_FILTER_MIP_LINEAR = @as(c_int, 0x2703);
pub const RL_TEXTURE_FILTER_ANISOTROPIC = @as(c_int, 0x3000);
