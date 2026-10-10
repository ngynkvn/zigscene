//! Visual edit and look-switch history. Script animation is excluded.
const std = @import("std");
const settings = @import("../scripting/settings.zig");
const Scene = @import("../scripting/Scene.zig");
pub const Values = [settings.entries.len]f64;
pub var defaults: Values = @splat(0);
var initialized = false;

pub fn initDefaults() void {
    for (settings.entries, &defaults) |entry, *value| value.* = entry.get();
    initialized = true;
}

pub const Snapshot = struct {
    values: Values,
    params: [Scene.c.ZS_MAX_PARAMS]f32 = @splat(0),
    param_ids: [Scene.c.ZS_MAX_PARAMS][48]u8 = @splat(@splat(0)),
    path: [4096]u8 = @splat(0),
    example: ?Scene.Example = null,
    scripted: bool = false,

    pub fn capture(scene: *Scene) Snapshot {
        var result: Snapshot = .{ .values = undefined, .path = scene.path_buffer, .example = scene.example, .scripted = scene.runtime != null };
        for (settings.entries, &result.values, scene.owned, scene.previous) |entry, *value, owned, previous| value.* = if (owned) previous else entry.get();
        for (scene.params(), 0..) |param, i| {
            result.params[i] = param.value;
            result.param_ids[i] = param.id;
        }
        return result;
    }

    fn apply(self: *const Snapshot, scene: *Scene) !void {
        const changed_source = self.example != scene.example or self.scripted != (scene.runtime != null) or !std.mem.eql(u8, std.mem.sliceTo(&self.path, 0), scene.path());
        if (changed_source) {
            const original = settings.snapshot();
            const old_previous = scene.previous;
            const old_path = scene.path_buffer;
            const old_example = scene.example;
            const old_hash = scene.last_hash;
            errdefer {
                for (settings.entries, original) |entry, old| entry.set(old.value);
                scene.previous = old_previous;
                scene.path_buffer = old_path;
                scene.example = old_example;
                scene.last_hash = old_hash;
            }
            for (settings.entries, self.values, 0..) |entry, value, i| {
                if (!entry.visual()) continue;
                if (scene.owned[i]) scene.previous[i] = value else entry.set(value);
            }
            const revision = scene.revision;
            if (!self.scripted) scene.unload() else if (self.example) |example| scene.loadExample(example) else if (self.path[0] != 0) scene.loadFile(std.mem.sliceTo(&self.path, 0)) else return error.SceneUnavailable;
            if (self.scripted and scene.revision == revision) return error.SceneUnavailable;
        }
        for (settings.entries, self.values, scene.owned, 0..) |entry, value, owned, i| {
            if (!entry.visual()) continue;
            if (owned) scene.previous[i] = value else entry.set(value);
        }
        for (scene.params()) |*param| for (self.param_ids, self.params) |id, value| {
            if (std.mem.eql(u8, std.mem.sliceTo(&id, 0), std.mem.sliceTo(&param.id, 0))) {
                param.value = std.math.clamp(value, param.min, param.max);
                break;
            }
        };
    }

    fn equal(a: Snapshot, b: Snapshot) bool {
        if (a.example != b.example or a.scripted != b.scripted or !std.mem.eql(u8, std.mem.sliceTo(&a.path, 0), std.mem.sliceTo(&b.path, 0))) return false;
        for (settings.entries, a.values, b.values) |entry, x, y| if (entry.visual() and x != y) return false;
        return std.mem.eql(f32, &a.params, &b.params);
    }
};

pub const History = struct {
    items: [64]Snapshot = undefined,
    len: usize = 0,
    position: usize = 0,
    revision: u64 = 0,
    notice: [:0]const u8 = "",

    pub fn sync(self: *History, scene: *Scene) void {
        if (self.len == 0 or self.revision != scene.revision) self.reset(scene);
    }
    pub fn reset(self: *History, scene: *Scene) void {
        self.items[0] = Snapshot.capture(scene);
        self.len = 1;
        self.position = 0;
        self.revision = scene.revision;
        self.notice = "";
    }
    pub fn record(self: *History, scene: *Scene) void {
        self.sync(scene);
        const next = Snapshot.capture(scene);
        if (Snapshot.equal(self.items[self.position], next)) return;
        self.len = self.position + 1; // A new edit discards the redo branch.
        if (self.len == self.items.len) {
            std.mem.copyForwards(Snapshot, self.items[0 .. self.items.len - 1], self.items[1..]);
            self.len -= 1;
        }
        self.items[self.len] = next;
        self.position = self.len;
        self.len += 1;
    }
    pub fn undo(self: *History, scene: *Scene) void {
        self.record(scene);
        if (self.position == 0) return;
        self.items[self.position - 1].apply(scene) catch {
            self.notice = "Scene unavailable; current look kept.";
            return;
        };
        self.position -= 1;
        self.revision = scene.revision;
        self.notice = "";
    }
    pub fn redo(self: *History, scene: *Scene) void {
        self.sync(scene);
        if (self.position + 1 >= self.len) return;
        self.items[self.position + 1].apply(scene) catch {
            self.notice = "Scene unavailable; current look kept.";
            return;
        };
        self.position += 1;
        self.revision = scene.revision;
        self.notice = "";
    }
};
pub var history: History = .{};

pub fn locked(pointer: *f32, scene: *const Scene) bool {
    const index = settings.indexOf(pointer) orelse return false;
    return scene.owned[index];
}
pub fn changed(pointer: *f32) bool {
    const index = settings.indexOf(pointer) orelse return false;
    return initialized and settings.entries[index].get() != defaults[index];
}
pub fn reset(pointer: *f32, scene: *Scene) void {
    const index = settings.indexOf(pointer) orelse return;
    if (initialized and !scene.owned[index]) settings.entries[index].set(defaults[index]);
}
pub fn resetPrefix(prefix: []const u8, scene: *Scene) void {
    if (!initialized) return;
    for (settings.entries, 0..) |entry, i| {
        if (!scene.owned[i] and std.mem.startsWith(u8, entry.name, prefix)) entry.set(defaults[i]);
    }
}

/// Restore the startup defaults captured before preferences or Lua overrides.
pub fn resetAll(scene: *Scene) void {
    if (!initialized) return;
    // Unload first so its saved baseline cannot overwrite the factory values.
    scene.unload();
    scene.auto_reload = true;
    for (settings.entries, defaults) |entry, value| entry.set(value);
    history.reset(scene);
}

test "history batches edits, branches redo, and excludes machine settings" {
    var scene: Scene = .{};
    const before = settings.snapshot();
    defer for (settings.entries, before) |entry, value| entry.set(value.value);
    var h: History = .{};
    h.sync(&scene);
    const index = settings.find("halo.radius").?;
    const original = settings.entries[index].get();
    settings.entries[index].set(80);
    settings.entries[index].set(90);
    h.record(&scene);
    try std.testing.expectEqual(@as(usize, 2), h.len);
    h.undo(&scene);
    try std.testing.expectEqual(original, settings.entries[index].get());
    h.redo(&scene);
    try std.testing.expectEqual(@as(f64, 90), settings.entries[index].get());
    h.undo(&scene);
    settings.entries[index].set(100);
    h.record(&scene);
    h.redo(&scene);
    try std.testing.expectEqual(@as(f64, 100), settings.entries[index].get());
    settings.entries[settings.find("audio.volume").?].set(0.12);
    h.record(&scene);
    try std.testing.expectEqual(@as(usize, 2), h.len);
}

test "script animation never becomes an undo edit; parameters do" {
    const before = settings.snapshot();
    defer for (settings.entries, before) |entry, value| entry.set(value.value);
    var scene: Scene = .{};
    defer scene.deinit();
    try std.testing.expect(scene.loadSource("return {config={halo={radius=80}}, params={{id='x',min=0,max=1,default=0.5}}}", "history.lua", false));
    var h: History = .{};
    h.sync(&scene);
    const index = settings.find("halo.radius").?;
    settings.entries[index].set(100);
    h.record(&scene);
    try std.testing.expectEqual(@as(usize, 1), h.len);
    scene.params()[0].value = 0.8;
    h.record(&scene);
    h.undo(&scene);
    try std.testing.expectEqual(@as(f32, 0.5), scene.params()[0].value);
    try std.testing.expectEqual(@as(f64, 100), settings.entries[index].get());
    scene.unload();
    h.sync(&scene);
    try std.testing.expectEqual(@as(usize, 1), h.len);
}

test "history capacity discards oldest edits without losing redo" {
    const before = settings.snapshot();
    defer for (settings.entries, before) |entry, value| entry.set(value.value);
    var scene: Scene = .{};
    var h: History = .{};
    const radius = settings.entries[settings.find("halo.radius").?];
    radius.set(40);
    h.sync(&scene);
    for (41..121) |value| {
        radius.set(@floatFromInt(value));
        h.record(&scene);
    }
    try std.testing.expectEqual(@as(usize, 64), h.len);
    for (0..100) |_| h.undo(&scene);
    try std.testing.expectEqual(@as(f64, 57), radius.get());
    for (0..100) |_| h.redo(&scene);
    try std.testing.expectEqual(@as(f64, 120), radius.get());
}

test "hard reset clears Lua overrides and history and persists factory defaults" {
    const before = settings.snapshot();
    const previous_defaults = defaults;
    const was_initialized = initialized;
    const previous_history = history;
    defer {
        for (settings.entries, before) |entry, value| entry.set(value.value);
        defaults = previous_defaults;
        initialized = was_initialized;
        history = previous_history;
    }
    initDefaults();
    var scene: Scene = .{};
    defer scene.deinit();
    for (settings.entries, defaults) |entry, value| entry.set(if (value == entry.max) entry.min else entry.max);
    scene.loadExample(.palette);
    try std.testing.expect(scene.runtime != null);
    scene.auto_reload = false;
    history.reset(&scene);
    settings.entries[settings.find("bubble.ring_radius").?].set(3);
    history.record(&scene);

    resetAll(&scene);
    try std.testing.expect(scene.runtime == null and !scene.canReload());
    try std.testing.expect(scene.auto_reload);
    try std.testing.expectEqual(@as(usize, 1), history.len);
    history.undo(&scene);
    history.redo(&scene);
    scene.unload();
    for (settings.entries, defaults, scene.owned) |entry, value, owned| {
        try std.testing.expectEqual(value, entry.get());
        try std.testing.expect(!owned);
    }

    const preferences = @import("../core/preferences.zig");
    var buffer: [16384]u8 = undefined;
    const saved = try preferences.encode(&buffer);
    for (settings.entries) |entry| entry.set(entry.min);
    preferences.decode(saved);
    for (settings.entries, defaults) |entry, value| try std.testing.expectEqual(value, entry.get());
}
