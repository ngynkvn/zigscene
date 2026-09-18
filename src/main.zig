const std = @import("std");
const App = @import("App.zig");
const cli = @import("core/cli.zig");

pub fn main(process_init: std.process.Init) !void {
    const args = try process_init.minimal.args.toSlice(process_init.arena.allocator());
    const plain_args = try process_init.arena.allocator().alloc([]const u8, args.len - 1);
    for (args[1..], plain_args) |arg, *plain| plain.* = arg;
    const options = cli.parse(plain_args) catch |err| {
        std.debug.print("Invalid command line: {s}\n", .{@errorName(err)});
        return err;
    };

    var app = App.create(options);
    defer app.destroy();
    app.run();
}

test "root" {
    _ = @import("audio/playback.zig");
    _ = @import("audio/processor.zig");
    _ = @import("graphics.zig");
    _ = @import("gui.zig");
    _ = @import("core/debug.zig");
    _ = @import("core/config.zig");
}
