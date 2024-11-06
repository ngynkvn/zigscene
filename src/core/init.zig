//! Init sequence for the GUI / Window
const std = @import("std");

const music = @import("../audio/playback.zig");
const rl = @import("../raylib.zig");
const rg = @import("../raygui.zig");
const Config = @import("config.zig");
pub var screenWidth: c_int = Config.Window.width;
pub var screenHeight: c_int = Config.Window.height;
const APP_NAME = Config.Window.title;
const event = @import("event.zig");

pub fn startup() !void {
    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE);

    // Setup
    rl.InitWindow(screenWidth, screenHeight, APP_NAME);

    rl.InitAudioDevice();

    rg.GuiSetAlpha(0.8);
    rl.RayguiDark();
    if (try processArgs()) |path| {
        event.onFilenameInput(path);
    }

    rl.SetMasterVolume(Config.Audio.volume);
}
pub fn shutdown() void {
    rl.CloseAudioDevice();
    rl.CloseWindow(); // Close window and OpenGL context
}

fn processArgs() !?[]const u8 {
    var buffer: [256]u8 = @splat(0);
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    var args = try std.process.argsWithAllocator(allocator);
    return if (!args.skip()) null else args.next();
}
