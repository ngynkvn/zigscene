//! Init sequence for the GUI / Window
const std = @import("std");

const rl = @import("../raylib.zig");
const Config = @import("config.zig");
pub var screenWidth: c_int = Config.Window.width;
pub var screenHeight: c_int = Config.Window.height;
const APP_NAME = Config.Window.title;
const event = @import("event.zig");

pub fn startup(process_args: std.process.Args) !void {
    // TODO: Options menu
    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE | rl.FLAG_WINDOW_TRANSPARENT | rl.FLAG_WINDOW_TOPMOST);

    // Setup
    rl.InitWindow(screenWidth, screenHeight, APP_NAME);

    rl.InitAudioDevice();

    rl.GuiSetAlpha(0.8);
    rl.RayguiDark();
    var buffer: [256]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var args = try std.process.Args.Iterator.initAllocator(process_args, fba.allocator());
    defer args.deinit();
    if (args.skip()) {
        if (args.next()) |path| event.onFilenameInput(path);
    }

    rl.SetMasterVolume(Config.Audio.volume);
}
pub fn shutdown() void {
    rl.CloseAudioDevice();
    rl.CloseWindow(); // Close window and OpenGL context
}

