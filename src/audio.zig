const std = @import("std");
const c = @import("raylib.zig").c;
const asF32 = @import("extras.zig").asF32;

const N = 256;
const Cf32 = std.math.Complex(f32);
var audio_buffer = std.mem.zeroes([N]f32);
var fft_buffer = std.mem.zeroes([N]Cf32);
pub var avg_intensity: f32 = 0;

pub var curr_buffer: []f32 = &audio_buffer;
pub var curr_fft: []Cf32 = &fft_buffer;
/// Accepts a buffer of the stream + the length of the buffer
/// The buffer is composed of PCM samples from the audio stream
/// passed to raylib / miniaudio.h
pub fn audioStreamCallback(ptr: ?*anyopaque, n: c_uint) callconv(.C) void {
    if (ptr == null) return;
    const buffer: []f32 = @as([*]f32, @ptrCast(@alignCast(ptr)))[0..n];
    var l: f32 = 0;
    var r: f32 = 0;
    const curr_len = n / 2;
    for (0..curr_len) |fi| {
        l = buffer[fi * 2 + 0];
        r = buffer[fi * 2 + 1];
        // Damping
        audio_buffer[fi] += (l + r) / 4;
        audio_buffer[fi] *= 0.98;
        // No Damping
        fft_buffer[fi] = Cf32.init(l + r, 0);
        avg_intensity += @abs(l + r) / asF32(curr_len);
        avg_intensity *= 0.99;
    }
    fft(fft_buffer[0..curr_len]);
    curr_buffer = audio_buffer[0..curr_len];
    curr_fft = fft_buffer[0..curr_len];
}

/// https://en.wikipedia.org/wiki/Cooley%E2%80%93Tukey_FFT_algorithm
fn fft(values: []Cf32) void {
    const len = values.len;
    if (len <= 1) return;
    var parts = std.mem.zeroes([2][N / 2]Cf32);
    var pi: [2]usize = .{ 0, 0 };
    for (values, 0..) |v, i| {
        parts[i % 2][pi[i % 2]] = v;
        pi[i % 2] += 1;
    }
    const evens = parts[0][0..pi[0]];
    const odds = parts[1][0..pi[1]];
    fft(evens);
    fft(odds);
    for (0..len / 2) |i| {
        const index = Cf32.init(
            @cos(-2 * std.math.pi * @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(len))),
            @sin(-2 * std.math.pi * @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(len))),
        ).mul(odds[i]);
        values[i] = evens[i].add(index);
        values[i + len / 2] = evens[i].sub(index);
    }
}

fn cf32(comptime raw: []const [2]f32) [raw.len]Cf32 {
    comptime {
        var out = std.mem.zeroes([raw.len]Cf32);
        for (0..raw.len) |i| {
            out[i] = Cf32.init(raw[i][0], raw[i][1]);
        }
        return out;
    }
}
test "fft" {
    const TC_DATA = comptime [_][2][]const Cf32{
        .{
            &cf32(&.{ .{ 0, 7 }, .{ 1, 6 }, .{ 2, 5 }, .{ 3, 4 }, .{ 4, 3 }, .{ 5, 2 }, .{ 6, 1 }, .{ 7, 0 } }),
            &cf32(&.{ .{ 28, 28 }, .{ 5.656, 13.656 }, .{ 0, 8 }, .{ -2.343, 5.656 }, .{ -4, 4 }, .{ -5.656, 2.343 }, .{ -8, 0 }, .{ -13.656, -5.656 } }),
        },

        .{
            &cf32(&.{ .{ 1, 1 }, .{ 1, 1 }, .{ 1, 1 }, .{ 1, 1 }, .{ 1, 1 }, .{ 1, 1 }, .{ 1, 1 }, .{ 1, 1 } }),
            &cf32(&.{ .{ 8, 8 }, .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 } }),
        },

        .{
            &cf32(&.{ .{ 1, -1 }, .{ -1, 1 }, .{ 1, -1 }, .{ -1, 1 }, .{ 1, -1 }, .{ -1, 1 }, .{ 1, -1 }, .{ -1, 1 } }),
            &cf32(&.{ .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 }, .{ 8, -8 }, .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 } }),
        },

        .{
            &cf32(&.{ .{ 1, 0 }, .{ 2, 0 }, .{ 3, 0 }, .{ 4, 0 } }),
            &cf32(&.{ .{ 10, 0 }, .{ -2, 2 }, .{ -2, 0 }, .{ -2, -2 } }),
        },
    };

    var input: [16]Cf32 = undefined;
    for (TC_DATA) |t| {
        const len = t[0].len;
        @memcpy(input[0..len], t[0]);
        fft(input[0..len]);
        for (input[0..len], t[1]) |actual, expected| {
            try std.testing.expectApproxEqAbs(expected.re, actual.re, 0.01);
            try std.testing.expectApproxEqAbs(expected.im, actual.im, 0.01);
        }
    }
}
