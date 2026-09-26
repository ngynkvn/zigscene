//! Best-effort native preferences, using the same stable names as Lua settings.
const std = @import("std");
const builtin = @import("builtin");
const settings = @import("../scripting/settings.zig");
const allocator = std.heap.page_allocator;

pub fn path(environ: std.process.Environ, gpa: std.mem.Allocator) !?[]const u8 {
    if (builtin.os.tag == .emscripten) return null;
    var env = try environ.createMap(gpa);
    defer env.deinit();
    return resolvePath(env, gpa);
}

fn nonempty(env: std.process.Environ.Map, key: []const u8) ?[]const u8 {
    const value = env.get(key) orelse return null;
    return if (value.len > 0) value else null;
}

fn resolvePath(env: std.process.Environ.Map, gpa: std.mem.Allocator) !?[]const u8 {
    const parts: []const []const u8 = switch (builtin.os.tag) {
        .windows => &.{ nonempty(env, "APPDATA") orelse return null, "zigscene", "settings.conf" },
        .macos => &.{ nonempty(env, "HOME") orelse return null, "Library", "Application Support", "zigscene", "settings.conf" },
        else => if (nonempty(env, "XDG_CONFIG_HOME")) |base|
            if (std.fs.path.isAbsolute(base)) &.{ base, "zigscene", "settings.conf" } else &.{ nonempty(env, "HOME") orelse return null, ".config", "zigscene", "settings.conf" }
        else
            &.{ nonempty(env, "HOME") orelse return null, ".config", "zigscene", "settings.conf" },
    };
    return try std.fs.path.join(gpa, parts);
}

pub fn load(file_path: ?[]const u8) void {
    if (builtin.os.tag == .emscripten) return;
    const filename = file_path orelse return;
    const io = std.Io.Threaded.global_single_threaded.io();
    const contents = std.Io.Dir.cwd().readFileAlloc(io, filename, allocator, .limited(64 * 1024)) catch return;
    defer allocator.free(contents);
    decode(contents);
}

pub fn save(file_path: ?[]const u8) void {
    if (builtin.os.tag == .emscripten) return;
    const filename = file_path orelse return;
    write(std.Io.Dir.cwd(), std.Io.Threaded.global_single_threaded.io(), filename) catch {};
}

fn write(dir: std.Io.Dir, io: std.Io, filename: []const u8) !void {
    var buffer: [16384]u8 = undefined;
    const contents = try encode(&buffer);
    if (std.fs.path.dirname(filename)) |parent| try dir.createDirPath(io, parent);
    const temporary = try std.fmt.allocPrint(allocator, "{s}.tmp", .{filename});
    defer allocator.free(temporary);
    defer dir.deleteFile(io, temporary) catch {};
    try dir.writeFile(io, .{ .sub_path = temporary, .data = contents });
    try dir.rename(temporary, dir, filename, io);
}

pub fn decode(contents: []const u8) void {
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        const separator = std.mem.indexOfScalar(u8, line, '=') orelse continue;
        const name = std.mem.trim(u8, line[0..separator], " \t\r");
        const text = std.mem.trim(u8, line[separator + 1 ..], " \t\r");
        const value = std.fmt.parseFloat(f64, text) catch continue;
        if (!std.math.isFinite(value)) continue;
        for (settings.entries) |entry| {
            if (!std.mem.eql(u8, name, entry.name)) continue;
            entry.set(std.math.clamp(value, entry.min, entry.max));
            break;
        }
    }
}

pub fn encode(buffer: []u8) ![]const u8 {
    var writer = std.Io.Writer.fixed(buffer);
    for (settings.entries) |entry| try writer.print("{s}={d}\n", .{ entry.name, entry.get() });
    return writer.buffered();
}

fn restore(values: [settings.entries.len]settings.c.ZsSetting) void {
    for (settings.entries, values) |entry, value| entry.set(value.value);
}

test "preferences round trip every registered value through a file" {
    const before = settings.snapshot();
    defer restore(before);
    for (settings.entries, 0..) |entry, i| entry.set(if (i % 2 == 0) entry.min else entry.max);
    const expected = settings.snapshot();
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const io = std.testing.io;
    try write(tmp.dir, io, "nested/settings.conf");
    restore(before);
    const contents = try tmp.dir.readFileAlloc(io, "nested/settings.conf", std.testing.allocator, .limited(64 * 1024));
    defer std.testing.allocator.free(contents);
    decode(contents);
    for (settings.entries, expected) |entry, value| try std.testing.expectEqual(value.value, entry.get());
    // Replacing an existing file exercises the save path used on subsequent exits.
    try write(tmp.dir, io, "nested/settings.conf");
}

test "preferences clamp ranges and ignore unknown or malformed values" {
    const before = settings.snapshot();
    defer restore(before);
    decode("audio.volume=9\naudio.wave_gain=-5\nwindow.fps_limit=nan\nwindow.opacity=inf\nunknown.key=12\nscene.bubble=garbage\nbad line\ninterface.scale_percent = 125\r\n");
    const Config = @import("config.zig");
    try std.testing.expectEqual(@as(f32, 1), Config.Audio.volume);
    try std.testing.expectEqual(@as(f32, 0.1), Config.Audio.wave_gain);
    try std.testing.expectEqual(@as(f32, 125), Config.Interface.scale_percent);
    for (settings.entries, before) |entry, value| {
        if (std.mem.eql(u8, entry.name, "audio.volume") or std.mem.eql(u8, entry.name, "audio.wave_gain") or std.mem.eql(u8, entry.name, "interface.scale_percent")) continue;
        try std.testing.expectEqual(value.value, entry.get());
    }
}

test "saving after scene teardown preserves the user baseline" {
    const before = settings.snapshot();
    defer restore(before);
    var scene: @import("../scripting/Scene.zig") = .{};
    try std.testing.expect(scene.loadSource("return { config = { audio = { volume = 0.123 }, window = { fps_limit = 73 } } }", "test.lua", false));
    scene.deinit();
    var buffer: [16384]u8 = undefined;
    const contents = try encode(&buffer);
    for (settings.entries) |entry| entry.set(entry.min);
    decode(contents);
    for (settings.entries, before) |entry, value| try std.testing.expectEqual(value.value, entry.get());
}

test "preference location uses platform environment and missing roots disable it" {
    var env = std.process.Environ.Map.init(std.testing.allocator);
    defer env.deinit();
    try std.testing.expectEqual(@as(?[]const u8, null), try resolvePath(env, std.testing.allocator));
    const base = if (builtin.os.tag == .windows) "C:\\Users\\test" else "/home/test";
    try env.put(if (builtin.os.tag == .windows) "APPDATA" else "HOME", base);
    const expected = try std.fs.path.join(std.testing.allocator, switch (builtin.os.tag) {
        .windows => &.{ base, "zigscene", "settings.conf" },
        .macos => &.{ base, "Library", "Application Support", "zigscene", "settings.conf" },
        else => &.{ base, ".config", "zigscene", "settings.conf" },
    });
    defer std.testing.allocator.free(expected);
    const actual = (try resolvePath(env, std.testing.allocator)).?;
    defer std.testing.allocator.free(actual);
    try std.testing.expectEqualStrings(expected, actual);
    if (builtin.os.tag == .linux) {
        for ([_][]const u8{ "", "relative", "/tmp/preferences" }) |xdg| {
            try env.put("XDG_CONFIG_HOME", xdg);
            const resolved = (try resolvePath(env, std.testing.allocator)).?;
            defer std.testing.allocator.free(resolved);
            try std.testing.expectEqualStrings(if (std.fs.path.isAbsolute(xdg)) "/tmp/preferences/zigscene/settings.conf" else expected, resolved);
        }
    }
}
