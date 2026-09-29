//! User-edit history. Script animation is excluded; a scene change starts a new history.
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

    pub fn capture(scene: *Scene) Snapshot {
        var result: Snapshot = .{ .values = undefined };
        for (settings.entries, &result.values, scene.owned, scene.previous) |entry, *value, owned, previous| value.* = if (owned) previous else entry.get();
        for (scene.params(), 0..) |param, i| result.params[i] = param.value;
        return result;
    }

    fn apply(self: Snapshot, scene: *Scene) void {
        for (settings.entries, self.values, scene.owned) |entry, value, owned| {
            if (entry.visual() and !owned) entry.set(value);
        }
        for (scene.params(), 0..) |*param, i| param.value = std.math.clamp(self.params[i], param.min, param.max);
    }

    fn equal(a: Snapshot, b: Snapshot) bool {
        for (settings.entries, a.values, b.values) |entry, x, y| if (entry.visual() and x != y) return false;
        return std.mem.eql(f32, &a.params, &b.params);
    }
};

pub const History = struct {
    items: [64]Snapshot = undefined,
    len: usize = 0,
    position: usize = 0,
    revision: u64 = 0,

    pub fn sync(self: *History, scene: *Scene) void {
        if (self.len == 0 or self.revision != scene.revision) self.reset(scene);
    }
    pub fn reset(self: *History, scene: *Scene) void {
        self.items[0] = Snapshot.capture(scene);
        self.len = 1;
        self.position = 0;
        self.revision = scene.revision;
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
        self.position -= 1;
        self.items[self.position].apply(scene);
    }
    pub fn redo(self: *History, scene: *Scene) void {
        self.sync(scene);
        if (self.position + 1 >= self.len) return;
        self.position += 1;
        self.items[self.position].apply(scene);
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
