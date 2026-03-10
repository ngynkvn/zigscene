const std = @import("std");
const processor = @import("processor.zig");

const c = struct {
    extern fn capture_init(device_index: c_uint, sample_rate: c_uint, channels: c_uint) c_int;
    extern fn capture_deinit() void;
    extern fn capture_start() c_int;
    extern fn capture_stop() c_int;
    extern fn capture_is_started() c_int;
    extern fn capture_set_callback(*const fn ([*]const f32, c_uint) callconv(.c) void) void;
    extern fn capture_enumerate_devices(name_buf: [*]u8, name_buf_size: c_uint, max_devices: c_uint) c_uint;
};

pub var active: bool = false;

fn captureCallback(frames: [*]const f32, frame_count: c_uint) callconv(.c) void {
    const buffer: []const f32 = frames[0 .. frame_count * 2];
    processor.processBufferExternal(buffer);
}

pub fn init(device_index: u32) !void {
    c.capture_set_callback(&captureCallback);
    const result = c.capture_init(@intCast(device_index), 44100, 2);
    if (result != 0) return error.CaptureInitFailed;
}

pub fn deinit() void {
    stop();
    c.capture_deinit();
}

pub fn start() !void {
    const result = c.capture_start();
    if (result != 0) return error.CaptureStartFailed;
    active = true;
}

pub fn stop() void {
    _ = c.capture_stop();
    active = false;
}

pub fn toggle() !void {
    if (active) {
        stop();
    } else {
        try start();
    }
}

pub const MAX_DEVICES: u32 = 16;
pub const NAME_ENTRY_SIZE: u32 = 128;

pub fn enumerateDevices(names: *[MAX_DEVICES][NAME_ENTRY_SIZE]u8) u32 {
    return c.capture_enumerate_devices(@ptrCast(names), MAX_DEVICES * NAME_ENTRY_SIZE, MAX_DEVICES);
}
