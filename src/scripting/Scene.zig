//! Owns a replaceable Lua VM and rolls back its host settings on unload/failure.
const Scene = @This();
const std = @import("std");
const settings = @import("settings.zig");
pub const c = settings.c;
const rl = @import("raylib");
const renderer = @import("render.zig");

pub const Example = enum { palette, orbit, sculpture };
pub const examples = [_]struct { label: [:0]const u8, source: []const u8 }{
    .{ .label = "Palette", .source = @embedFile("examples/palette.lua") },
    .{ .label = "Orbit", .source = @embedFile("examples/orbit.lua") },
    .{ .label = "Sculpture", .source = @embedFile("examples/sculpture.lua") },
};

runtime: ?*c.ZsScene = null,
previous: [settings.entries.len]f64 = @splat(0),
owned: [settings.entries.len]bool = @splat(false),
error_buffer: [2048]u8 = @splat(0),
path_buffer: [4096]u8 = @splat(0),
example: ?Example = null,
auto_reload: bool = true,
watch_elapsed: f32 = 0,
last_hash: ?u64 = null,
last_frame: c.ZsFrame = .{ .width = 1024, .height = 768 },

pub fn deinit(self: *Scene) void {
    self.stopRuntime();
}
fn stopRuntime(self: *Scene) void {
    if (self.runtime) |runtime| c.zs_destroy(runtime);
    self.runtime = null;
    for (settings.entries, &self.owned, self.previous) |entry, *owned, previous| {
        if (owned.*) entry.set(previous);
        owned.* = false;
    }
}
pub fn unload(self: *Scene) void {
    self.stopRuntime();
    self.path_buffer[0] = 0;
    self.error_buffer[0] = 0;
    self.example = null;
    self.last_hash = null;
}
pub fn errorMessage(self: *const Scene) [:0]const u8 {
    return std.mem.span(@as([*:0]const u8, @ptrCast(&self.error_buffer)));
}
pub fn path(self: *const Scene) [:0]const u8 {
    return std.mem.span(@as([*:0]const u8, @ptrCast(&self.path_buffer)));
}
pub fn name(self: *const Scene) [:0]const u8 {
    return if (self.runtime) |runtime| std.mem.span(c.zs_name(runtime)) else "Built-in scene";
}
pub fn logMessage(self: *const Scene) [:0]const u8 {
    return if (self.runtime) |runtime| std.mem.span(c.zs_log(runtime)) else "";
}
pub fn usesBuiltin(self: *const Scene) bool {
    return if (self.runtime) |runtime| c.zs_overlay(runtime) != 0 else true;
}
pub fn canReload(self: *const Scene) bool {
    return self.path().len != 0 or self.example != null;
}
pub fn params(self: *Scene) []c.ZsParam {
    const runtime = self.runtime orelse return &.{};
    var pointer: [*c]c.ZsParam = null;
    const count = c.zs_params(runtime, &pointer);
    return pointer[0..count];
}
pub fn commands(self: *const Scene) []const c.ZsCommand {
    const runtime = self.runtime orelse return &.{};
    var pointer: [*c]const c.ZsCommand = null;
    const count = c.zs_commands(runtime, &pointer);
    return pointer[0..count];
}
fn report(self: *Scene, message: []const u8) void {
    self.last_hash = null; // Retry unchanged content after a transient file error.
    @memset(&self.error_buffer, 0);
    const length = @min(message.len, self.error_buffer.len - 1);
    @memcpy(self.error_buffer[0..length], message[0..length]);
}
fn applyChanges(self: *Scene) void {
    const runtime = self.runtime orelse return;
    for (settings.entries, 0..) |entry, i| {
        var value: f64 = 0;
        if (c.zs_change(runtime, i, &value) == 0) continue;
        if (!self.owned[i]) {
            self.previous[i] = entry.get();
            self.owned[i] = true;
        }
        entry.set(value);
    }
}
/// Compile/setup a candidate without changing the running VM or host settings.
/// Removed settings return to their pre-script values; slider values survive reload.
pub fn loadSource(self: *Scene, source: []const u8, chunk_name: [:0]const u8, preserve_params: bool) bool {
    if (@import("builtin").os.tag == .emscripten) {
        self.report("Lua scenes are currently supported in the native app only.");
        return false;
    }
    var snapshot = settings.snapshot();
    for (&snapshot, self.owned, self.previous) |*entry, owned, previous| if (owned) {
        entry.value = previous;
    };
    const next = c.zs_create(source.ptr, source.len, chunk_name.ptr, &snapshot, snapshot.len, &self.last_frame, if (preserve_params) self.runtime else null, &self.error_buffer, self.error_buffer.len) orelse return false;
    self.stopRuntime();
    self.runtime = next;
    self.error_buffer[0] = 0;
    self.applyChanges();
    return true;
}
pub fn loadExample(self: *Scene, example: Example) void {
    self.path_buffer[0] = 0;
    self.last_hash = null;
    self.example = example;
    const entry = examples[@intFromEnum(example)];
    _ = self.loadSource(entry.source, entry.label, false);
}
pub fn loadFile(self: *Scene, filename: []const u8) void {
    if (filename.len == 0 or filename.len >= self.path_buffer.len or std.mem.indexOfScalar(u8, filename, 0) != null) {
        self.report("Scene path is empty or too long.");
        return;
    }
    // The caller may pass our own path, so copy before clearing the buffer.
    var copy: [4096]u8 = @splat(0);
    @memcpy(copy[0..filename.len], filename);
    self.path_buffer = copy;
    self.example = null;
    self.last_hash = null;
    self.readFile(true, false);
}
fn readFile(self: *Scene, force: bool, preserve_params: bool) void {
    if (@import("builtin").os.tag == .emscripten) {
        self.report("Lua scenes are currently supported in the native app only.");
        return;
    }
    // Scene loading runs synchronously on the app thread, like the other native I/O.
    const io = std.Io.Threaded.global_single_threaded.io();
    const handle = std.Io.Dir.cwd().openFile(io, self.path(), .{}) catch {
        self.report("Cannot open scene file. Save it, then press F5.");
        return;
    };
    defer handle.close(io);
    const length = handle.length(io) catch {
        self.report("Cannot read scene file.");
        return;
    };
    if (length > c.ZS_SOURCE_LIMIT) {
        self.report("Scene file exceeds the 1 MiB limit or cannot be read.");
        return;
    }
    const source = std.heap.c_allocator.alloc(u8, @intCast(length)) catch {
        self.report("Cannot allocate scene source.");
        return;
    };
    defer std.heap.c_allocator.free(source);
    const bytes_read = handle.readPositionalAll(io, source, 0) catch {
        self.report("Cannot read scene file.");
        return;
    };
    if (bytes_read != source.len) {
        self.report("Scene file changed while reading. Save it and retry.");
        return;
    }
    const hash = std.hash.Wyhash.hash(0, source);
    if (!force and self.last_hash == hash) return;
    self.last_hash = hash;
    _ = self.loadSource(source, self.path(), preserve_params);
}
pub fn reload(self: *Scene) void {
    if (self.path().len != 0) self.readFile(true, true) else if (self.example) |example| {
        const entry = examples[@intFromEnum(example)];
        _ = self.loadSource(entry.source, entry.label, true);
    }
}
pub fn update(self: *Scene, frame: c.ZsFrame) void {
    self.last_frame = frame;
    if (self.auto_reload and self.path().len != 0) {
        self.watch_elapsed += frame.dt;
        if (self.watch_elapsed >= 0.75) {
            self.watch_elapsed = 0;
            self.readFile(false, true);
        }
    }
    const runtime = self.runtime orelse return;
    const snapshot = settings.snapshot();
    // Preserve a failed reload's error while the old scene keeps running.
    var error_buffer: [2048]u8 = @splat(0);
    if (c.zs_step(runtime, &snapshot, &frame, &error_buffer, error_buffer.len) == 0) {
        self.error_buffer = error_buffer;
        self.stopRuntime();
        return;
    }
    self.applyChanges();
}
pub fn render(self: *const Scene, camera: rl.Camera3D) void {
    renderer.draw(self.commands(), camera);
}
