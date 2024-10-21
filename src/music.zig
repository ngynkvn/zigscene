const std = @import("std");
const c = @import("raylib.zig").c;
const audio = @import("audio.zig");

pub var music = c.Music{};
var fnbuff = std.mem.zeroes([32]u8);
pub var filename: []u8 = undefined;

pub fn handleFile() !void {
    const files = c.LoadDroppedFiles();
    defer c.UnloadDroppedFiles(files);
    const file = files.paths[0];
    const cfilename = c.GetFileName(file);
    const clen = std.mem.len(cfilename);
    @memcpy(fnbuff[0..clen], cfilename[0..clen]);
    filename = fnbuff[0..clen];
    try startMusic(file);
}

pub fn startMusic(path: [*c]const u8) !void {
    music = c.LoadMusicStream(path);
    if (music.stream.sampleSize != 32) return error.NoMusic;
    c.AttachAudioStreamProcessor(music.stream, audio.audioStreamCallback);
    std.log.info("samplesize = {}, samplerate = {}\n", .{ music.stream.sampleSize, music.stream.sampleRate });
    c.PlayMusicStream(music);
}
pub fn GetMusicTimePlayed() f32 {
    return c.GetMusicTimePlayed(music);
}
pub fn GetMusicTimeLength() f32 {
    return c.GetMusicTimeLength(music);
}
pub fn IsMusicStreamPlaying() bool {
    return c.IsMusicStreamPlaying(music);
}
pub fn UpdateMusicStream() void {
    c.UpdateMusicStream(music);
}
