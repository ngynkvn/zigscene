const std = @import("std");
const tracy = @import("tracy");

const controls = @import("gui/controls.zig");
const asF32 = @import("extras.zig").asF32;

pub const Controls = struct {
    pub const Scalars = [_]controls.Scalar{
        .{ .name = "Attack", .value = &Attack, .range = .{ 0.0, 1 } },
        .{ .name = "Release", .value = &Release, .range = .{ 0.0, 1 } },
    };
};

const N = 256;
var Attack: f32 = 0.8;
var Release: f32 = 0.6;
comptime {
    @setFloatMode(.optimized);
}
const ComplexF32 = std.math.Complex(f32);
/// Currently loaded audio buffer data
var audio_buffer = std.mem.zeroes([N]f32);
/// Currently loaded buffer for fft data
var fft_buffer = std.mem.zeroes([N]ComplexF32);
/// Root mean square of signal
pub var rms_energy: f32 = 0;

pub var curr_buffer: []f32 = &audio_buffer;
pub var curr_fft: []ComplexF32 = &fft_buffer;

/// Accepts a buffer of the stream + the length of the buffer
/// The buffer is composed of PCM samples from the audio stream
/// that were passed to raylib / miniaudio.h
pub fn audioStreamCallback(ptr: ?*anyopaque, n: c_uint) callconv(.C) void {
    if (ptr == null) return;
    const ctx = tracy.traceNamed(@src(), "audio_stream");
    defer ctx.end();
    const buffer: []f32 = @as([*]f32, @ptrCast(@alignCast(ptr)))[0..n];
    var l: f32 = 0;
    var r: f32 = 0;
    var rms: f32 = 0;
    const curr_len = n / 2;
    const ool: f32 = 1 / @as(f32, @floatFromInt(curr_len));
    for (0..curr_len) |fi| {
        l = buffer[fi * 2 + 0];
        r = buffer[fi * 2 + 1];
        const x = (l + r) * 0.5;
        audio_buffer[fi] =
            (Attack * x) +
            (Release * audio_buffer[fi]);

        fft_buffer[fi] = ComplexF32.init(l + r, 0);
        rms += (x * x);
    }
    rms_energy = 0.65 * rms_energy + 0.90 * @sqrt(rms * ool);
    fft(fft_buffer[0..curr_len]);
    curr_buffer = audio_buffer[0..curr_len];
    curr_fft = fft_buffer[0..curr_len];
}

/// https://en.wikipedia.org/wiki/Cooley%E2%80%93Tukey_FFT_algorithm
fn fft(values: []ComplexF32) void {
    const len = values.len;
    if (len <= 1) return;
    var parts = std.mem.zeroes([2][N / 2]ComplexF32);
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
        const index = ComplexF32.init(
            @cos(-2 * std.math.pi * @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(len))),
            @sin(-2 * std.math.pi * @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(len))),
        ).mul(odds[i]);
        values[i] = evens[i].add(index);
        values[i + len / 2] = evens[i].sub(index);
    }
}

test "fft" {
    const globals = struct {
        fn cf32(comptime raw: []const [2]f32) [raw.len]ComplexF32 {
            comptime {
                var out = std.mem.zeroes([raw.len]ComplexF32);
                for (0..raw.len) |i| {
                    out[i] = ComplexF32.init(raw[i][0], raw[i][1]);
                }
                return out;
            }
        }
        const TC_DATA = [_][2][]const ComplexF32{
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
    };

    var input: [16]ComplexF32 = undefined;
    for (globals.TC_DATA) |t| {
        const len = t[0].len;
        @memcpy(input[0..len], t[0]);
        fft(input[0..len]);
        for (input[0..len], t[1]) |actual, expected| {
            try std.testing.expectApproxEqAbs(expected.re, actual.re, 0.01);
            try std.testing.expectApproxEqAbs(expected.im, actual.im, 0.01);
        }
    }
}
