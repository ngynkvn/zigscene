//! Offline benchmark: no window, audio device, or sound output.
//! zig run -O ReleaseSafe -mcpu=baseline --dep frame -Mroot=dev/audio_bench.zig -Mframe=src/audio/analysis/frame.zig
const std = @import("std");
const frame = @import("frame");
const iterations = 100_000;

noinline fn run(comptime simd: bool, input: []const f32, raw: []f32, smooth: []f32, spectrum: []std.math.Complex(f32)) f32 {
    return frame.analyze(simd, input, raw, smooth, spectrum, 0.55, 1);
}
fn measure(comptime simd: bool, io: std.Io) f64 {
    var input: [2048]f32 = undefined;
    for (&input, 0..) |*sample, i| sample.* = @sin(@as(f32, @floatFromInt(i)) * 0.1);
    var raw: [1024]f32 = undefined;
    var smooth: [1024]f32 = @splat(0);
    var spectrum: [1024]std.math.Complex(f32) = undefined;
    const start = std.Io.Clock.awake.now(io);
    for (0..iterations) |_| {
        const rms = run(simd, &input, &raw, &smooth, &spectrum);
        std.mem.doNotOptimizeAway(rms);
        std.mem.doNotOptimizeAway(&raw);
        std.mem.doNotOptimizeAway(&smooth);
        std.mem.doNotOptimizeAway(&spectrum);
    }
    const elapsed = start.durationTo(std.Io.Clock.awake.now(io)).toNanoseconds();
    return @as(f64, @floatFromInt(elapsed)) / iterations;
}
pub fn main(init: std.process.Init) void {
    // Warm both paths, then alternate their order to reduce order bias.
    _ = measure(false, init.io);
    _ = measure(true, init.io);
    for (0..4) |round| {
        var scalar: f64 = undefined;
        var simd: f64 = undefined;
        if (round % 2 == 0) {
            scalar = measure(false, init.io);
            simd = measure(true, init.io);
        } else {
            simd = measure(true, init.io);
            scalar = measure(false, init.io);
        }
        std.debug.print("scalar {d:.0} ns/block, SIMD {d:.0} ns/block, speedup {d:.2}x\n", .{ scalar, simd, scalar / simd });
    }
}
