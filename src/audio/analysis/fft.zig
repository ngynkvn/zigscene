const std = @import("std");

const Config = @import("../../core/config.zig");
const N = Config.Audio.buffer_size;
const cnv = @import("../../ext/convert.zig");
const ffi = cnv.ffi;

pub const ComplexF32 = std.math.Complex(f32);
/// https://en.wikipedia.org/wiki/Cooley%E2%80%93Tukey_FFT_algorithm
pub fn fft(values: []ComplexF32) void {
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
            @cos(-2 * std.math.pi * ffi(f32, i) / ffi(f32, len)),
            @sin(-2 * std.math.pi * ffi(f32, i) / ffi(f32, len)),
        ).mul(odds[i]);
        values[i] = evens[i].add(index);
        values[i + len / 2] = evens[i].sub(index);
    }
}

test "fft" {
    const globals = struct {
        fn cf32(comptime raw: []const [2]f32) [raw.len]ComplexF32 {
            comptime {
                var out: [raw.len]ComplexF32 = @splat(.init(0, 0));
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
