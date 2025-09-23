const std = @import("std");
const tracy = @import("tracy");

const Config = @import("../../core/config.zig");
const N = Config.Audio.buffer_size;

pub const ComplexF32 = std.math.Complex(f32);
/// https://en.wikipedia.org/wiki/Cooley%E2%80%93Tukey_FFT_algorithm
pub fn fft(values: []ComplexF32) void {
    // const t = tracy.traceNamed(@src(), "fft");
    // defer t.end();
    const len = values.len;
    if (len <= 1) return;
    var it = std.mem.window(ComplexF32, values, 2, 2);
    var evens = std.mem.zeroes([N / 2]ComplexF32);
    var odds = std.mem.zeroes([N / 2]ComplexF32);
    for (&evens, &odds) |*e, *o| {
        const w = it.next() orelse break;
        if (w.len != 2) break;
        const ev = w[0];
        const od = w[1];
        e.* = ev;
        o.* = od;
    }
    fft(evens[0 .. len / 2]);
    fft(odds[0 .. len / 2]);
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
                var out: [raw.len]ComplexF32 = @splat(.init(0, 0));
                for (raw, &out) |v, *i| i.* = .init(v[0], v[1]);
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
