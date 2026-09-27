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
    if (!hasFile() or !std.math.isFinite(seconds)) return;
    const was_playing = rl.IsMusicStreamPlaying(music);
    // raylib's SeekMusicStream leaves frameCursorPos at the old position.
    // Reset the stream first, while its buffers are marked empty, then pause
    // before decoding the target. This also keeps paused seeks paused.
    rl.PlayMusicStream(music);
    rl.PauseMusicStream(music);
    const last_frame = @max(0, rl.GetMusicTimeLength(music) - 1 / @as(f32, @floatFromInt(music.stream.sampleRate)));
    rl.SeekMusicStream(music, std.math.clamp(seconds, 0, last_frame));
    rl.UpdateMusicStream(music);
    if (was_playing) rl.ResumeMusicStream(music);
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

const PreviewDecoder = opaque {};
extern fn zigscene_preview_open(path: [*:0]const u8, kind: c_int, frames: *u64, channels: *c_uint, rate: *c_uint) ?*PreviewDecoder;
extern fn zigscene_preview_read(decoder: *PreviewDecoder, out: [*]f32, capacity: c_uint) c_uint;
extern fn zigscene_preview_close(decoder: *PreviewDecoder) void;

/// Common formats decode in fixed chunks; other raylib formats retain their fallback.
fn buildWaveform(path: [*:0]const u8, out: *WaveformPreview) void {
    const extension = std.fs.path.extension(std.mem.span(path));
    const kind: ?c_int = if (std.ascii.eqlIgnoreCase(extension, ".mp3")) 0 else if (std.ascii.eqlIgnoreCase(extension, ".wav")) 1 else if (std.ascii.eqlIgnoreCase(extension, ".ogg")) 2 else null;
    if (if (native) kind else null) |format| {
        var frames: u64 = 0;
        var channels: c_uint = 0;
        var rate: c_uint = 0;
        const decoder = zigscene_preview_open(path, format, &frames, &channels, &rate) orelse return;
        defer zigscene_preview_close(decoder);
        var builder = WaveformPreview.Builder.init(out, std.heap.page_allocator, frames, channels, rate) catch return;
        defer builder.deinit();
        var samples: [8192]f32 = undefined;
        while (builder.frames < frames) {
            const count = zigscene_preview_read(decoder, &samples, samples.len);
            if (count == 0) break;
            builder.append(samples[0 .. @as(usize, count) * channels]);
        }
        return;
    }
    buildWaveformFallback(path, out);
}

fn buildWaveformFallback(path: [*:0]const u8, out: *WaveformPreview) void {
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

const PreviewRequest = struct {
    path: [:0]u8,
    build: *const fn ([*:0]const u8, *WaveformPreview) void,

    fn deinit(request: PreviewRequest) void {
        std.heap.page_allocator.free(request.path);
    }
};

/// Only one decode runs at a time. The render thread owns the job's lifetime;
/// the worker publishes its result before the render thread joins and frees it.
const PreviewJob = struct {
    done: std.atomic.Value(bool) = .init(false),
    request: PreviewRequest,
    thread: std.Thread = undefined,
    abandoned: bool = false,
    preview: WaveformPreview = .{},

    fn run(job: *PreviewJob) void {
        job.request.build(job.request.path.ptr, &job.preview);
        job.done.store(true, .release);
    }

    fn destroy(job: *PreviewJob) void {
        job.request.deinit();
        std.heap.page_allocator.destroy(job);
    }
};
const can_spawn = native and !builtin.single_threaded;
var preview_job: ?*PreviewJob = null;
// Replaced on each track change; queued tracks hold only a path, never decoded PCM.
var pending_preview: ?PreviewRequest = null;

fn startPreview(path: [:0]const u8) void {
    if (can_spawn) {
        if (spawnPreview(path, buildWaveform)) return;
        // Never start a synchronous decode alongside an abandoned worker.
        if (preview_job != null) {
            std.debug.print("Waveform preview unavailable for this track.\n", .{});
            return;
        }
        std.debug.print("Waveform preview thread unavailable; building it inline.\n", .{});
    }
    buildWaveform(path.ptr, &waveform);
}

fn spawnPreview(path: [:0]const u8, build: *const fn ([*:0]const u8, *WaveformPreview) void) bool {
    abandonPreview();
    const request: PreviewRequest = .{
        .path = std.heap.page_allocator.dupeZ(u8, path) catch return false,
        .build = build,
    };
    if (preview_job != null) {
        pending_preview = request;
        return true;
    }
    if (launchPreview(request)) return true;
    request.deinit();
    return false;
}

/// Takes ownership of the request only if the worker starts successfully.
fn launchPreview(request: PreviewRequest) bool {
    std.debug.assert(preview_job == null);
    const allocator = std.heap.page_allocator;
    const job = allocator.create(PreviewJob) catch return false;
    job.* = .{ .request = request };
    job.thread = std.Thread.spawn(.{}, PreviewJob.run, .{job}) catch {
        allocator.destroy(job);
        return false;
    };
    preview_job = job;
    return true;
}

fn abandonPreview() void {
    if (pending_preview) |request| request.deinit();
    pending_preview = null;
    if (preview_job) |job| job.abandoned = true;
}

fn stopPreview() void {
    if (!can_spawn) return;
    abandonPreview();
    if (preview_job) |job| {
        job.thread.join();
        job.destroy();
        preview_job = null;
    }
}

/// Adopts a finished background preview. Call once per frame.
pub fn pollPreview() void {
    if (!can_spawn) return;
    const job = preview_job orelse return;
    if (!job.done.load(.acquire)) return;
    job.thread.join();
    preview_job = null;
    if (!job.abandoned) {
        const revision = waveform.revision;
        waveform = job.preview;
        waveform.revision = revision +% 1;
    }
    job.destroy();
    if (pending_preview) |request| {
        pending_preview = null;
        if (!launchPreview(request)) {
            // The previous worker has been joined, so the fallback is also bounded.
            request.build(request.path.ptr, &waveform);
            request.deinit();
        }
    }
}

pub fn previewPending() bool {
    return pending_preview != null or (if (preview_job) |job| !job.abandoned else false);
}

pub fn shutdown() void {
    stopWorker();
    if (processor_attached) {
        rl.DetachAudioMixedProcessor(processor.audioStreamCallback);
        processor_attached = false;
    }
    if (rl.IsMusicValid(music)) rl.UnloadMusicStream(music);
    music = .{};
    stopPreview();
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
    var started = std.atomic.Value(usize).init(0);
    var skipped_started = std.atomic.Value(bool).init(false);

    fn build(path: [*:0]const u8, out: *WaveformPreview) void {
        _ = started.fetchAdd(1, .monotonic);
        if (std.mem.eql(u8, std.mem.span(path), "skipped.wav")) skipped_started.store(true, .release);
        while (!release.load(.acquire)) std.atomic.spinLoopHint();
        if (std.mem.eql(u8, std.mem.span(path), "latest.wav")) {
            out.build(&.{0.75}, 1, 44100);
        } else {
            out.build(&.{ 0.5, -1, 0.25 }, 1, 44100);
        }
    }

    fn reset() void {
        release.store(false, .release);
        started.store(0, .monotonic);
        skipped_started.store(false, .release);
    }

    fn cleanup() void {
        release.store(true, .release);
        stopPreview();
        waveform.clear();
    }
};

test "background preview is adopted once it finishes" {
    if (!can_spawn) return;
    preview_test.reset();
    defer preview_test.cleanup();
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
    defer preview_test.cleanup();
    waveform.clear();
    try std.testing.expect(spawnPreview("old.wav", preview_test.build));
    abandonPreview();
    try std.testing.expect(!previewPending());
    preview_test.release.store(true, .release);
    while (preview_job != null) pollPreview();
    try std.testing.expectEqual(@as(usize, 0), waveform.len);
}

test "rapid track replacement keeps one decoder and only the latest pending preview" {
    if (!can_spawn) return;
    preview_test.reset();
    defer preview_test.cleanup();
    waveform.clear();
    const revision = waveform.revision;
    try std.testing.expect(spawnPreview("old.wav", preview_test.build));
    while (preview_test.started.load(.monotonic) == 0) std.atomic.spinLoopHint();
    const original_job = preview_job.?;
    for (0..100) |_| {
        try std.testing.expect(spawnPreview("skipped.wav", preview_test.build));
        pollPreview();
        try std.testing.expect(preview_job.? == original_job);
    }
    try std.testing.expect(spawnPreview("latest.wav", preview_test.build));
    try std.testing.expectEqual(@as(usize, 1), preview_test.started.load(.monotonic));
    try std.testing.expect(previewPending());
    preview_test.release.store(true, .release);
    while (previewPending()) pollPreview();
    try std.testing.expectEqual(@as(usize, 2), preview_test.started.load(.monotonic));
    try std.testing.expect(!preview_test.skipped_started.load(.acquire));
    try std.testing.expectEqual(@as(usize, 1), waveform.len);
    try std.testing.expectEqual(@as(f32, 0.75), waveform.bins[0].peak);
    try std.testing.expectEqual(revision +% 1, waveform.revision);
    try std.testing.expect(preview_job == null and pending_preview == null);
}

test "preview shutdown joins the active decoder and discards the pending track" {
    if (!can_spawn) return;
    preview_test.reset();
    defer preview_test.cleanup();
    waveform.clear();
    try std.testing.expect(spawnPreview("old.wav", preview_test.build));
    try std.testing.expect(spawnPreview("skipped.wav", preview_test.build));
    preview_test.release.store(true, .release);
    stopPreview();
    try std.testing.expect(preview_job == null and pending_preview == null);
    try std.testing.expect(!previewPending());
    try std.testing.expectEqual(@as(usize, 1), preview_test.started.load(.monotonic));
    try std.testing.expectEqual(@as(usize, 0), waveform.len);
    // Starting again must not retain stale requests or a joined thread handle.
    try std.testing.expect(spawnPreview("latest.wav", preview_test.build));
    while (previewPending()) pollPreview();
    try std.testing.expectEqual(@as(f32, 0.75), waveform.bins[0].peak);
    try std.testing.expect(!preview_test.skipped_started.load(.acquire));
}

extern fn test_refill_worker() c_int;
test "native refill worker survives render stalls and serializes controls" {
    if (native) try std.testing.expectEqual(@as(c_int, 0), test_refill_worker());
}

test "seeking after playback resets the buffer cursor and preserves pause" {
    if (!native) return;
    rl.rl.SetTraceLogLevel(rl.rl.LOG_NONE);
    defer rl.rl.SetTraceLogLevel(rl.rl.LOG_INFO);
    rl.InitAudioDevice();
    defer rl.CloseAudioDevice();
    if (!rl.rl.IsAudioDeviceReady()) return error.SkipZigTest;
    rl.SetMasterVolume(0);
    // A silent ten-second WAV exercises the real decoder and audio clock.
    const wav = try std.testing.allocator.alloc(u8, 44 + 80000 * 2);
    defer std.testing.allocator.free(wav);
    @memset(wav, 0);
    @memcpy(wav[0..4], "RIFF");
    std.mem.writeInt(u32, wav[4..8], @intCast(wav.len - 8), .little);
    @memcpy(wav[8..16], "WAVEfmt ");
    std.mem.writeInt(u32, wav[16..20], 16, .little);
    std.mem.writeInt(u16, wav[20..22], 1, .little);
    std.mem.writeInt(u16, wav[22..24], 1, .little);
    std.mem.writeInt(u32, wav[24..28], 8000, .little);
    std.mem.writeInt(u32, wav[28..32], 16000, .little);
    std.mem.writeInt(u16, wav[32..34], 2, .little);
    std.mem.writeInt(u16, wav[34..36], 16, .little);
    @memcpy(wav[36..40], "data");
    std.mem.writeInt(u32, wav[40..44], @intCast(wav.len - 44), .little);
    music = rl.rl.LoadMusicStreamFromMemory(".wav", wav.ptr, @intCast(wav.len));
    defer shutdown();
    try std.testing.expect(hasFile());
    play();
    for (0..500) |_| {
        UpdateMusicStream();
        if (GetMusicTimePlayed() > 0.075) break;
        try std.Io.sleep(std.testing.io, .fromMilliseconds(10), .awake);
    }
    pause();
    try std.testing.expect(GetMusicTimePlayed() > 0.075);
    seek(4);
    try std.testing.expect(!IsMusicStreamPlaying());
    try std.testing.expectApproxEqAbs(@as(f32, 4), GetMusicTimePlayed(), 0.001);
    seek(2);
    try std.testing.expect(!IsMusicStreamPlaying());
    try std.testing.expectApproxEqAbs(@as(f32, 2), GetMusicTimePlayed(), 0.001);
    seek(-1);
    try std.testing.expectEqual(@as(f32, 0), GetMusicTimePlayed());
    seek(20);
    try std.testing.expect(GetMusicTimePlayed() > 9.99 and GetMusicTimePlayed() < 10);
    seek(4);
    resumePlayback();
    try std.testing.expect(IsMusicStreamPlaying());
    seek(2);
    try std.testing.expect(IsMusicStreamPlaying());
}

test "streaming WAV preview matches raylib decoding and handles missing files" {
    if (!native) return;
    // raylib logs to stdout, which Zig uses for its test-runner protocol.
    rl.rl.SetTraceLogLevel(rl.rl.LOG_NONE);
    defer rl.rl.SetTraceLogLevel(rl.rl.LOG_INFO);
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const path = try std.fmt.allocPrintSentinel(std.testing.allocator, ".zig-cache/tmp/{s}/preview.wav", .{tmp.sub_path}, 0);
    defer std.testing.allocator.free(path);
    const frames = 9007;
    var wav: [44 + frames * 4]u8 = undefined;
    @memcpy(wav[0..4], "RIFF");
    std.mem.writeInt(u32, wav[4..8], wav.len - 8, .little);
    @memcpy(wav[8..16], "WAVEfmt ");
    std.mem.writeInt(u32, wav[16..20], 16, .little);
    std.mem.writeInt(u16, wav[20..22], 1, .little);
    std.mem.writeInt(u16, wav[22..24], 2, .little);
    std.mem.writeInt(u32, wav[24..28], 44100, .little);
    std.mem.writeInt(u32, wav[28..32], 44100 * 4, .little);
    std.mem.writeInt(u16, wav[32..34], 4, .little);
    std.mem.writeInt(u16, wav[34..36], 16, .little);
    @memcpy(wav[36..40], "data");
    std.mem.writeInt(u32, wav[40..44], wav.len - 44, .little);
    for (0..frames * 2) |i| std.mem.writeInt(i16, wav[44 + i * 2 ..][0..2], @intCast(@as(i32, @intCast(i % 1000)) * 60 - 30000), .little);
    try tmp.dir.writeFile(std.testing.io, .{ .sub_path = "preview.wav", .data = &wav });
    var actual: WaveformPreview = .{};
    var expected: WaveformPreview = .{};
    buildWaveform(path, &actual);
    buildWaveformFallback(path, &expected);
    try std.testing.expectEqual(@as(usize, WaveformPreview.bin_count), actual.len);
    for (actual.bins, expected.bins) |a, b| {
        try std.testing.expectEqual(b.peak, a.peak);
        try std.testing.expectEqual(b.sample_count, a.sample_count);
        try std.testing.expectApproxEqAbs(b.square_sum, a.square_sum, 1e-10);
        for (a.band_square_sum, b.band_square_sum) |x, y| try std.testing.expectApproxEqAbs(x, y, 1e-10);
    }
    try tmp.dir.deleteFile(std.testing.io, "preview.wav");
    actual.clear();
    buildWaveform(path, &actual);
    try std.testing.expectEqual(@as(usize, 0), actual.len);
    try tmp.dir.writeFile(std.testing.io, .{ .sub_path = "preview.wav", .data = "invalid wave" });
    buildWaveform(path, &actual);
    try std.testing.expectEqual(@as(usize, 0), actual.len);
}
