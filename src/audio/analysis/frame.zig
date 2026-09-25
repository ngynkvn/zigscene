//! Stereo analysis only: never modifies the samples sent to the audio device.
const std = @import("std");
const Complex = std.math.Complex(f32);

/// The scalar path is retained as a reference for tests and benchmarks.
/// Four lanes fit baseline x86-64 SSE; AVX is not required.
pub fn analyze(comptime simd: bool, stereo: []const f32, raw: []f32, smoothed: []f32, spectrum: []Complex, blend: f32, gain: f32) f32 {
    std.debug.assert(stereo.len == raw.len * 2);
    std.debug.assert(smoothed.len == raw.len and spectrum.len == raw.len);
    if (raw.len == 0) return 0;
    var sum: f32 = 0;
    var i: usize = 0;
    if (simd) {
        const V = @Vector(4, f32);
        var energy: V = @splat(0);
        while (i + 4 <= raw.len) : (i += 4) {
            const samples: @Vector(8, f32) = stereo[i * 2 ..][0..8].*;
            const left = @shuffle(f32, samples, undefined, @Vector(4, i32){ 0, 2, 4, 6 });
            const right = @shuffle(f32, samples, undefined, @Vector(4, i32){ 1, 3, 5, 7 });
            const mono = (left + right) * @as(V, @splat(0.5));
            const previous: V = smoothed[i..][0..4].*;
            const next = @as(V, @splat(blend)) * previous + @as(V, @splat(1 - blend)) * mono * @as(V, @splat(gain));
            raw[i..][0..4].* = mono;
            smoothed[i..][0..4].* = @min(@max(next, @as(V, @splat(-2))), @as(V, @splat(2)));
            const combined = left + right;
            inline for (0..4) |lane| spectrum[i + lane] = .init(combined[lane], 0);
            energy += left * left + right * right;
        }
        sum = @reduce(.Add, energy);
    }
    // Handles short blocks and tails without reading beyond the input.
    while (i < raw.len) : (i += 1) {
        const left = stereo[i * 2];
        const right = stereo[i * 2 + 1];
        const mono = (left + right) * 0.5;
        raw[i] = mono;
        smoothed[i] = std.math.clamp(blend * smoothed[i] + (1 - blend) * mono * gain, -2, 2);
        spectrum[i] = .init(left + right, 0);
        sum += left * left + right * right;
    }
    return @sqrt(sum / @as(f32, @floatFromInt(stereo.len)));
}

test "SIMD matches scalar stereo analysis including tails and clamping" {
    var random = std.Random.DefaultPrng.init(42);
    var stereo: [2054]f32 = undefined;
    for (&stereo) |*sample| sample.* = random.random().float(f32) * 8 - 4;
    for ([_]usize{ 0, 1, 3, 4, 7, 1024, 1027 }) |len| {
        for ([_]f32{ 0, 0.55, 0.98, 1 }) |blend| {
            var scalar_raw: [1027]f32 = undefined;
            var vector_raw: [1027]f32 = undefined;
            var scalar_smooth: [1027]f32 = @splat(0.25);
            var vector_smooth = scalar_smooth;
            var scalar_fft: [1027]Complex = undefined;
            var vector_fft: [1027]Complex = undefined;
            const expected = analyze(false, stereo[0 .. len * 2], scalar_raw[0..len], scalar_smooth[0..len], scalar_fft[0..len], blend, 3);
            const actual = analyze(true, stereo[0 .. len * 2], vector_raw[0..len], vector_smooth[0..len], vector_fft[0..len], blend, 3);
            try std.testing.expectApproxEqAbs(expected, actual, 0.00001);
            for (0..len) |i| {
                try std.testing.expectApproxEqAbs(scalar_raw[i], vector_raw[i], 0.00001);
                try std.testing.expectApproxEqAbs(scalar_smooth[i], vector_smooth[i], 0.00001);
                try std.testing.expectEqual(scalar_fft[i], vector_fft[i]);
            }
        }
    }
}

test "silence remains silent" {
    const input: [8]f32 = @splat(0);
    var raw: [4]f32 = undefined;
    var smooth: [4]f32 = @splat(0);
    var spectrum: [4]Complex = undefined;
    try std.testing.expectEqual(@as(f32, 0), analyze(true, &input, &raw, &smooth, &spectrum, 0.55, 1));
    try std.testing.expectEqualSlices(f32, &.{ 0, 0, 0, 0 }, &smooth);
}
