const std = @import("std");

const tracy = @import("tracy");

const apprt = @import("core/apprt.zig");
const rl = @import("raylib.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var app = try apprt.App.init(allocator);
    defer app.deinit();

    // Main loop
    // Detects window close button or ESC key
    while (!rl.WindowShouldClose()) {
        defer tracy.frameMarkNamed("zigscene");
        app.processMusic();
        app.processInput();
        app.render();
        app.t += rl.GetFrameTime();
    }
}
