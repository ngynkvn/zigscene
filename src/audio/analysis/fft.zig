const std = @import("std");

const N = @import("../../core/config.zig").Audio.buffer_size;

pub const ComplexF32 = std.math.Complex(f32);

comptime {
    if (!std.math.isPowerOfTwo(N)) @compileError("FFT buffer size must be a power of two");
}

/// twiddles[j] = e^(-2πij/N); shared by every power-of-two length up to N.
const twiddles = blk: {
    @setEvalBranchQuota(100_000);
    var table: [N / 2]ComplexF32 = undefined;
    for (&table, 0..) |*w, j| {
        const angle = -2 * std.math.pi * @as(f64, @floatFromInt(j)) / @as(f64, @floatFromInt(N));
        w.* = .init(@floatCast(@cos(angle)), @floatCast(@sin(angle)));
    }
    break :blk table;
};

/// In-place iterative radix-2 Cooley-Tukey FFT. `values.len` must be a power of two no larger than N.
/// https://en.wikipedia.org/wiki/Cooley%E2%80%93Tukey_FFT_algorithm
pub fn fft(values: []ComplexF32) void {
    const len = values.len;
    if (len <= 1) return;
    std.debug.assert(std.math.isPowerOfTwo(len) and len <= N);
    const shift: std.math.Log2Int(usize) = @intCast(@bitSizeOf(usize) - @as(usize, std.math.log2_int(usize, len)));
    for (0..len) |i| {
        const j = @bitReverse(i) >> shift;
        if (i < j) std.mem.swap(ComplexF32, &values[i], &values[j]);
    }
    var size: usize = 2;
    while (size <= len) : (size *= 2) {
        const half = size / 2;
        const stride = N / size;
        var start: usize = 0;
        while (start < len) : (start += size) {
            for (0..half) |k| {
                const t = twiddles[k * stride].mul(values[start + k + half]);
                const u = values[start + k];
                values[start + k] = u.add(t);
                values[start + k + half] = u.sub(t);
            }
        }
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

test "fft matches a direct DFT at the analysis block size" {
    var random = std.Random.DefaultPrng.init(7);
    var input: [N]ComplexF32 = undefined;
    for (&input) |*value| value.* = .init(random.random().float(f32) * 2 - 1, 0);
    var actual = input;
    fft(&actual);
    for ([_]usize{ 0, 1, 37, N / 4, N / 2, N - 1 }) |k| {
        var re: f64 = 0;
        var im: f64 = 0;
        for (input, 0..) |value, n| {
            const angle = -2 * std.math.pi * @as(f64, @floatFromInt(k * n % N)) / @as(f64, @floatFromInt(N));
            re += value.re * @cos(angle);
            im += value.re * @sin(angle);
        }
        try std.testing.expectApproxEqAbs(@as(f32, @floatCast(re)), actual[k].re, 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, @floatCast(im)), actual[k].im, 0.001);
    }
}
