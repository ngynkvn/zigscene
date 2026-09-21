const std = @import("std");
const builtin = @import("builtin");
const processor = @import("processor.zig");
const AudioConfig = @import("../core/config.zig").Audio;

const c = struct {
    extern fn zigscene_capture_start(c_int, c_int, c_uint, c_uint, *const fn ([*]const f32, c_uint) callconv(.c) void) c_int;
    extern fn zigscene_capture_stop() void;
    extern fn zigscene_capture_list(c_int, [*]u8, c_uint, c_uint) c_uint;
};

pub const Mode = enum(c_int) { input = 0, system = 1 };
pub var active = false;
pub var mode: Mode = .system;

fn onFrames(samples: [*]const f32, count: c_uint) callconv(.c) void {
    processor.submitCapture(samples[0 .. @as(usize, count) * AudioConfig.channels]);
}

pub fn start(new_mode: Mode, device_index: i32) !void {
    if (builtin.os.tag == .emscripten) return error.CaptureUnsupported;
    if (active) stop();
    const result = c.zigscene_capture_start(@intFromEnum(new_mode), device_index, AudioConfig.channels, AudioConfig.sample_rate, onFrames);
    if (result != 0) {
        std.debug.print("Audio capture failed (miniaudio error {d}). List devices with --list-audio-devices.\n", .{result});
        return error.CaptureFailed;
    }
    mode = new_mode;
    active = true;
}

pub fn stop() void {
    if (!active) return;
    c.zigscene_capture_stop();
    active = false;
}

pub fn listDevices() void {
    var names: [32][128]u8 = @splat(@splat(0));
    for ([_]Mode{ .system, .input }) |kind| {
        if (builtin.os.tag != .windows and kind == .system) {
            std.debug.print("System audio uses a capture device named Monitor.\n", .{});
        }
        const count = c.zigscene_capture_list(@intFromEnum(kind), @ptrCast(&names), names.len, names[0].len);
        std.debug.print("{s} audio devices:\n", .{if (kind == .system) "System" else "Input"});
        for (names[0..count], 0..) |name, i| {
            std.debug.print("  {d}: {s}\n", .{ i, std.mem.sliceTo(&name, 0) });
        }
    }
}
