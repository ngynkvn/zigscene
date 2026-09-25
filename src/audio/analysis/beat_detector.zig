const std = @import("std");
const AudioConfig = @import("../../core/config.zig").Audio;

// One energy value is measured per analysis block, so this covers about one second.
const N = @divTrunc(@as(usize, AudioConfig.sample_rate), AudioConfig.buffer_size);
/// Blocks of history (~190 ms) needed before the average is meaningful.
const min_history = 8;
const beat_sensitivity: f32 = 1.5142857;
const variance_sensitivity: f32 = -0.0025714;

var energy_history: [N]f32 = @splat(0);
var history_pos: usize = 0;
var history_len: usize = 0;

pub fn reset() void {
    energy_history = @splat(0);
    history_pos = 0;
    history_len = 0;
}

/// The core concept comes from the observation that musical beats often
/// come with sudden spikes in the energy of the signal So, we can try to
/// detect the beat by checking the current energy level against the mean
/// and variance of recent samples
///
/// - energy as `E(n) = sum(i**2)/n`
/// - beat = `if (E(n) > C*avg(E(n))) true else false`
/// This is a very basic version based on:
/// https://archive.gamedev.net/archive/reference/programming/features/beatdetection/index.html
pub fn process(buffer: []const f32) bool {
    var current_energy: f32 = 0;
    for (buffer) |sample| current_energy += sample * sample;
    current_energy = current_energy / @as(f32, @floatFromInt(buffer.len));

    // Only filled entries count, so zeroed history after a reset cannot fake a spike.
    const beat = history_len >= min_history and isSpike(energy_history[0..history_len], current_energy);
    energy_history[history_pos] = current_energy;
    history_pos = (history_pos + 1) % N;
    history_len = @min(history_len + 1, N);
    return beat;
}

fn isSpike(history: []const f32, current_energy: f32) bool {
    var local_average: f32 = 0;
    for (history) |energy| local_average += energy;
    local_average /= @floatFromInt(history.len);

    var local_variance: f32 = 0;
    for (history) |energy| {
        const d = energy - local_average;
        local_variance += (d * d);
    }
    local_variance /= @floatFromInt(history.len - 1);

    // "We can choose with a linear decrease of 'C' with 'V' (the variance)
    // and for example when V → 200, C → 1.0 and when V → 25, C → 1.45 "
    const C = beat_sensitivity + (variance_sensitivity * local_variance);

    return current_energy > C * local_average;
}

fn constantBlock(level: f32) [AudioConfig.buffer_size * AudioConfig.channels]f32 {
    return @splat(level);
}

test "steady signal is not a beat, a sudden spike is" {
    reset();
    defer reset();
    const steady = constantBlock(0.2);
    for (0..N * 2) |_| try std.testing.expect(!process(&steady));
    const spike = constantBlock(0.4);
    try std.testing.expect(process(&spike));
}

test "no beats while history warms up after a reset" {
    reset();
    defer reset();
    const loud = constantBlock(0.5);
    for (0..min_history) |_| try std.testing.expect(!process(&loud));
    // The average now reflects real audio, not the zeroed history.
    try std.testing.expect(!process(&loud));
}

test "quiet passages still register relative spikes" {
    reset();
    defer reset();
    const quiet = constantBlock(0.01);
    for (0..N) |_| _ = process(&quiet);
    const hit = constantBlock(0.02);
    try std.testing.expect(process(&hit));
}
