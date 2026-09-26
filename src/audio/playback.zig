const std = @import("std");
const builtin = @import("builtin");
const native = builtin.os.tag != .emscripten;

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
    abandonPreview();
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
    startPreview(path_z);
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

/// Decodes the whole track, so it runs off the render thread when possible.
fn buildWaveform(path: [*:0]const u8, out: *WaveformPreview) void {
    const wave = rl.LoadWave(path);
    if (!rl.IsWaveValid(wave)) return;
    defer rl.UnloadWave(wave);
    const sample_count = @as(usize, wave.frameCount) * @as(usize, wave.channels);
    // 32-bit waves are already float (MP3 decodes this way); skip a full-size copy.
    if (wave.sampleSize == 32) {
        const samples: [*]const f32 = @ptrCast(@alignCast(wave.data));
        return out.build(samples[0..sample_count], wave.channels, wave.sampleRate);
    }
    const samples = rl.LoadWaveSamples(wave);
    if (samples == null) return;
    defer rl.UnloadWaveSamples(samples);
    out.build(samples[0..sample_count], wave.channels, wave.sampleRate);
}

/// A background preview build. Loading another track abandons it; whichever of
/// the worker and the render thread sees the other's transition frees it.
const PreviewJob = struct {
    const State = enum(u8) { running, done, abandoned };
    state: std.atomic.Value(State) = .init(.running),
    path: [:0]u8,
    preview: WaveformPreview = .{},
    build: *const fn ([*:0]const u8, *WaveformPreview) void = buildWaveform,

    fn run(job: *PreviewJob) void {
        job.build(job.path.ptr, &job.preview);
        if (job.state.swap(.done, .acq_rel) == .abandoned) job.destroy();
    }

    fn destroy(job: *PreviewJob) void {
        std.heap.page_allocator.free(job.path);
        std.heap.page_allocator.destroy(job);
    }
};
const can_spawn = native and !builtin.single_threaded;
var preview_job: ?*PreviewJob = null;

fn startPreview(path: [:0]const u8) void {
    if (can_spawn) {
        if (spawnPreview(path, buildWaveform)) return;
        std.debug.print("Waveform preview thread unavailable; building it inline.\n", .{});
    }
    buildWaveform(path.ptr, &waveform);
}

fn spawnPreview(path: [:0]const u8, build: *const fn ([*:0]const u8, *WaveformPreview) void) bool {
    const allocator = std.heap.page_allocator;
    const job = allocator.create(PreviewJob) catch return false;
    job.* = .{ .path = allocator.dupeZ(u8, path) catch {
        allocator.destroy(job);
        return false;
    }, .build = build };
    const thread = std.Thread.spawn(.{}, PreviewJob.run, .{job}) catch {
        job.destroy();
        return false;
    };
    thread.detach();
    preview_job = job;
    return true;
}

fn abandonPreview() void {
    const job = preview_job orelse return;
    preview_job = null;
    if (job.state.swap(.abandoned, .acq_rel) == .done) job.destroy();
}

/// Adopts a finished background preview. Call once per frame.
pub fn pollPreview() void {
    const job = preview_job orelse return;
    if (job.state.load(.acquire) != .done) return;
    preview_job = null;
    const revision = waveform.revision;
    waveform = job.preview;
    waveform.revision = revision +% 1;
    job.destroy();
}

pub fn previewPending() bool {
    return preview_job != null;
}

pub fn shutdown() void {
    stopWorker();
    if (processor_attached) {
        rl.DetachAudioMixedProcessor(processor.audioStreamCallback);
        processor_attached = false;
    }
    if (rl.IsMusicValid(music)) rl.UnloadMusicStream(music);
    music = .{};
    abandonPreview();
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

const preview_test = struct {
    var release = std.atomic.Value(bool).init(false);
    var finished = std.atomic.Value(bool).init(false);

    fn build(_: [*:0]const u8, out: *WaveformPreview) void {
        while (!release.load(.acquire)) std.atomic.spinLoopHint();
        out.build(&.{ 0.5, -1, 0.25 }, 1, 44100);
        finished.store(true, .release);
    }

    fn reset() void {
        release.store(false, .release);
        finished.store(false, .release);
    }
};

test "background preview is adopted once it finishes" {
    if (!can_spawn) return;
    preview_test.reset();
    waveform.clear();
    const revision = waveform.revision;
    try std.testing.expect(spawnPreview("song.wav", preview_test.build));
    pollPreview();
    try std.testing.expect(previewPending());
    try std.testing.expectEqual(@as(usize, 0), waveform.len);
    preview_test.release.store(true, .release);
    while (previewPending()) pollPreview();
    try std.testing.expectEqual(@as(usize, 3), waveform.len);
    try std.testing.expectEqual(@as(f32, 1), waveform.bins[1].peak);
    try std.testing.expect(waveform.revision != revision);
    waveform.clear();
}

test "an abandoned preview never replaces the next track's waveform" {
    if (!can_spawn) return;
    preview_test.reset();
    waveform.clear();
    try std.testing.expect(spawnPreview("old.wav", preview_test.build));
    abandonPreview();
    try std.testing.expect(!previewPending());
    preview_test.release.store(true, .release);
    while (!preview_test.finished.load(.acquire)) std.atomic.spinLoopHint();
    pollPreview();
    try std.testing.expectEqual(@as(usize, 0), waveform.len);
}

extern fn test_refill_worker() c_int;
test "native refill worker survives render stalls and serializes controls" {
    if (native) try std.testing.expectEqual(@as(c_int, 0), test_refill_worker());
}
