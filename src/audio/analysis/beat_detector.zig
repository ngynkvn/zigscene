const std = @import("std");

// Assuming a sample rate of 44100, 43 samples approximates 1 second
const N = 43;
pub var energy_history: [N]f32 = std.mem.zeroes([N]f32);
pub var history_pos: usize = 0;
pub var beat_sensitivity: f32 = 1.5142857;
pub var var_sensititvity: f32 = -0.0025714;
pub var min_beat_interval = 10;

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

    var local_average: f32 = 0;
    var local_variance: f32 = 0;

    for (energy_history) |energy| {
        local_average += energy;
    }
    local_average /= N;

    for (energy_history) |energy| {
        const d = energy - local_average;
        local_variance += (d * d);
    }
    local_variance /= N - 1;

    energy_history[history_pos] = current_energy;
    history_pos = @mod(history_pos + 1, N);
    // "We can choose with a linear decrease of 'C' with 'V' (the variance)
    // and for example when V → 200, C → 1.0 and when V → 25, C → 1.45 "
    const C = beat_sensitivity + (var_sensititvity * local_variance);

    return C * current_energy > local_average;
}
