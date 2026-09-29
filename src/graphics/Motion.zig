//! Frame-rate independent motion envelope for scene visuals.
const std = @import("std");
const Config = @import("../core/config.zig").Motion;
const Motion = @This();
const max_frame_dt_seconds: f32 = 0.1;
const min_response_seconds: f32 = 0.001;
const max_energy: f32 = 1.5;

energy: f32 = 0,
pulse: f32 = 0,
previous_rms: f32 = 0,

pub fn update(self: *Motion, dt_seconds: f32, rms: f32, beat: bool) void {
    const dt = std.math.clamp(dt_seconds, 0, max_frame_dt_seconds);
    const level = @max(0, rms) * Config.energy_gain;
    const target = std.math.clamp(level / (1 + Config.compression * level), 0, max_energy);
    const time_constant = if (target > self.energy) Config.attack_seconds else Config.release_seconds;
    const blend = 1 - @exp(-dt / @max(time_constant, min_response_seconds));
    self.energy += (target - self.energy) * blend;
    // The rise control shapes gradual swells. Musical onsets must not wait
    // several attack time constants (or the beat detector's initial history).
    if (beat or @import("../audio/analysis/response.zig").isOnset(rms, self.previous_rms)) self.energy = @max(self.energy, target);
    self.previous_rms = rms;
    self.pulse *= @exp(-dt / @max(Config.beat_decay_seconds, min_response_seconds));
    if (beat) self.pulse = 1;
}

test "energy rises, compresses, and decays smoothly" {
    var motion: Motion = .{};
    motion.update(0.016, 100, false);
    try std.testing.expect(motion.energy > 0);
    try std.testing.expect(motion.energy <= 1.5);
    const peak = motion.energy;
    motion.update(0.016, 0, false);
    try std.testing.expect(motion.energy < peak);
    try std.testing.expect(motion.energy > 0);
}

test "beat pulse decays with elapsed time" {
    var motion: Motion = .{};
    motion.update(0.016, 0, true);
    try std.testing.expectEqual(@as(f32, 1), motion.pulse);
    motion.update(0.05, 0, false);
    try std.testing.expect(motion.pulse < 1 and motion.pulse > 0);
}

test "energy response is independent of frame subdivision" {
    // An ongoing swell exercises the envelope, rather than the onset snap.
    var once: Motion = .{ .energy = 0.1, .previous_rms = 0.4 };
    var split = once;
    once.update(0.1, 0.4, false);
    split.update(0.05, 0.4, false);
    split.update(0.05, 0.4, false);
    try std.testing.expectApproxEqAbs(once.energy, split.energy, 0.00001);
}

test "onsets bypass a slow rise while gradual swells and releases stay smooth" {
    const old_attack = Config.attack_seconds;
    defer Config.attack_seconds = old_attack;
    Config.attack_seconds = 0.5;
    var motion: Motion = .{};
    motion.update(1.0 / 144.0, 0.2, false);
    const initial = motion.energy;
    motion.update(1.0 / 144.0, 0.22, false);
    const level = 0.22 * Config.energy_gain;
    const swell_target = std.math.clamp(level / (1 + Config.compression * level), 0, max_energy);
    try std.testing.expect(motion.energy > initial and motion.energy < swell_target);
    motion.update(1.0 / 144.0, 0.5, false);
    const hit = motion.energy;
    motion.update(1.0 / 144.0, 0, false);
    try std.testing.expect(motion.energy > 0 and motion.energy < hit);
}
