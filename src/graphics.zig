const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
    @cInclude("rlgl.h");
});
const main = @import("main.zig");
const audio = @import("audio.zig");

pub fn draw_line(center: c.Vector2, i: usize, v: f32) void {
    const SPACING = main.screenWidth / 200;
    const x = @as(f32, @floatFromInt(i)) * SPACING;
    const y = (v * 60);
    // "plot" x and y
    const px = x;
    const py = -y + center.y - 60;
    c.DrawRectangleRec(.{ .x = px, .y = py, .width = 1, .height = 2 }, c.RAYWHITE);
    c.DrawRectangleRec(.{ .x = px, .y = py + 12, .width = 2, .height = 1 }, c.GREEN);
}

pub fn draw_bars(center: c.Vector2, i: usize, v: f32) void {
    const SPACING = main.screenWidth / 200;
    const x = @as(f32, @floatFromInt(i)) * SPACING;
    const y = (v * 40);
    const base_h: f32 = 40;
    const tgrad = c.BLUE;
    const bgrad = c.BLUE;
    const px = x;
    c.DrawRectangleGradientEx(
        .{
            .x = px,
            .y = center.y * 2 - y - base_h,
            .width = 3,
            .height = y + base_h,
        },
        tgrad,
        bgrad,
        bgrad,
        tgrad,
    );
}

const bubbles = [_][2]f32{
    .{ 240, 60 },
    .{ 240, 40 },
    .{ 240, 20 },
    .{ 240, 10 },
    .{ 220, 10 },
};
pub fn draw_bubbles(center: c.Vector2, i: usize, v: f32, t: f32) void {
    const tsteps = std.math.pi * 2 / @as(f32, @floatFromInt(audio.curr_buffer.len));
    for (bubbles) |b| {
        const r = b[0] + (@abs(v) * b[1]);
        const x = (@cos(@as(f32, @floatFromInt(i)) * tsteps + t) * r) + center.x;
        const y = (@sin(@as(f32, @floatFromInt(i)) * tsteps + t) * r) + center.y;
        c.DrawRectangleRec(.{ .x = x, .y = y, .width = 2, .height = 2 }, c.ORANGE);
    }
}
