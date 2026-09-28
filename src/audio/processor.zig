const std = @import("std");

const Config = @import("../core/config.zig");
const N = Config.Audio.buffer_size;
const channels = Config.Audio.channels;
const max_blocks_per_frame = 4;
const beat_retrigger_blocks = 8;
comptime {
    if (channels != 2) @compileError("audio analysis expects stereo input");
}
const frame_analysis = @import("analysis/frame.zig");
const beat = @import("analysis/beat_detector.zig");
const fft = @import("analysis/fft.zig");
const SampleQueue = @import("SampleQueue.zig");
var samples: SampleQueue = .{};

/// Currently loaded audio buffer data
var audio_buffer = std.mem.zeroes([N]f32);
/// Unsmoothed mono samples written by frame analysis.
var raw_sample = std.mem.zeroes([N]f32);

// Buffer states
pub var curr_buffer: []f32 = &audio_buffer;
pub var curr_fft: []fft.ComplexF32 = &fft_buffer;

/// Currently loaded buffer for fft data
var fft_buffer = std.mem.zeroes([N]fft.ComplexF32);

// Analysis
pub var on_beat = false;
var beat_cooldown: usize = 0;
/// Peak block RMS since the previous render frame, so short hits survive batching.
pub var rms_energy: f32 = 0;
const audio_hold_seconds: f32 = 0.12;
var seconds_since_audio: f32 = 0;
/// Space holds maximum smoothing for analysis only. It never writes the
/// setting, so it cannot leak into saved preferences or Lua setting rollback.
pub var smoothing_held = false;
const held_blend: f32 = 0.98;

/// Accepts a buffer of the stream + the length of the buffer
/// The buffer is composed of PCM samples from the audio stream
/// that were passed to raylib / miniaudio.h
pub fn audioStreamCallback(ptr: ?*anyopaque, frames: c_uint) callconv(.c) void {
    const data = ptr orelse return;
    const buffer: []const f32 = @as([*]f32, @ptrCast(@alignCast(data)))[0 .. frames * channels];
    samples.submit(.file, buffer);
}

pub fn submitCapture(buffer: []const f32) void {
    samples.submit(.capture, buffer);
}

pub fn selectSource(source: SampleQueue.Source) void {
    samples.selectSource(source);
    seconds_since_audio = 0;
    clearAnalysis();
}

fn clearAnalysis() void {
    @memset(&audio_buffer, 0);
    @memset(&raw_sample, 0);
    @memset(&fft_buffer, .init(0, 0));
    rms_energy = 0;
    on_beat = false;
    beat_cooldown = 0;
    beat.reset();
}

/// Run fixed-size analysis on the render thread, outside device callbacks.
pub fn update(dt: f32) bool {
    var blocks: [max_blocks_per_frame][N * channels]f32 = undefined;
    const count = samples.popLatestBlocks(&blocks);
    on_beat = false;
    if (count == 0) {
        seconds_since_audio += @max(0, dt);
        // Capture can stop delivering callbacks altogether. Expire waveform,
        // spectrum and Lua RMS together instead of freezing their last values.
        if (seconds_since_audio >= audio_hold_seconds) clearAnalysis();
        return false;
    }
    seconds_since_audio = 0;
    var peak_rms: f32 = 0;
    for (blocks[0..count]) |*block| {
        processBuffer(block);
        peak_rms = @max(peak_rms, rms_energy);
    }
    rms_energy = peak_rms;
    return true;
}

fn processBuffer(buffer: []const f32) void {
    std.debug.assert(buffer.len == N * channels);
    const curr_len = buffer.len / channels;

    processFrame(buffer, curr_len);
    fft.fft(fft_buffer[0..curr_len]);
    const detected = beat.process(buffer);
    if (beat_cooldown > 0) beat_cooldown -= 1;
    const hit = detected and beat_cooldown == 0;
    if (hit) beat_cooldown = beat_retrigger_blocks;
    on_beat = on_beat or hit;

    curr_buffer = audio_buffer[0..curr_len];
    curr_fft = fft_buffer[0..curr_len];
}

fn processFrame(buffer: []const f32, len: usize) void {
    const blend = if (smoothing_held) held_blend else Config.Audio.wave_blend;
    rms_energy = frame_analysis.analyze(true, buffer, raw_sample[0..len], audio_buffer[0..len], fft_buffer[0..len], blend, Config.Audio.wave_gain);
}

test "a render stall catches up to the newest complete audio block" {
    selectSource(.capture);
    defer selectSource(.none);
    const old: [N * channels]f32 = @splat(0.1);
    const recent: [N * channels]f32 = @splat(0.5);
    for (0..7) |_| submitCapture(&old);
    submitCapture(&recent);
    try std.testing.expect(update(0));
    try std.testing.expectApproxEqAbs(@as(f32, 0.5), rms_energy, 0.00001);
    try std.testing.expect(!update(0));
}

test "a short hit survives quieter blocks in the same render frame" {
    selectSource(.capture);
    defer selectSource(.none);
    const hit: [N * channels]f32 = @splat(0.5);
    const silence: [N * channels]f32 = @splat(0);
    submitCapture(&hit);
    for (0..3) |_| submitCapture(&silence);
    try std.testing.expect(update(0));
    try std.testing.expectApproxEqAbs(@as(f32, 0.5), rms_energy, 0.00001);
    submitCapture(&silence);
    try std.testing.expect(update(0));
    try std.testing.expectEqual(@as(f32, 0), rms_energy);
}

test "missing callbacks expire all analysis exposed to visuals" {
    selectSource(.capture);
    defer selectSource(.none);
    const hit: [N * channels]f32 = @splat(0.5);
    submitCapture(&hit);
    try std.testing.expect(update(0));
    try std.testing.expect(!update(audio_hold_seconds / 2));
    try std.testing.expect(rms_energy > 0);
    try std.testing.expect(!update(audio_hold_seconds));
    try std.testing.expectEqual(@as(f32, 0), rms_energy);
    for (curr_buffer) |value| try std.testing.expectEqual(@as(f32, 0), value);
    for (curr_fft) |value| try std.testing.expectEqual(@as(f32, 0), value.magnitude());
    try std.testing.expect(!on_beat);
}
