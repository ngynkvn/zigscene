const std = @import("std");
const builtin = @import("builtin");
const processor = @import("processor.zig");
const AudioConfig = @import("../core/config.zig").Audio;

const c = struct {
    extern fn zigscene_capture_start(c_int, c_int, c_uint, c_uint, *const fn ([*]const f32, c_uint) callconv(.c) void) c_int;
    extern fn zigscene_capture_stop() void;
    extern fn zigscene_capture_list(c_int, [*]u8, c_uint, c_uint) c_uint;
    extern fn zigscene_capture_select(c_int, c_int) c_int;
    extern fn zigscene_capture_selected_index(c_int) c_int;
};

pub const Mode = enum(c_int) { input = 0, system = 1 };
pub var active = false;
pub var mode: Mode = .system;

pub const Devices = struct {
    names: [32][256]u8 = @splat(@splat(0)),
    count: usize = 0,

    pub fn name(self: *const Devices, index: usize) [:0]const u8 {
        return std.mem.span(@as([*:0]const u8, @ptrCast(&self.names[index])));
    }
};

pub fn enumerate(kind: Mode) Devices {
    var result: Devices = .{};
    if (builtin.os.tag != .emscripten) {
        result.count = c.zigscene_capture_list(@intFromEnum(kind), @ptrCast(&result.names), result.names.len, result.names[0].len);
    }
    return result;
}

pub fn selectDevice(kind: Mode, index: i32) bool {
    if (builtin.os.tag == .emscripten) return false;
    return c.zigscene_capture_select(@intFromEnum(kind), index) != 0;
}

pub fn selectedIndex(kind: Mode) i32 {
    if (builtin.os.tag == .emscripten) return -1;
    return c.zigscene_capture_selected_index(@intFromEnum(kind));
}

pub fn startSelected(kind: Mode) !void {
    // The bridge retains a device ID, independent of the latest enumeration order.
    const index = selectedIndex(kind);
    if (index == -2) return error.CaptureDeviceUnavailable;
    try start(kind, if (index == -1) -1 else -2);
}

fn onFrames(samples: [*]const f32, count: c_uint) callconv(.c) void {
    processor.submitCapture(samples[0 .. @as(usize, count) * AudioConfig.channels]);
}

pub fn start(new_mode: Mode, device_index: i32) !void {
    if (builtin.os.tag == .emscripten) return error.CaptureUnsupported;
    if (active) stop();
    const result = c.zigscene_capture_start(@intFromEnum(new_mode), device_index, AudioConfig.channels, AudioConfig.sample_rate, onFrames);
    if (result != 0) {
        std.debug.print("Audio capture failed (miniaudio error {d}). Choose a device in Audio devices or use --list-audio-devices.\n", .{result});
        return error.CaptureFailed;
    }
    mode = new_mode;
    active = true;
}

pub fn stop() void {
    if (builtin.os.tag == .emscripten) {
        active = false;
        return;
    }
    if (!active) return;
    c.zigscene_capture_stop();
    active = false;
}

pub fn listDevices() void {
    if (builtin.os.tag == .emscripten) {
        std.debug.print("Audio capture is not available in the web build.\n", .{});
        return;
    }
    for ([_]Mode{ .system, .input }) |kind| {
        if (builtin.os.tag == .macos and kind == .system) {
            std.debug.print("System audio requires a routed loopback input, such as BlackHole.\n", .{});
        } else if (builtin.os.tag != .windows and kind == .system) {
            std.debug.print("System audio uses a capture device named Monitor.\n", .{});
        }
        const devices = enumerate(kind);
        std.debug.print("{s} audio devices:\n", .{if (kind == .system) "System" else "Input"});
        for (0..devices.count) |i| {
            std.debug.print("  {d}: {s}\n", .{ i, devices.name(i) });
        }
    }
}
