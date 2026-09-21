//! Owns transitions between file playback and live capture.
const Session = @This();
const capture = @import("capture.zig");
const playback = @import("playback.zig");
const processor = @import("processor.zig");
const rl = @import("../raylib.zig");

resume_file_after_capture: bool = false,
resume_file_after_seek: bool = false,
seeking: bool = false,

pub fn playFile(self: *Session, path: []const u8) void {
    capture.stop();
    self.resume_file_after_capture = false;
    self.seeking = false;
    if (playback.loadFile(path)) {
        processor.selectSource(.file);
        rl.PlayMusicStream(playback.music);
    } else {
        processor.selectSource(.none);
    }
}

pub fn startCapture(self: *Session, mode: capture.Mode, device_index: i32) !void {
    const was_capturing = capture.active;
    if (was_capturing) capture.stop();
    const resume_file = if (was_capturing) self.resume_file_after_capture else if (self.seeking) self.resume_file_after_seek else self.isFilePlaying();
    if (!was_capturing and !self.seeking and resume_file) rl.PauseMusicStream(playback.music);
    processor.selectSource(.capture);
    capture.start(mode, device_index) catch |err| {
        processor.selectSource(if (self.hasFile()) .file else .none);
        if (resume_file) rl.ResumeMusicStream(playback.music);
        self.resume_file_after_capture = false;
        self.seeking = false;
        return err;
    };
    self.resume_file_after_capture = resume_file;
    self.seeking = false;
}

pub fn stopCapture(self: *Session) void {
    if (!capture.active) return;
    capture.stop();
    processor.selectSource(if (self.hasFile()) .file else .none);
    if (self.resume_file_after_capture and self.hasFile()) rl.ResumeMusicStream(playback.music);
    self.resume_file_after_capture = false;
}

pub fn toggleSystemCapture(self: *Session) void {
    if (capture.active) {
        self.stopCapture();
    } else {
        self.startCapture(.system, -1) catch {};
    }
}

pub fn togglePlayback(self: *Session) void {
    if (capture.active or !self.hasFile()) return;
    if (self.isFilePlaying()) {
        rl.PauseMusicStream(playback.music);
    } else {
        rl.ResumeMusicStream(playback.music);
    }
}

pub fn beginSeek(self: *Session) void {
    if (self.seeking or capture.active or !self.hasFile()) return;
    self.resume_file_after_seek = self.isFilePlaying();
    self.seeking = true;
    if (self.resume_file_after_seek) rl.PauseMusicStream(playback.music);
}

pub fn seekTo(self: *Session, seconds: f32) void {
    if (!self.seeking) self.beginSeek();
    if (self.seeking) rl.SeekMusicStream(playback.music, seconds);
}

pub fn endSeek(self: *Session) void {
    if (!self.seeking) return;
    self.seeking = false;
    if (self.resume_file_after_seek and !capture.active and self.hasFile()) rl.ResumeMusicStream(playback.music);
    self.resume_file_after_seek = false;
}

pub fn update(self: *Session) void {
    if (self.isFilePlaying()) playback.UpdateMusicStream();
}

pub fn shutdown(self: *Session) void {
    capture.stop();
    playback.shutdown();
    processor.selectSource(.none);
    self.* = .{};
}

pub fn listDevices() void {
    capture.listDevices();
}

pub fn captureActive(_: *const Session) bool {
    return capture.active;
}

pub fn captureMode(_: *const Session) capture.Mode {
    return capture.mode;
}

pub fn hasFile(_: *const Session) bool {
    return rl.IsMusicValid(playback.music);
}

pub fn isFilePlaying(self: *const Session) bool {
    return self.hasFile() and rl.IsMusicStreamPlaying(playback.music);
}

pub fn filename(_: *const Session) []const u8 {
    return playback.filename;
}

pub fn timePlayed(_: *const Session) f32 {
    return playback.GetMusicTimePlayed();
}

pub fn timeLength(_: *const Session) f32 {
    return playback.GetMusicTimeLength();
}
