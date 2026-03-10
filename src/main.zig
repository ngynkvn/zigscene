const std = @import("std");
const rl = @import("raylibz");

const tracy = @import("tracy");

const apprt = @import("core/apprt.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var app = try apprt.App.init(allocator);
    defer app.deinit();

    // Main loop
    // Detects window close button or ESC key
    while (!rl.Window.shouldClose()) {
        const f = tracy.namedFrame("zigscene");
        defer f.end();
        app.processMusic();
        app.processInput();
        app.render();
        app.executeCallbacks();
        app.t += rl.getFrameTime();
    }
}

test "root" {
    std.testing.refAllDeclsRecursive(@This());
}
