const std = @import("std");

const Config = @import("../core/config.zig");
const N = Config.Audio.buffer_size;
const cnv = @import("../ext/convert.zig");
const ffi = cnv.ffi;
const beat = @import("analysis/beat_detector.zig");
const fft = @import("analysis/fft.zig");

/// Currently loaded audio buffer data
var audio_buffer = std.mem.zeroes([N]f32);
var raw_windowed_buffer = std.mem.zeroes([N]f32);
var raw_sample = std.mem.zeroes([N]f32);

// Buffer states
pub var raw_buffer: []f32 = &raw_sample;
pub var curr_buffer: []f32 = &audio_buffer;
pub var curr_windowed_buffer: []f32 = &audio_buffer;
pub var curr_fft: []fft.ComplexF32 = &fft_buffer;

/// Currently loaded buffer for fft data
var fft_buffer = std.mem.zeroes([N]fft.ComplexF32);

// Analysis
pub var on_beat = false;
pub var past_beats: [N]bool = @splat(false);
pub var bi: usize = 0;
/// Root mean square of signal
pub var rms_energy: f32 = 0;

/// Accepts a buffer of the stream + the length of the buffer
/// The buffer is composed of PCM samples from the audio stream
/// that were passed to raylib / miniaudio.h
pub fn audioStreamCallback(ptr: ?*anyopaque, frames: c_uint) callconv(.C) void {
    const ctx = @import("tracy").traceNamed(@src(), "audio_stream");
    defer ctx.end();
    const buffer: []const f32 = @as([*]f32, @ptrCast(@alignCast(ptr)))[0 .. frames * 2];
    processBuffer(buffer);
}

/// Process a stereo interleaved PCM buffer
/// Performance-critical: Called at audio stream rate
fn processBuffer(buffer: []const f32) void {
    const curr_len = buffer.len / 2;

    processFrame(buffer, curr_len);
    processWindowed(curr_len);
    fft.fft(fft_buffer[0..curr_len]);
    past_beats[bi] = beat.process(buffer);
    bi = (bi + 1) % N;

    raw_buffer = raw_sample[0..curr_len];
    curr_buffer = audio_buffer[0..curr_len];
    curr_fft = fft_buffer[0..curr_len];
}

fn processFrame(buffer: []const f32, len: usize) void {
    var l: f32 = 0;
    var r: f32 = 0;
    var rms: f32 = 0;

    // TODO: Use @Vector maybe?
    // For now, process frame-by-frame
    for (0..len) |fi| {
        // Stereo -> Mono
        l = buffer[fi * 2 + 0];
        r = buffer[fi * 2 + 1];
        const mono = (l + r) * 0.5;

        raw_sample[fi] = mono;

        audio_buffer[fi] =
            (Config.Audio.attack * mono) +
            (Config.Audio.release * audio_buffer[fi]);

        fft_buffer[fi] = fft.ComplexF32.init(l + r, 0);
        rms += (l * l + r * r);
    }

    const ool: f32 = 1 / ffi(f32, len);
    rms_energy = 0.65 * rms_energy + 0.90 * @sqrt(rms * ool);
}

fn processWindowed(len: usize) void {
    var it = std.mem.window(f32, audio_buffer[0..len], 2, 2);
    var i: usize = 0;
    while (it.next()) |window| {
        var sum: f32 = 0;
        for (window) |w| sum += w;
        raw_windowed_buffer[i] = sum / @as(f32, @floatFromInt(window.len));
        i += 1;
    }
    curr_windowed_buffer = raw_windowed_buffer[0..i];
}
