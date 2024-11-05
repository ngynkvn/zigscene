const std = @import("std");
const rl = @import("../raylib.zig");
const processor = @import("processor.zig");

pub var music = rl.Music{};
var fnbuff: [256]u8 = @splat(0);
pub var filename: []u8 = fnbuff[0..0];

pub fn onFilenameInput(path: []const u8) void {
    music = rl.LoadMusicStream(path.ptr);
    const cfilename = rl.GetFileName(path.ptr);
    const clen = std.mem.len(cfilename);
    @memcpy(fnbuff[0..clen], cfilename[0..clen]);
    filename = fnbuff[0..clen];
    std.log.info("samplesize = {}, samplerate = {}\n", .{ music.stream.sampleSize, music.stream.sampleRate });
    rl.AttachAudioStreamProcessor(music.stream, processor.audioStreamCallback);
    rl.PlayMusicStream(music);
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
