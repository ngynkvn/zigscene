const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
});

const Cf32 = std.math.Complex(f32);
pub var curr_buffer = std.mem.zeroes([256:0]f32);
pub var curr_len: usize = 256;
pub var intensity: f32 = 0;
pub var curr_fft = std.mem.zeroes([256]Cf32);
// understand what *this* is?
// a buffer of the stream + the lengtth of the buffer
pub fn audioStreamCallback(ptr: ?*anyopaque, n: c_uint) callconv(.C) void {
    if (ptr == null) return;
    const buffer: []f32 = @as([*]f32, @ptrCast(@alignCast(ptr)))[0..n];
    var l: f32 = 0;
    var r: f32 = 0;
    curr_len = n / 2;
    for (0..curr_len) |fi| {
        l = buffer[fi * 2 + 0];
        r = buffer[fi * 2 + 1];
        // Damping
        curr_buffer[fi] += (l + r) / 4;
        curr_buffer[fi] *= 0.97;
        // No Damping
        curr_fft[fi] = Cf32.init(l + r, 0);
        intensity = (l + r);
    }
    intensity /= @floatFromInt(curr_len);
    fft(curr_fft[0..curr_len]);
}

fn fft(values: []Cf32) void {
    const N = values.len;
    if (N <= 1) return;
    var parts = std.mem.zeroes([2][128]Cf32);
    var pi: [2]usize = .{ 0, 0 };
    for (values, 0..) |v, i| {
        parts[i % 2][pi[i % 2]] = v;
        pi[i % 2] += 1;
    }
    const evens = parts[0][0..pi[0]];
    const odds = parts[1][0..pi[1]];
    fft(evens);
    fft(odds);
    for (0..N / 2) |i| {
        const index = Cf32.init(
            @cos(-2 * std.math.pi * @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(N))),
            @sin(-2 * std.math.pi * @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(N))),
        ).mul(odds[i]);
        values[i] = evens[i].add(index);
        values[i + N / 2] = evens[i].sub(index);
    }
}
