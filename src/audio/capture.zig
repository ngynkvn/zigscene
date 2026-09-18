const std = @import("std");
const builtin = @import("builtin");
const processor = @import("processor.zig");
const Config = @import("../core/config.zig");

const c = struct {
    extern fn zigscene_capture_start(c_int, c_int, *const fn ([*]const f32, c_uint) callconv(.c) void) c_int;
    extern fn zigscene_capture_stop() void;
    extern fn zigscene_capture_list(c_int, [*]u8, c_uint, c_uint) c_uint;
};

pub const Mode = enum(c_int) { input = 0, system = 1 };
pub var active = false;
pub var mode: Mode = .system;

var pending: [Config.Audio.buffer_size * 2]f32 = undefined;
var pending_frames: usize = 0;

fn onFrames(samples: [*]const f32, count: c_uint) callconv(.c) void {
    var source = samples[0 .. @as(usize, count) * 2];
    while (source.len != 0) {
        const n = @min(source.len, pending.len - pending_frames * 2);
        @memcpy(pending[pending_frames * 2 ..][0..n], source[0..n]);
        pending_frames += n / 2;
        source = source[n..];
        if (pending_frames == Config.Audio.buffer_size) {
            processor.processBuffer(pending[0..]);
            pending_frames = 0;
        }
    }
}

pub fn start(new_mode: Mode, device_index: i32) !void {
    if (builtin.os.tag == .emscripten) return error.CaptureUnsupported;
    if (active) stop();
    pending_frames = 0;
    const result = c.zigscene_capture_start(@intFromEnum(new_mode), device_index, onFrames);
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
