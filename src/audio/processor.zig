const std = @import("std");
const tracy = @import("tracy");
const Config = @import("zigscene").Config;
const controls = @import("../gui/controls.zig");
const cnv = @import("../ext/convert.zig");
const fft = @import("analysis/fft.zig");
const ffi = cnv.ffi;
const iff = cnv.iff;

const N = Config.Audio.buffer_size;
/// Currently loaded audio buffer data
var audio_buffer = std.mem.zeroes([N]f32);
var raw_sample = std.mem.zeroes([N]f32);
/// Root mean square of signal
pub var rms_energy: f32 = 0;

pub var raw_buffer: []f32 = &raw_sample;
pub var curr_buffer: []f32 = &audio_buffer;

/// Currently loaded buffer for fft data
var fft_buffer = std.mem.zeroes([N]fft.ComplexF32);
pub var curr_fft: []fft.ComplexF32 = &fft_buffer;

/// Accepts a buffer of the stream + the length of the buffer
/// The buffer is composed of PCM samples from the audio stream
/// that were passed to raylib / miniaudio.h
pub fn audioStreamCallback(ptr: ?*anyopaque, n: c_uint) callconv(.C) void {
    if (ptr == null) return;
    const ctx = tracy.traceNamed(@src(), "audio_stream");
    defer ctx.end();
    const buffer: []f32 = @as([*]f32, @ptrCast(@alignCast(ptr)))[0..n];
    var l: f32 = 0;
    var r: f32 = 0;
    var rms: f32 = 0;
    const curr_len = n / 2;
    const ool: f32 = 1 / ffi(f32, curr_len);
    for (0..curr_len) |fi| {
        l = buffer[fi * 2 + 0];
        r = buffer[fi * 2 + 1];
        const x = (l + r) * 0.5;
        raw_sample[fi] = x * 2;
        audio_buffer[fi] =
            (Config.Audio.attack * x) +
            (Config.Audio.release * audio_buffer[fi]);

        fft_buffer[fi] = fft.ComplexF32.init(l + r, 0);
        rms += (l * l + r * r);
    }
    rms_energy = 0.65 * rms_energy + 0.90 * @sqrt(rms * ool);
    fft.fft(fft_buffer[0..curr_len]);
    raw_buffer = raw_sample[0..curr_len];
    curr_buffer = audio_buffer[0..curr_len];
    curr_fft = fft_buffer[0..curr_len];
}
