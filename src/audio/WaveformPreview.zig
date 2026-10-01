const std = @import("std");
const WaveformPreview = @This();

// Enough detail for wide/Retina views without retaining the decoded track.
pub const bin_count = 8192;
pub const low_hz = 250;
pub const high_hz = 4000;

pub const Bin = struct {
    peak: f32 = 0,
    square_sum: f64 = 0,
    band_square_sum: [3]f64 = @splat(0),
    sample_count: usize = 0,

    pub fn merge(self: *Bin, other: Bin) void {
        self.peak = @max(self.peak, other.peak);
        self.square_sum += other.square_sum;
        for (&self.band_square_sum, other.band_square_sum) |*sum, value| sum.* += value;
        self.sample_count += other.sample_count;
    }

    pub fn rms(self: Bin) f32 {
        if (self.sample_count == 0) return 0;
        return @floatCast(@sqrt(self.square_sum / @as(f64, @floatFromInt(self.sample_count))));
    }

    /// Relative band RMS levels partition the full-band peak envelope.
    pub fn bandWeights(self: Bin) [3]f32 {
        var weights: [3]f32 = undefined;
        var total: f32 = 0;
        for (&weights, self.band_square_sum) |*weight, energy| {
            weight.* = @floatCast(@sqrt(energy));
            total += weight.*;
        }
        if (total > 0) for (&weights) |*weight| {
            weight.* /= total;
        };
        return weights;
    }
};

bins: [bin_count]Bin = @splat(.{}),
len: usize = 0,
revision: u64 = 0,

pub fn clear(self: *WaveformPreview) void {
    @memset(&self.bins, .{});
    self.len = 0;
    self.revision +%= 1;
}

/// Accumulates complete interleaved frames without retaining decoded audio.
pub const Builder = struct {
    const Filters = struct { low: Biquad, mid_low: Biquad, mid_high: Biquad, high: Biquad };
    preview: *WaveformPreview,
    filters: []Filters,
    allocator: std.mem.Allocator,
    total_frames: u64,
    frames: u64 = 0,
    bin_index: usize = 0,

    pub fn init(preview: *WaveformPreview, allocator: std.mem.Allocator, total_frames: u64, channels: usize, sample_rate: u32) !Builder {
        preview.clear();
        if (total_frames == 0 or channels == 0 or sample_rate == 0) return error.InvalidFormat;
        const filters = try allocator.alloc(Filters, channels);
        for (filters) |*filter| filter.* = .{
            .low = Biquad.init(.lowpass, low_hz, sample_rate),
            .mid_low = Biquad.init(.highpass, low_hz, sample_rate),
            .mid_high = Biquad.init(.lowpass, high_hz, sample_rate),
            .high = Biquad.init(.highpass, high_hz, sample_rate),
        };
        preview.len = @intCast(@min(bin_count, total_frames));
        return .{ .preview = preview, .filters = filters, .allocator = allocator, .total_frames = total_frames };
    }

    pub fn deinit(self: *Builder) void {
        self.allocator.free(self.filters);
    }

    pub fn append(self: *Builder, samples: []const f32) void {
        const channels = self.filters.len;
        const count: usize = @intCast(@min(samples.len / channels, self.total_frames - self.frames));
        var offset: usize = 0;
        while (offset < count) {
            // Match the whole-buffer floor boundaries, including uneven bins.
            const end: u64 = @intCast(@as(u128, self.bin_index + 1) * self.total_frames / self.preview.len);
            const take: usize = @intCast(@min(count - offset, end - self.frames));
            const bin = &self.preview.bins[self.bin_index];
            for (self.filters, 0..) |*filter, channel| {
                for (offset..offset + take) |frame| {
                    const raw = samples[frame * channels + channel];
                    const value: f64 = if (std.math.isFinite(raw)) raw else 0;
                    bin.peak = @max(bin.peak, @as(f32, @floatCast(@abs(value))));
                    bin.square_sum += value * value;
                    const bands = [_]f64{ filter.low.process(value), filter.mid_high.process(filter.mid_low.process(value)), filter.high.process(value) };
                    for (&bin.band_square_sum, bands) |*sum, band| sum.* += band * band;
                }
            }
            bin.sample_count += take * channels;
            offset += take;
            self.frames += take;
            if (self.frames == end) self.bin_index += 1;
        }
    }
};

pub fn build(self: *WaveformPreview, samples: []const f32, channels: usize, sample_rate: u32) void {
    if (channels == 0) return self.clear();
    var builder = Builder.init(self, @import("../core/memory.zig").allocator, samples.len / channels, channels, sample_rate) catch return;
    defer builder.deinit();
    builder.append(samples);
}

// Independent whole-buffer reference for chunk-boundary regression tests.
fn buildReference(self: *WaveformPreview, samples: []const f32, channels: usize, sample_rate: u32) void {
    self.clear();
    if (channels == 0 or samples.len < channels or sample_rate == 0) return;

    const frame_count = samples.len / channels;
    self.len = @min(bin_count, frame_count);
    // Process channels independently: out-of-phase stereo must not disappear.
    // Filter state persists across bins, but never across channels or tracks.
    for (0..channels) |channel| {
        var low = Biquad.init(.lowpass, low_hz, sample_rate);
        var mid_low = Biquad.init(.highpass, low_hz, sample_rate);
        var mid_high = Biquad.init(.lowpass, high_hz, sample_rate);
        var high = Biquad.init(.highpass, high_hz, sample_rate);
        for (self.bins[0..self.len], 0..) |*bin, index| {
            const start = index * frame_count / self.len;
            const end = (index + 1) * frame_count / self.len;
            for (start..end) |frame| {
                const raw = samples[frame * channels + channel];
                const value: f64 = if (std.math.isFinite(raw)) raw else 0;
                bin.peak = @max(bin.peak, @as(f32, @floatCast(@abs(value))));
                bin.square_sum += value * value;
                const bands = [_]f64{ low.process(value), mid_high.process(mid_low.process(value)), high.process(value) };
                for (&bin.band_square_sum, bands) |*sum, band| sum.* += band * band;
            }
            bin.sample_count += end - start;
        }
    }
}

/// Aggregate every covered bin; resizing cannot skip a transient.
pub fn column(self: *const WaveformPreview, index: usize, columns: usize) Bin {
    if (self.len == 0 or columns == 0 or index >= columns) return .{};
    const start = index * self.len / columns;
    const end = @min(self.len, @max(start + 1, (index + 1) * self.len / columns));
    var result: Bin = .{};
    for (self.bins[start..end]) |bin| result.merge(bin);
    return result;
}

// Butterworth biquads (Q = 1/sqrt(2)), RBJ coefficients:
// https://www.w3.org/TR/audio-eq-cookbook/
// f64 keeps low-frequency filters stable at high source sample rates.
const Biquad = struct {
    b0: f64,
    b1: f64,
    b2: f64,
    a1: f64,
    a2: f64,
    z1: f64 = 0,
    z2: f64 = 0,

    fn init(kind: enum { lowpass, highpass }, cutoff: f64, sample_rate: u32) Biquad {
        const rate: f64 = @floatFromInt(sample_rate);
        // A band entirely above Nyquist has no energy; bypass its lowpass.
        if (cutoff >= rate / 2) return .{
            .b0 = if (kind == .lowpass) 1 else 0,
            .b1 = 0,
            .b2 = 0,
            .a1 = 0,
            .a2 = 0,
        };
        const omega = 2 * std.math.pi * cutoff / rate;
        const cosine = @cos(omega);
        const alpha = @sin(omega) / @sqrt(@as(f64, 2));
        const a0 = 1 + alpha;
        const b0 = (if (kind == .lowpass) 1 - cosine else 1 + cosine) / (2 * a0);
        return .{
            .b0 = b0,
            .b1 = (if (kind == .lowpass) @as(f64, 2) else -2) * b0,
            .b2 = b0,
            .a1 = -2 * cosine / a0,
            .a2 = (1 - alpha) / a0,
        };
    }

    fn process(self: *Biquad, value: f64) f64 {
        const result = self.b0 * value + self.z1;
        self.z1 = self.b1 * value - self.a1 * result + self.z2;
        self.z2 = self.b2 * value - self.a2 * result;
        return result;
    }
};

test "preview preserves linear amplitude, stereo peaks and short track length" {
    var preview: WaveformPreview = .{};
    preview.build(&.{ -0.25, 0.5, 1, -1, 0, 0 }, 2, 44100);
    try std.testing.expectEqual(@as(usize, 3), preview.len);
    try std.testing.expectEqual(@as(f32, 0.5), preview.bins[0].peak);
    try std.testing.expectEqual(@as(f32, 1), preview.bins[1].peak);
    try std.testing.expectEqual(@as(f32, 0), preview.bins[2].peak);
    try std.testing.expectApproxEqAbs(@as(f32, @sqrt(0.15625)), preview.bins[0].rms(), 0.0001);
}

test "column reduction retains transients and sample-weighted RMS" {
    var preview: WaveformPreview = .{};
    var samples: [bin_count * 2 + 1]f32 = @splat(0);
    samples[123] = 0.25;
    samples[samples.len - 1] = -1;
    preview.build(&samples, 1, 48000);
    const all = preview.column(0, 1);
    try std.testing.expectEqual(@as(f32, 1), all.peak);
    try std.testing.expectEqual(samples.len, all.sample_count);
    try std.testing.expectApproxEqAbs(@as(f32, @sqrt(1.0625 / @as(f32, @floatFromInt(samples.len)))), all.rms(), 0.000001);
    try std.testing.expectEqual(@as(f32, 1), preview.column(136, 137).peak);
    try std.testing.expectEqual(@as(f32, 1), preview.column(bin_count * 2 - 1, bin_count * 2).peak);
}

test "frequency bands identify tones at source sample rates without stereo cancellation" {
    var preview: WaveformPreview = .{};
    var samples: [24000 * 2]f32 = undefined;
    for ([_]u32{ 22050, 44100, 48000, 96000 }) |rate| {
        for ([_]f64{ 80, 1000, 10000 }, 0..) |frequency, expected_band| {
            for (0..samples.len / 2) |frame| {
                const value: f32 = @floatCast(0.5 * @sin(2 * std.math.pi * frequency * @as(f64, @floatFromInt(frame)) / @as(f64, @floatFromInt(rate))));
                samples[frame * 2] = value;
                samples[frame * 2 + 1] = -value;
            }
            preview.build(&samples, 2, rate);
            const result = preview.column(0, 1);
            const energy = result.band_square_sum;
            try std.testing.expect(energy[expected_band] / (energy[0] + energy[1] + energy[2]) > 0.95);
            try std.testing.expectApproxEqAbs(@as(f32, 0.35355), result.rms(), 0.001);
        }
    }
}

test "silence, invalid input and new tracks clear analysis" {
    var preview: WaveformPreview = .{};
    preview.build(&.{1}, 1, 44100);
    preview.build(&.{ 0, 0, 0, 0 }, 1, 44100);
    const silent = preview.column(0, 1);
    try std.testing.expectEqual(@as(f32, 0), silent.peak);
    try std.testing.expectEqual([3]f32{ 0, 0, 0 }, silent.bandWeights());
    preview.build(&.{ std.math.nan(f32), std.math.inf(f32) }, 1, 44100);
    try std.testing.expectEqual(@as(f32, 0), preview.column(0, 1).peak);
    preview.build(&.{1}, 1, 0);
    try std.testing.expectEqual(@as(usize, 0), preview.len);
    preview.build(&.{1}, 0, 44100);
    try std.testing.expectEqual(@as(usize, 0), preview.len);
    preview.build(&.{1}, 2, 44100);
    try std.testing.expectEqual(@as(usize, 0), preview.len);
    preview.build(&.{}, 1, 44100);
    try std.testing.expectEqual(@as(usize, 0), preview.len);
}

test "bands above Nyquist remain empty" {
    var preview: WaveformPreview = .{};
    preview.build(&.{ 0.5, -0.5, 0.5, -0.5 }, 1, 8000);
    try std.testing.expectEqual(@as(f64, 0), preview.column(0, 1).band_square_sum[2]);
}

test "chunked preview matches whole-buffer analysis across uneven boundaries" {
    var samples: [bin_count * 6 + 14]f32 = undefined;
    for (&samples, 0..) |*sample, i| sample.* = @floatCast(@sin(@as(f64, @floatFromInt(i)) * 0.017));
    samples[7] = std.math.nan(f32);
    samples[33] = std.math.inf(f32);
    var reference: WaveformPreview = .{};
    reference.buildReference(&samples, 2, 48000);
    for ([_]usize{ 1, 17, 4096, samples.len / 2 }) |chunk_frames| {
        var preview: WaveformPreview = .{};
        var builder = try Builder.init(&preview, std.testing.allocator, samples.len / 2, 2, 48000);
        defer builder.deinit();
        var offset: usize = 0;
        while (offset < samples.len) {
            const end = @min(samples.len, offset + chunk_frames * 2);
            builder.append(samples[offset..end]);
            offset = end;
        }
        builder.append(&.{ 1, 1 }); // Extra decoded data must not overrun the bins.
        try std.testing.expectEqual(reference.len, preview.len);
        for (reference.bins, preview.bins) |expected, actual| {
            try std.testing.expectEqual(expected.peak, actual.peak);
            try std.testing.expectEqual(expected.sample_count, actual.sample_count);
            try std.testing.expectApproxEqAbs(expected.square_sum, actual.square_sum, 1e-10);
            for (expected.band_square_sum, actual.band_square_sum) |a, b| try std.testing.expectApproxEqAbs(a, b, 1e-10);
        }
    }
}
