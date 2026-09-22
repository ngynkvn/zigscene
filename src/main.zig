const std = @import("std");
const builtin = @import("builtin");
const App = @import("App.zig");
const cli = @import("core/cli.zig");

pub const panic = if (builtin.os.tag == .emscripten)
    std.debug.FullPanic(webPanic)
else
    std.debug.FullPanic(std.debug.defaultPanic);
// Zig 0.16's default debug I/O instantiates unsupported process waiting code
// for Emscripten. Web panics trap directly, so no debug I/O is needed there.
pub const std_options_debug_threaded_io: ?*std.Io.Threaded = if (builtin.os.tag == .emscripten)
    null
else
    std.Io.Threaded.global_single_threaded;
pub const std_options_debug_io: std.Io = if (builtin.os.tag == .emscripten)
    undefined
else
    std.Io.Threaded.global_single_threaded.io();

fn webPanic(_: []const u8, _: ?usize) noreturn {
    @trap();
}

var web_app: ?App = null;

fn webFrame() callconv(.c) void {
    web_app.?.frame();
}

pub fn main(process_init: std.process.Init.Minimal) !void {
    if (builtin.os.tag == .emscripten) {
        web_app = App.create(.{});
        emscripten_set_main_loop(webFrame, 0, 1);
        return;
    }

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const args = try process_init.args.toSlice(allocator);
    const plain_args = try allocator.alloc([]const u8, args.len - 1);
    for (args[1..], plain_args) |arg, *plain| plain.* = arg;
    const options = cli.parse(plain_args) catch |err| {
        std.debug.print("Invalid command line: {s}\n", .{@errorName(err)});
        return err;
    };

    var app = App.create(options);
    defer app.destroy();
    app.run();
}

extern fn emscripten_set_main_loop(callback: *const fn () callconv(.c) void, fps: c_int, simulate_infinite_loop: c_int) void;

test "root" {
    _ = @import("audio/playback.zig");
    _ = @import("audio/processor.zig");
    _ = @import("graphics.zig");
    _ = @import("gui.zig");
    _ = @import("core/debug.zig");
    _ = @import("core/config.zig");
}
