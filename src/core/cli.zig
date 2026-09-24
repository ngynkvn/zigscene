const std = @import("std");
const capture = @import("../audio/capture.zig");

pub const Options = struct {
    capture_mode: ?capture.Mode = null,
    capture_device: i32 = -1,
    list_audio_devices: bool = false,
    file: ?[]const u8 = null,
    scene_path: ?[]const u8 = null,
};

pub const ParseError = error{ InvalidAudioDevice, TooManyFiles, UnknownOption, InvalidScenePath };

pub fn parse(args: []const []const u8) ParseError!Options {
    var options: Options = .{};
    for (args) |arg| {
        if (std.mem.eql(u8, arg, "--system-audio")) {
            options.capture_mode = .system;
        } else if (std.mem.eql(u8, arg, "--input-audio")) {
            options.capture_mode = .input;
        } else if (std.mem.eql(u8, arg, "--list-audio-devices")) {
            options.list_audio_devices = true;
        } else if (std.mem.startsWith(u8, arg, "--audio-device=")) {
            options.capture_device = std.fmt.parseInt(i32, arg["--audio-device=".len..], 10) catch return error.InvalidAudioDevice;
            if (options.capture_device < 0) return error.InvalidAudioDevice;
        } else if (std.mem.startsWith(u8, arg, "--scene=")) {
            const path = arg["--scene=".len..];
            if (path.len == 0) return error.InvalidScenePath;
            options.scene_path = path;
        } else if (std.mem.startsWith(u8, arg, "--")) {
            return error.UnknownOption;
        } else if (options.file == null) {
            options.file = arg;
        } else {
            return error.TooManyFiles;
        }
    }
    return options;
}

test "parse capture and file options" {
    const options = try parse(&[_][]const u8{ "--system-audio", "--audio-device=2", "song.wav" });
    try std.testing.expectEqual(capture.Mode.system, options.capture_mode.?);
    try std.testing.expectEqual(@as(i32, 2), options.capture_device);
    try std.testing.expectEqualStrings("song.wav", options.file.?);
}

test "reject invalid options" {
    try std.testing.expectError(error.InvalidAudioDevice, parse(&[_][]const u8{"--audio-device=nope"}));
    try std.testing.expectError(error.UnknownOption, parse(&[_][]const u8{"--wat"}));
    try std.testing.expectError(error.TooManyFiles, parse(&[_][]const u8{ "one.wav", "two.wav" }));
}

test "scene script is independent of audio and capture arguments" {
    const options = try parse(&.{ "--scene=my scene.lua", "song.wav", "--system-audio" });
    try std.testing.expectEqualStrings("my scene.lua", options.scene_path.?);
    try std.testing.expectEqualStrings("song.wav", options.file.?);
    try std.testing.expectEqual(capture.Mode.system, options.capture_mode.?);
    try std.testing.expectError(error.InvalidScenePath, parse(&.{"--scene="}));
}
