const std = @import("std");
const rl = @import("raylib.zig");
const audio = @import("audio.zig");

pub var music = rl.Music{};
var fnbuff: [256]u8 = @splat(0);
pub var filename: []u8 = undefined;

pub fn handleFile() !void {
    const files = rl.LoadDroppedFiles();
    defer rl.UnloadDroppedFiles(files);
    const file = files.paths[0];

    const cfilename = GetFileName(file);
    const clen = std.mem.len(cfilename);
    @memcpy(fnbuff[0..clen], cfilename[0..clen]);
    filename = fnbuff[0..clen];
    try startMusic(file);
}

pub fn startMusic(path: [*c]const u8) !void {
    music = rl.LoadMusicStream(path);
    std.log.info("samplesize = {}, samplerate = {}\n", .{ music.stream.sampleSize, music.stream.sampleRate });
    rl.AttachAudioStreamProcessor(music.stream, audio.audioStreamCallback);
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
pub export fn strpbrk(arg_s: [*c]const u8, arg_accept: [*c]const u8) [*c]u8 {
    var s = arg_s;
    _ = &s;
    var accept = arg_accept;
    _ = &accept;
    while (@as(c_int, @bitCast(@as(c_uint, s.*))) != @as(c_int, '\x00')) {
        var a: [*c]const u8 = accept;
        _ = &a;
        while (@as(c_int, @bitCast(@as(c_uint, a.*))) != @as(c_int, '\x00')) if (@as(c_int, @bitCast(@as(c_uint, (blk: {
            const ref = &a;
            const tmp = ref.*;
            ref.* += 1;
            break :blk tmp;
        }).*))) == @as(c_int, @bitCast(@as(c_uint, s.*)))) return @as([*c]u8, @ptrCast(@volatileCast(@constCast(s))));
        s += 1;
    }
    return null;
}
pub fn strprbrk(arg_s: [*c]const u8, arg_charset: [*c]const u8) callconv(.c) [*c]const u8 {
    var s = arg_s;
    _ = &s;
    var charset = arg_charset;
    _ = &charset;
    var latestMatch: [*c]const u8 = null;
    _ = &latestMatch;
    while ((blk: {
        s = strpbrk(s, charset);
        break :blk s != null;
    })) : (latestMatch = blk: {
        const ref = &s;
        const tmp = ref.*;
        ref.* += 1;
        break :blk tmp;
    }) {}
    return latestMatch;
}
pub fn GetFileName(arg_filePath: [*c]const u8) callconv(.c) [*c]const u8 {
    var filePath = arg_filePath;
    _ = &filePath;
    var fileName: [*c]const u8 = null;
    _ = &fileName;
    if (filePath != null) {
        fileName = strprbrk(filePath, "\\/");
    }
    if (!(fileName != null)) return filePath;
    return fileName + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 1)))));
}
