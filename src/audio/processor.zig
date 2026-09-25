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
/// Root mean square of signal
pub var rms_energy: f32 = 0;

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
    @memset(&audio_buffer, 0);
    @memset(&raw_sample, 0);
    @memset(&fft_buffer, .init(0, 0));
    rms_energy = 0;
    on_beat = false;
    beat_cooldown = 0;
    beat.reset();
}

/// Run fixed-size analysis on the render thread, outside device callbacks.
pub fn update() bool {
    var block: [N * channels]f32 = undefined;
    var processed = false;
    on_beat = false;
    for (0..max_blocks_per_frame) |_| {
        if (!samples.popBlock(&block)) break;
        processBuffer(&block);
        processed = true;
    }
    return processed;
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
    rms_energy = frame_analysis.analyze(true, buffer, raw_sample[0..len], audio_buffer[0..len], fft_buffer[0..len], Config.Audio.wave_blend, Config.Audio.wave_gain);
}
