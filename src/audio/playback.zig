const std = @import("std");

const rl = @import("../raylib.zig");
const processor = @import("processor.zig");
const WaveformPreview = @import("WaveformPreview.zig");

pub var music = rl.Music{};
var processor_attached = false;
var fnbuff: [256]u8 = @splat(0);
pub var filename: []u8 = fnbuff[0..0];
pub var waveform: WaveformPreview = .{};

pub fn loadFile(path: []const u8) bool {
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
    if (processor_attached) {
        rl.DetachAudioMixedProcessor(processor.audioStreamCallback);
        processor_attached = false;
    }
    if (rl.IsMusicValid(music)) rl.UnloadMusicStream(music);
    music = .{};
    waveform.clear();
}
pub fn GetMusicTimePlayed() f32 {
    return rl.GetMusicTimePlayed(music);
}
pub fn GetMusicTimeLength() f32 {
    return rl.GetMusicTimeLength(music);
}
pub fn IsMusicStreamPlaying() bool {
    return rl.IsMusicStreamPlaying(music);
}
pub fn UpdateMusicStream() void {
    rl.UpdateMusicStream(music);
}

fn strpbrk(s: [*:0]const u8, accept: [*:0]const u8) ?[*:0]const u8 {
    var curr_s = s;
    while (curr_s[0] != 0) : (curr_s += 1) {
        var curr_accept = accept;
        while (curr_accept[0] != 0) : (curr_accept += 1)
            if (curr_accept[0] == curr_s[0]) return curr_s;
    } else return null;
}

test "strpbrk basic functionality" {
    const s = "hello world".*;
    const accept = "ow".*;
    const result = strpbrk(&s, &accept);
    try std.testing.expect(result != null);
    try std.testing.expectEqual(@as(u8, 'o'), result.?[0]);
}

test "strpbrk no match" {
    const s = "hello".*;
    const accept = "xyz".*;
    const result = strpbrk(&s, &accept);
    try std.testing.expect(result == null);
}

fn strprbrk(s: [*:0]const u8, charset: [*:0]const u8) ?[*:0]const u8 {
    var curr_s = s;
    var latest_match: ?[*:0]const u8 = null;

    while (strpbrk(curr_s, charset)) |match| {
        latest_match = match;
        curr_s = match + 1;
    }

    return latest_match;
}

test "strprbrk basic functionality" {
    const s = "hello/world/file.txt".*;
    const charset = "/".*;
    const result = strprbrk(&s, &charset);
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("file.txt", result.?[1 .. "file.txt".len + 1]);
}

test "strprbrk no separators" {
    const s = "filename.txt".*;
    const charset = "/".*;
    const result = strprbrk(&s, &charset);
    try std.testing.expect(result == null);
}

pub fn GetFileName(file_path: [*:0]const u8) [*:0]const u8 {
    if (strprbrk(file_path, "\\/")) |last_sep| {
        return last_sep + 1;
    } else return file_path;
}

test "GetFileName with path" {
    const path = "/home/user/file.txt".*;
    const result = GetFileName(&path);
    try std.testing.expectEqualStrings("file.txt", result[0 .. "file.txt.".len - 1]);
}

test "GetFileName no path" {
    const path = "file.txt".*;
    const result = GetFileName(&path);
    try std.testing.expectEqualStrings("file.txt", result[0.."file.txt".len]);
}
