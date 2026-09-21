//! Frame-rate independent motion envelope for scene visuals.
const std = @import("std");
const Config = @import("../core/config.zig").Motion;
const Motion = @This();
const max_frame_dt_seconds: f32 = 0.1;
const min_response_seconds: f32 = 0.001;
const max_energy: f32 = 1.5;

energy: f32 = 0,
pulse: f32 = 0,

pub fn update(self: *Motion, dt_seconds: f32, rms: f32, beat: bool) void {
    const dt = std.math.clamp(dt_seconds, 0, max_frame_dt_seconds);
    const level = @max(0, rms) * Config.energy_gain;
    const target = std.math.clamp(level / (1 + Config.compression * level), 0, max_energy);
    const time_constant = if (target > self.energy) Config.attack_seconds else Config.release_seconds;
    const blend = 1 - @exp(-dt / @max(time_constant, min_response_seconds));
    self.energy += (target - self.energy) * blend;
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
    var once: Motion = .{};
    var split: Motion = .{};
    once.update(0.1, 0.4, false);
    split.update(0.05, 0.4, false);
    split.update(0.05, 0.4, false);
    try std.testing.expectApproxEqAbs(once.energy, split.energy, 0.00001);
}
