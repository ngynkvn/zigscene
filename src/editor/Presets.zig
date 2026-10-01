//! Versioned visual presets and user color swatches. All writes replace atomically.
const std = @import("std");
const builtin = @import("builtin");
const settings = @import("../scripting/settings.zig");
const State = @import("State.zig");
const Scene = @import("../scripting/Scene.zig");
const allocator = @import("../core/memory.zig").allocator;
pub const capacity = 24;
const Pair = struct { name: []const u8, value: f64 };
const Record = struct { name: []const u8, scene: []const u8 = "", example: ?Scene.Example = null, values: []const Pair, params: []const Pair = &.{} };
const Document = struct { version: u32 = 1, presets: []const Record, swatches: [8][3]f32 = initial_swatches };
const initial_swatches = [8][3]f32{ .{ 190, 0.8, 1 }, .{ 280, 0.7, 1 }, .{ 20, 0.85, 1 }, .{ 140, 0.7, 0.9 }, .{ 330, 0.6, 1 }, .{ 55, 0.8, 1 }, .{ 220, 0.7, 0.8 }, .{ 0, 0, 1 } };

pub const Preset = struct {
    name_buffer: [64]u8 = @splat(0),
    path_buffer: [4096]u8 = @splat(0),
    example: ?Scene.Example = null,
    values: State.Values = @splat(0),
    param_ids: [16][48]u8 = @splat(@splat(0)),
    param_values: [16]f32 = @splat(0),
    param_count: usize = 0,

    pub fn name(self: *const Preset) [:0]const u8 {
        return std.mem.span(@as([*:0]const u8, @ptrCast(&self.name_buffer)));
    }
    fn path(self: *const Preset) [:0]const u8 {
        return std.mem.span(@as([*:0]const u8, @ptrCast(&self.path_buffer)));
    }

    pub fn capture(scene: *Scene, name_text: []const u8) !Preset {
        const label = std.mem.trim(u8, name_text, " \t\r\n");
        if (label.len == 0 or label.len >= 64 or std.mem.indexOfScalar(u8, label, 0) != null) return error.InvalidName;
        var result: Preset = .{ .values = State.Snapshot.capture(scene).values, .example = scene.example };
        @memcpy(result.name_buffer[0..label.len], label);
        if (scene.path().len > 0) {
            if (builtin.os.tag == .emscripten) return error.SceneUnavailable;
            const io = std.Io.Threaded.global_single_threaded.io();
            const resolved = try std.Io.Dir.cwd().realPathFileAlloc(io, scene.path(), allocator);
            defer allocator.free(resolved);
            if (resolved.len >= result.path_buffer.len) return error.PathTooLong;
            @memcpy(result.path_buffer[0..resolved.len], resolved);
        }
        for (scene.params(), 0..) |param, i| {
            result.param_ids[i] = param.id;
            result.param_values[i] = param.value;
            result.param_count += 1;
        }
        return result;
    }

    pub fn apply(self: *const Preset, scene: *Scene) !void {
        const original = settings.snapshot();
        const original_previous = scene.previous;
        // Setup must see the saved baseline too, not the outgoing look.
        for (settings.entries, self.values, 0..) |entry, value, i| {
            if (!entry.visual()) continue;
            if (scene.owned[i]) scene.previous[i] = value else entry.set(value);
        }
        errdefer {
            for (settings.entries, original) |entry, value| entry.set(value.value);
            scene.previous = original_previous;
        }
        // The scene loader retains its VM on compile/read failure. Retain its
        // reference as well so a failed preset cannot change future reloads.
        if (self.path().len > 0 or self.example != null) {
            const old_path = scene.path_buffer;
            const old_example = scene.example;
            const old_hash = scene.last_hash;
            const revision = scene.revision;
            if (self.example) |example| scene.loadExample(example) else scene.loadFile(self.path());
            if (scene.revision == revision) {
                scene.path_buffer = old_path;
                scene.example = old_example;
                scene.last_hash = old_hash;
                return error.SceneUnavailable;
            }
        } else scene.unload();
        for (settings.entries, self.values, 0..) |entry, value, i| {
            if (!entry.visual()) continue;
            if (scene.owned[i]) scene.previous[i] = value else entry.set(value);
        }
        for (scene.params()) |*param| {
            for (0..self.param_count) |i| {
                if (std.mem.eql(u8, std.mem.sliceTo(&param.id, 0), std.mem.sliceTo(&self.param_ids[i], 0))) {
                    param.value = std.math.clamp(self.param_values[i], param.min, param.max);
                    break;
                }
            }
        }
        State.history.reset(scene);
    }
};

pub const Store = struct {
    items: [capacity]Preset = undefined,
    len: usize = 0,
    swatches: [8][3]f32 = initial_swatches,

    fn find(self: *const Store, label: []const u8) ?usize {
        for (self.items[0..self.len], 0..) |*item, i| {
            if (std.mem.eql(u8, item.name(), label)) return i;
        }
        return null;
    }

    pub fn put(self: *Store, preset: Preset, replace: bool) !usize {
        if (self.find(preset.name())) |i| {
            if (!replace) return error.NameExists;
            self.items[i] = preset;
            return i;
        }
        if (self.len == capacity) return error.LibraryFull;
        self.items[self.len] = preset;
        self.len += 1;
        return self.len - 1;
    }

    pub fn encode(self: *const Store, gpa: std.mem.Allocator) ![]u8 {
        var records: [capacity]Record = undefined;
        var values: [capacity][settings.entries.len]Pair = undefined;
        var params: [capacity][16]Pair = undefined;
        for (self.items[0..self.len], 0..) |*item, index| {
            var count: usize = 0;
            for (settings.entries, item.values) |entry, value| {
                if (!entry.visual()) continue;
                values[index][count] = .{ .name = entry.name, .value = value };
                count += 1;
            }
            for (0..item.param_count) |i| params[index][i] = .{ .name = std.mem.sliceTo(&item.param_ids[i], 0), .value = item.param_values[i] };
            records[index] = .{ .name = item.name(), .scene = item.path(), .example = item.example, .values = values[index][0..count], .params = params[index][0..item.param_count] };
        }
        return std.json.Stringify.valueAlloc(gpa, Document{ .presets = records[0..self.len], .swatches = self.swatches }, .{ .whitespace = .indent_2 });
    }

    pub fn decode(self: *Store, source: []const u8) !void {
        const parsed = try std.json.parseFromSlice(Document, allocator, source, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();
        const doc = parsed.value;
        if (doc.version != 1 or doc.presets.len > capacity) return error.InvalidLibrary;
        var next: Store = .{};
        for (doc.presets) |record| {
            if (record.name.len == 0 or record.name.len >= 64 or record.scene.len >= 4096 or record.params.len > 16 or
                std.mem.indexOfScalar(u8, record.name, 0) != null or std.mem.indexOfScalar(u8, record.scene, 0) != null) return error.InvalidLibrary;
            var item: Preset = .{ .values = State.defaults, .example = record.example };
            @memcpy(item.name_buffer[0..record.name.len], record.name);
            @memcpy(item.path_buffer[0..record.scene.len], record.scene);
            for (record.values) |pair| {
                if (!std.math.isFinite(pair.value)) return error.InvalidLibrary;
                if (settings.find(pair.name)) |i| {
                    const entry = settings.entries[i];
                    if (entry.visual()) item.values[i] = std.math.clamp(pair.value, entry.min, entry.max);
                }
            }
            for (record.params, 0..) |pair, i| {
                if (pair.name.len == 0 or pair.name.len >= 48 or std.mem.indexOfScalar(u8, pair.name, 0) != null or !std.math.isFinite(pair.value) or @abs(pair.value) > 1000000) return error.InvalidLibrary;
                @memcpy(item.param_ids[i][0..pair.name.len], pair.name);
                item.param_values[i] = @floatCast(pair.value);
                item.param_count += 1;
            }
            _ = try next.put(item, false);
        }
        for (doc.swatches) |color| for (color, 0..) |value, i| {
            if (!std.math.isFinite(value) or value < 0 or value > (if (i == 0) @as(f32, 359) else 1)) return error.InvalidLibrary;
        };
        next.swatches = doc.swatches;
        self.* = next;
    }
};
pub var store: Store = .{};
var file_path: ?[]const u8 = null;
pub var load_failed = false;

pub fn init(preferences_path: ?[]const u8) void {
    if (builtin.os.tag == .emscripten) return;
    const preferences = preferences_path orelse return;
    const parent = std.fs.path.dirname(preferences) orelse return;
    file_path = std.fs.path.join(allocator, &.{ parent, "presets.json" }) catch return;
    const source = std.Io.Dir.cwd().readFileAlloc(std.Io.Threaded.global_single_threaded.io(), file_path.?, allocator, .limited(512 * 1024)) catch |err| {
        load_failed = err != error.FileNotFound;
        return;
    };
    defer allocator.free(source);
    store.decode(source) catch {
        load_failed = true;
    };
}
pub fn deinit() void {
    if (file_path) |path| allocator.free(path);
    file_path = null;
}
pub fn persistent() bool {
    return file_path != null;
}

pub fn write(dir: std.Io.Dir, io: std.Io, path: []const u8, library: *const Store) !void {
    const source = try library.encode(allocator);
    defer allocator.free(source);
    if (std.fs.path.dirname(path)) |parent| try dir.createDirPath(io, parent);
    const temporary = try std.fmt.allocPrint(allocator, "{s}.tmp", .{path});
    defer allocator.free(temporary);
    defer dir.deleteFile(io, temporary) catch {};
    try dir.writeFile(io, .{ .sub_path = temporary, .data = source });
    try dir.rename(temporary, dir, path, io);
}
pub fn save() !void {
    if (load_failed) return error.InvalidLibrary;
    if (builtin.os.tag == .emscripten) return;
    const path = file_path orelse return;
    try write(std.Io.Dir.cwd(), std.Io.Threaded.global_single_threaded.io(), path, &store);
}

/// Rolls back only the touched slot: a copy of the whole library is ~130 KiB,
/// more than the browser build's stack.
pub fn savePreset(item: Preset, replace: bool) !usize {
    const previous_len = store.len;
    const replaced: ?Preset = if (store.find(item.name())) |i| store.items[i] else null;
    const index = try store.put(item, replace);
    save() catch |err| {
        if (replaced) |old| store.items[index] = old else store.len = previous_len;
        return err;
    };
    return index;
}
pub fn saveSwatch(index: usize, color: [3]f32) !void {
    const previous = store.swatches[index];
    store.swatches[index] = color;
    save() catch |err| {
        store.swatches[index] = previous;
        return err;
    };
}

test "preset file round trip preserves names, visual settings and parameters" {
    const before = settings.snapshot();
    defer for (settings.entries, before) |entry, value| entry.set(value.value);
    State.initDefaults();
    var scene: Scene = .{};
    defer scene.deinit();
    scene.loadExample(.orbit);
    scene.params()[0].value = 210;
    var library: Store = .{};
    _ = try library.put(try Preset.capture(&scene, "My orbit"), false);
    const source = try library.encode(std.testing.allocator);
    defer std.testing.allocator.free(source);
    try std.testing.expect(std.mem.indexOf(u8, source, "audio.volume") == null);
    try std.testing.expect(std.mem.indexOf(u8, source, "window.opacity") == null);
    var restored: Store = .{};
    try restored.decode(source);
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try write(tmp.dir, std.testing.io, "presets.json", &restored);
    try write(tmp.dir, std.testing.io, "presets.json", &restored);
    scene.unload();
    const volume = settings.entries[settings.find("audio.volume").?];
    volume.set(0.23);
    try restored.items[0].apply(&scene);
    try std.testing.expectEqualStrings("My orbit", restored.items[0].name());
    try std.testing.expectEqual(@as(f32, 210), scene.params()[0].value);
    try std.testing.expectApproxEqAbs(@as(f64, 0.23), volume.get(), 1e-6);
}

test "invalid libraries and missing scenes preserve existing data" {
    State.initDefaults();
    var scene: Scene = .{};
    defer scene.deinit();
    var library: Store = .{};
    _ = try library.put(try Preset.capture(&scene, "Keep"), false);
    try std.testing.expectError(error.InvalidLibrary, library.decode("{\"version\":99,\"presets\":[]}"));
    try std.testing.expectEqualStrings("Keep", library.items[0].name());
    scene.loadExample(.orbit);
    const previous_runtime = scene.runtime;
    const previous_revision = scene.revision;
    var broken = library.items[0];
    const path = ".zig-cache/missing-preset-scene.lua";
    @memcpy(broken.path_buffer[0..path.len], path);
    try std.testing.expectError(error.SceneUnavailable, broken.apply(&scene));
    try std.testing.expectEqual(previous_runtime, scene.runtime);
    try std.testing.expectEqual(previous_revision, scene.revision);
    try std.testing.expectEqual(Scene.Example.orbit, scene.example.?);
    try std.testing.expectError(error.NameExists, library.put(library.items[0], false));
}

test "preset setup sees saved baseline and failed restore rolls it back" {
    const before = settings.snapshot();
    defer for (settings.entries, before) |entry, value| entry.set(value.value);
    const radius = settings.entries[settings.find("halo.radius").?];
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(std.testing.io, .{ .sub_path = "look.lua", .data = "return {config={halo={radius=scene.get('halo.radius')+10}}}" });
    const path = try tmp.dir.realPathFileAlloc(std.testing.io, "look.lua", std.testing.allocator);
    defer std.testing.allocator.free(path);
    var scene: Scene = .{};
    defer scene.deinit();
    radius.set(70);
    scene.loadFile(path);
    try std.testing.expect(scene.runtime != null);
    try std.testing.expectEqual(@as(f64, 80), radius.get());
    const preset = try Preset.capture(&scene, "Baseline");
    scene.unload();
    radius.set(150);
    try preset.apply(&scene);
    try std.testing.expectEqual(@as(f64, 80), radius.get());
    const previous = scene.previous;
    try tmp.dir.writeFile(std.testing.io, .{ .sub_path = "look.lua", .data = "invalid lua!" });
    try std.testing.expectError(error.SceneUnavailable, preset.apply(&scene));
    try std.testing.expectEqual(@as(f64, 80), radius.get());
    try std.testing.expectEqualSlices(f64, &previous, &scene.previous);
    scene.unload();
    try std.testing.expectEqual(@as(f64, 70), radius.get());
}

test "a failed save rolls back a replaced or appended preset" {
    const previous_store = store;
    const previous_failed = load_failed;
    defer {
        store = previous_store;
        load_failed = previous_failed;
    }
    State.initDefaults();
    var scene: Scene = .{};
    defer scene.deinit();
    store = .{};
    load_failed = false;
    var first = try Preset.capture(&scene, "Look");
    first.values[0] = 1;
    _ = try savePreset(first, false);
    // An unreadable library refuses writes; the in-memory store must not change.
    load_failed = true;
    var changed = first;
    changed.values[0] = 2;
    try std.testing.expectError(error.InvalidLibrary, savePreset(changed, true));
    try std.testing.expectEqual(@as(usize, 1), store.len);
    try std.testing.expectEqual(@as(f64, 1), store.items[0].values[0]);
    try std.testing.expectError(error.InvalidLibrary, savePreset(try Preset.capture(&scene, "Other"), false));
    try std.testing.expectEqual(@as(usize, 1), store.len);
}
