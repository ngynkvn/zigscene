const std = @import("std");
const rl = @import("raylib.zig");
const audio = @import("audio.zig");

pub var music = rl.Music{};
var fnbuff = std.mem.zeroes([256]u8);
pub var filename: []u8 = undefined;

pub fn handleFile() !void {
    const files = rl.LoadDroppedFiles();
    defer rl.UnloadDroppedFiles(files);
    const file = files.paths[0];
    try startMusic(file);
}

pub fn startMusic(path: [*c]const u8) !void {
    const cfilename = rl.GetFileName(path);
    const clen = std.mem.len(cfilename);
    @memcpy(fnbuff[0..clen], cfilename[0..clen]);
    filename = fnbuff[0..clen];
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
