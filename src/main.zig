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

    const preferences = @import("core/preferences.zig");
    const preferences_path = preferences.path(process_init.environ, allocator) catch null;
    preferences.load(preferences_path);
    var app = App.create(options);
    app.preferences_path = preferences_path;
    defer app.destroy();
    app.run();
}

extern fn emscripten_set_main_loop(callback: *const fn () callconv(.c) void, fps: c_int, simulate_infinite_loop: c_int) void;

extern fn zigscene_test_capture_selection() c_int;
test "capture selection survives device reorder and detects removal" {
    if (builtin.os.tag != .emscripten) try std.testing.expectEqual(@as(c_int, 0), zigscene_test_capture_selection());
}

test "root" {
    _ = @import("audio/playback.zig");
    _ = @import("audio/Session.zig");
    _ = @import("audio/WaveformPreview.zig");
    _ = @import("audio/processor.zig");
    _ = @import("graphics.zig");
    _ = @import("graphics/Highlight.zig");
    _ = @import("graphics/Viewport.zig");
    _ = @import("graphics/visualizers/spectrum.zig");
    _ = @import("gui.zig");
    _ = @import("gui/Cursor.zig");
    _ = @import("core/debug.zig");
    _ = @import("core/config.zig");
    _ = @import("core/input.zig");
    _ = @import("core/preferences.zig");
    _ = @import("scripting/tests.zig");
}
