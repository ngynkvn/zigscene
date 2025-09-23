const std = @import("std");

const Config = @import("../core/config.zig");
const N = Config.Audio.buffer_size;
const beat = @import("analysis/beat_detector.zig");
const fft = @import("analysis/fft.zig");

// Buffer states
pub var raw_buffer: []f32 = &raw_sample;
pub var curr_buffer: []f32 = &audio_buffer;
pub var curr_windowed_buffer: []f32 = &audio_buffer;
pub var curr_fft: []fft.ComplexF32 = &fft_buffer;

/// Currently loaded audio buffer data
var audio_buffer = std.mem.zeroes([N]f32);
var raw_windowed_buffer = std.mem.zeroes([N]f32);
var raw_sample = std.mem.zeroes([N]f32);

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
pub fn audioStreamCallback(ptr: ?*anyopaque, frames: c_uint) callconv(.c) void {
    const ctx = @import("tracy").traceNamed(@src(), "audio_stream");
    defer ctx.end();
    const buffer: []const f32 = @as([*]f32, @ptrCast(@alignCast(ptr)))[0 .. frames * 2];
    processBuffer(buffer);
}

/// Process a stereo interleaved PCM buffer
/// Performance-critical: Called at audio stream rate
fn processBuffer(buffer: []const f32) void {
    const len = buffer.len / 2;

    var rms: f32 = 0;

    // TODO: Use @Vector maybe?
    // For now, process frame-by-frame
    var i: usize = 0;
    var it = std.mem.window(f32, buffer, 2, 2);
    while (it.next()) |window| : (i += 1) {
        // Stereo -> Mono
        const l = window[0];
        const r = window[1];
        const mono = (l + r) * 0.5;

        raw_sample[i] = mono;

        audio_buffer[i] =
            (Config.Audio.attack * mono) +
            (Config.Audio.release * audio_buffer[i]);

        fft_buffer[i] = fft.ComplexF32.init(l + r, 0);
        rms += (l * l + r * r);

        var sum: f32 = 0;
        for (window) |w| sum += w;
        raw_windowed_buffer[i] = sum / @as(f32, @floatFromInt(window.len));
    }

    const ool: f32 = 1 / @as(f32, @floatFromInt(len));
    rms_energy = 0.65 * rms_energy + 0.90 * @sqrt(rms * ool);

    raw_buffer = raw_sample[0..len];
    curr_buffer = audio_buffer[0..len];
    curr_windowed_buffer = audio_buffer[0..len];

    fft.fft(fft_buffer[0..len]);
    curr_fft = fft_buffer[0..len];

    past_beats[bi] = beat.process(buffer);
    bi = (bi + 1) % N;
}
