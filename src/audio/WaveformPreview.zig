const std = @import("std");

pub const bin_count = 512;

peaks: [bin_count]f32 = @splat(0),
available: bool = false,

pub fn clear(self: *WaveformPreview) void {
    self.* = .{};
}

pub fn build(self: *WaveformPreview, samples: []const f32, channels: usize) void {
    self.clear();
    if (channels == 0 or samples.len < channels) return;

    const frame_count = samples.len / channels;
    var largest: f32 = 0;
    for (&self.peaks, 0..) |*peak, bin| {
        const start = bin * frame_count / bin_count;
        const end = @max(start + 1, (bin + 1) * frame_count / bin_count);
        for (start..@min(end, frame_count)) |frame| {
            var amplitude: f32 = 0;
            for (0..channels) |channel| {
                amplitude = @max(amplitude, @abs(samples[frame * channels + channel]));
            }
            peak.* = @max(peak.*, amplitude);
        }
        largest = @max(largest, peak.*);
    }

    if (largest > 0) {
        for (&self.peaks) |*peak| peak.* = @sqrt(peak.* / largest);
    }
    self.available = true;
}

const WaveformPreview = @This();

test "build reduces stereo samples into normalized peaks" {
    var preview: WaveformPreview = .{};
    var samples: [bin_count * 2]f32 = @splat(0);
    samples[0] = -0.25;
    samples[1] = 0.5;
    samples[samples.len - 2] = 1;
    preview.build(&samples, 2);

    try std.testing.expect(preview.available);
    try std.testing.expectApproxEqAbs(@as(f32, @sqrt(0.5)), preview.peaks[0], 0.0001);
    try std.testing.expectEqual(@as(f32, 1), preview.peaks[bin_count - 1]);
}

test "build rejects empty or invalid channel data" {
    var preview: WaveformPreview = .{ .available = true };
    preview.build(&.{}, 0);
    try std.testing.expect(!preview.available);
}
