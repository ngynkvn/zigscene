const r = @cImport(
    @cInclude("raylib.h"),
);
const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const Allocator = mem.Allocator;
pub fn main() !void {
    r.InitWindow(960, 540, "My Window Name");
    r.SetTargetFPS(144);
    defer r.CloseWindow();
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    _ = allocator;

    var buffer = [_]u8{0} ** 128;
    while (!r.WindowShouldClose()) {
        const mp = r.GetMousePosition();
        const msg = try std.fmt.bufPrint(&buffer, "Mouse pos: {} {}", mp);
        r.BeginDrawing();
        r.ClearBackground(r.RAYWHITE);
        r.DrawText(msg.ptr, 0, 0, 24, r.BLACK);
        r.DrawLine(0, 0, @intFromFloat(mp.x), @intFromFloat(mp.y), r.BLUE);
        r.EndDrawing();
    }
}
