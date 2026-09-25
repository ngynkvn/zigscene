const std = @import("std");
const native = @import("builtin").os.tag != .emscripten;

const rl = @import("../raylib.zig");
const processor = @import("processor.zig");
const WaveformPreview = @import("WaveformPreview.zig");

var music = rl.Music{};
var worker_started = false;
extern fn zigscene_refill_start(callback: *const fn () callconv(.c) void) bool;
extern fn zigscene_refill_lock() void;
extern fn zigscene_refill_unlock() void;
extern fn zigscene_refill_stop() void;

fn lock() void {
    if (native and worker_started) zigscene_refill_lock();
}
fn unlock() void {
    if (native and worker_started) zigscene_refill_unlock();
}
fn refill() callconv(.c) void {
    if (rl.IsMusicStreamPlaying(music)) rl.UpdateMusicStream(music);
}
fn stopWorker() void {
    if (native and worker_started) zigscene_refill_stop();
    worker_started = false;
}

pub fn hasFile() bool {
    return rl.IsMusicValid(music);
}
pub fn play() void {
    lock();
    defer unlock();
    rl.PlayMusicStream(music);
    rl.UpdateMusicStream(music);
}
pub fn pause() void {
    lock();
    defer unlock();
    rl.PauseMusicStream(music);
}
pub fn resumePlayback() void {
    lock();
    defer unlock();
    rl.ResumeMusicStream(music);
    rl.UpdateMusicStream(music);
}
pub fn seek(seconds: f32) void {
    lock();
    defer unlock();
    rl.SeekMusicStream(music, seconds);
}

var processor_attached = false;
var fnbuff: [256]u8 = @splat(0);
pub var filename: []u8 = fnbuff[0..0];
pub var waveform: WaveformPreview = .{};

pub fn loadFile(path: []const u8) bool {
    stopWorker();
    if (rl.IsMusicValid(music)) rl.UnloadMusicStream(music);
    waveform.clear();
    const path_z = std.heap.page_allocator.dupeZ(u8, path) catch {
        music = .{};
        filename = fnbuff[0..0];
        return false;
    };
    defer std.heap.page_allocator.free(path_z);
    music = rl.LoadMusicStream(path_z.ptr);
    if (!rl.IsMusicValid(music)) {
        filename = fnbuff[0..0];
        return false;
    }
    const cfilename = rl.GetFileName(path_z.ptr);
    const clen = @min(std.mem.len(cfilename), 160);
    @memcpy(fnbuff[0..clen], cfilename[0..clen]);
    filename = fnbuff[0..clen];
    buildWaveform(path_z.ptr);
    if (!processor_attached) {
        rl.AttachAudioMixedProcessor(processor.audioStreamCallback);
        processor_attached = true;
    }
    if (native) {
        worker_started = zigscene_refill_start(refill);
        if (!worker_started) std.debug.print("Audio refill worker unavailable; falling back to frame updates.\n", .{});
    }
    return true;
}

fn buildWaveform(path: [*:0]const u8) void {
    const wave = rl.LoadWave(path);
    if (!rl.IsWaveValid(wave)) return;
    defer rl.UnloadWave(wave);
    const samples = rl.LoadWaveSamples(wave);
    if (samples == null) return;
    defer rl.UnloadWaveSamples(samples);
    const sample_count = @as(usize, wave.frameCount) * @as(usize, wave.channels);
    waveform.build(samples[0..sample_count], wave.channels, wave.sampleRate);
}

pub fn shutdown() void {
    stopWorker();
    if (processor_attached) {
        rl.DetachAudioMixedProcessor(processor.audioStreamCallback);
        processor_attached = false;
    }
    if (rl.IsMusicValid(music)) rl.UnloadMusicStream(music);
    music = .{};
    waveform.clear();
}
pub fn GetMusicTimePlayed() f32 {
    lock();
    defer unlock();
    return rl.GetMusicTimePlayed(music);
}
pub fn GetMusicTimeLength() f32 {
    lock();
    defer unlock();
    return rl.GetMusicTimeLength(music);
}
pub fn IsMusicStreamPlaying() bool {
    lock();
    defer unlock();
    return rl.IsMusicStreamPlaying(music);
}
pub fn UpdateMusicStream() void {
    // Browsers and failed worker starts retain the single-threaded path.
    if (!worker_started) refill();
}

extern fn test_refill_worker() c_int;
test "native refill worker survives render stalls and serializes controls" {
    if (native) try std.testing.expectEqual(@as(c_int, 0), test_refill_worker());
}
