const std = @import("std");
const Scene = @import("Scene.zig");
const c = Scene.c;
const Config = @import("../core/config.zig");
const settings = @import("settings.zig");
const expect = std.testing.expect;
const equal = std.testing.expectEqual;
const strings = std.testing.expectEqualStrings;
const frame: c.ZsFrame = .{ .width = 800, .height = 600, .dt = 1.0 / 60.0 };

fn load(scene: *Scene, source: []const u8) !void {
    if (!scene.loadSource(source, "test.lua", false)) {
        std.debug.print("Unexpected Lua error: {s}\n", .{scene.errorMessage()});
        return error.ScriptDidNotLoad;
    }
}

test "Lua callbacks share state, current context, and normalized colors" {
    var scene: Scene = .{};
    defer scene.deinit();
    try load(&scene,
        \\local count = 0
        \\return { name = "Test", mode = "replace",
        \\ setup = function(ctx) count = 10; assert(ctx.width == 1024) end,
        \\ update = function(ctx) count = count + 1; assert(ctx.width == 800) end,
        \\ draw = function(ctx) gfx.circle(count, ctx.height / 2, 5, gfx.hsv(0, 1, 1, 0.5)) end }
    );
    try expect(!scene.usesBuiltin());
    try strings("Test", scene.name());
    scene.update(frame);
    try equal(@as(usize, 1), scene.commands().len);
    const command = scene.commands()[0];
    try equal(c.ZS_CIRCLE, command.kind);
    try equal(@as(f32, 11), command.values[0]);
    try equal(@as(f32, 300), command.values[1]);
    try equal([4]u8{ 255, 0, 0, 128 }, command.color);
    scene.update(frame);
    try equal(@as(f32, 12), scene.commands()[0].values[0]);
}

test "config applies transactionally and unloading restores owned settings" {
    const before = settings.snapshot();
    var scene: Scene = .{};
    defer scene.deinit();
    try load(&scene,
        \\return { config = { window = { fps_limit = 120, always_on_top = false },
        \\ scene = { bubble = false }, wave_lines = { color1 = { h = 90, s = 0.5 } } } }
    );
    try expect(scene.usesBuiltin());
    try equal(@as(f32, 120), Config.Window.fps_limit);
    try expect(!Config.Window.always_on_top);
    try expect(!Config.Scene.bubble);
    try equal(@as(f32, 90), Config.Visualizer.WaveFormLine.color1.x);
    try expect(!scene.loadSource("scene.set('window.fps_limit', 30); error('broken setup')", "bad.lua", true));
    try equal(@as(f32, 120), Config.Window.fps_limit);
    try expect(scene.runtime != null);
    scene.unload();
    const after = settings.snapshot();
    for (before, after) |a, b| try equal(a.value, b.value);
}

test "reload removes stale settings and preserves clamped parameter values" {
    const original_fps = Config.Window.fps_limit;
    var scene: Scene = .{};
    defer scene.deinit();
    try load(&scene,
        \\return { config = { window = { fps_limit = 144 } },
        \\ params = {{id='speed', min=0, max=10, default=2}} }
    );
    scene.params()[0].value = 8;
    try expect(scene.loadSource(
        \\return { params = {{id='speed', min=0, max=5, default=1}},
        \\ setup = function(ctx) assert(scene.param('speed') == 5) end }
    , "reload.lua", true));
    try equal(@as(f32, 5), scene.params()[0].value);
    try equal(original_fps, Config.Window.fps_limit);
}

test "runtime failures discard commands and settings and restore the built-in scene" {
    const original_fps = Config.Window.fps_limit;
    var scene: Scene = .{};
    defer scene.deinit();
    try load(&scene,
        \\return { mode='replace', config={window={fps_limit=60}},
        \\ draw=function(ctx) scene.set('window.fps_limit', 10); gfx.circle(0,0,10); error('draw failed') end }
    );
    scene.update(frame);
    try expect(scene.runtime == null);
    try expect(scene.usesBuiltin());
    try equal(@as(usize, 0), scene.commands().len);
    try equal(original_fps, Config.Window.fps_limit);
    try expect(std.mem.indexOf(u8, scene.errorMessage(), "draw failed") != null);
}

test "syntax and setup errors leave the previous scene running" {
    var scene: Scene = .{};
    defer scene.deinit();
    try load(&scene, "return {name='Working', draw=function(ctx) gfx.rect(1,2,3,4) end}");
    try expect(!scene.loadSource("return { this is invalid", "broken.lua", true));
    const message = try std.testing.allocator.dupe(u8, scene.errorMessage());
    defer std.testing.allocator.free(message);
    scene.update(frame);
    try strings("Working", scene.name());
    try strings(message, scene.errorMessage());
    try equal(@as(usize, 1), scene.commands().len);
}

test "unknown paths, incorrect types and out of range settings are rejected" {
    var scene: Scene = .{};
    defer scene.deinit();
    for ([_][]const u8{
        "return {config={window={unknown=1}}}",
        "return {config={window={fps_limit=361}}}",
        "return {config={scene={halo=1}}}",
        "return {config={audio={volume='0.5'}}}",
        "return {config={halo={radius=0/0}}}",
        "return {mode='wrong'}",
        "return {draw=42}",
        "return {params={{id='x',min=0,max=1,default=2}}}",
        "return {params={{id='x',min=0,max=1,default=0},{id='x',min=0,max=1,default=0}}}",
    }) |source| try expect(!scene.loadSource(source, "bad.lua", false));
    // Decimal endpoints must not be rejected by a float-to-double range conversion.
    try load(&scene, "return {config={audio={wave_gain=0.1},motion={attack_seconds=0.01},window={opacity=0.15}}}");
}

test "Lua instruction and memory budgets recover without hanging" {
    var scene: Scene = .{};
    defer scene.deinit();
    try expect(!scene.loadSource("while true do end", "loop.lua", false));
    try expect(scene.errorMessage().len > 0);
    try expect(!scene.loadSource("while true do pcall(function() while true do end end) end", "caught-loop.lua", false));
    try expect(!scene.loadSource("local x=string.rep('x', 32*1024*1024); return {}", "memory.lua", false));
    try load(&scene, "return {update=function(ctx) while true do end end}");
    scene.update(frame);
    try expect(scene.runtime == null);
    try load(&scene, "return {name='Recovered'}");
    try strings("Recovered", scene.name());
}

test "scripts cannot access host I/O, load code, or install finalizers" {
    var scene: Scene = .{};
    defer scene.deinit();
    try load(&scene,
        \\assert(io == nil and os == nil and package == nil and debug == nil and coroutine == nil)
        \\assert(load == nil and dofile == nil and loadfile == nil and require == nil)
        \\assert(getmetatable == nil and setmetatable == nil and collectgarbage == nil)
        \\assert(math and string and table and utf8)
        \\return {}
    );
}

test "invalid drawing, non-finite values, and command overflows are contained" {
    var scene: Scene = .{};
    defer scene.deinit();
    for ([_][]const u8{
        "return {draw=function() gfx.circle(0,0,-1) end}",
        "return {draw=function() gfx.line(0,0,1/0,1,2) end}",
        "return {draw=function() gfx.rect(0,0,1,1,{2,0,0}) end}",
        "return {draw=function() gfx.camera{position={0,0,0},target={0,0,0}} end}",
        "return {draw=function() for i=1,4097 do gfx.circle(i,1,1) end end}",
        "return {update=function() gfx.circle(1,1,1) end}",
    }) |source| {
        try load(&scene, source);
        scene.update(frame);
        try expect(scene.runtime == null);
        try equal(@as(usize, 0), scene.commands().len);
        try expect(scene.errorMessage().len > 0);
    }
    // A script may catch a drawing error; the partial command must never render.
    try load(&scene, "return {draw=function() pcall(gfx.circle,0,0,-1); gfx.circle(1,2,3) end}");
    scene.update(frame);
    try equal(@as(usize, 1), scene.commands().len);
    try equal(@as(f32, 3), scene.commands()[0].values[2]);
}

test "audio arrays and mouse data refresh without retaining a stale tail" {
    var scene: Scene = .{};
    defer scene.deinit();
    try load(&scene,
        \\return { update = function(ctx)
        \\ assert(ctx.audio.samples[1] == 0.5 and ctx.audio.spectrum[1] == 0.25)
        \\ assert(#ctx.audio.samples == ctx.time and ctx.mouse.down and ctx.audio.beat)
        \\ assert(ctx.mouse.x == 42 and ctx.audio.capturing)
        \\end }
    );
    const samples = [_]f32{ 0.5, 0.1, 0.2 };
    const spectrum = [_]f32{0.25};
    var context = frame;
    context.samples = &samples;
    context.spectrum = &spectrum;
    context.sample_count = 3;
    context.spectrum_count = 1;
    context.time = 3;
    context.mouse_down = 1;
    context.mouse_x = 42;
    context.beat = 1;
    context.capturing = 1;
    scene.update(context);
    try expect(scene.runtime != null);
    context.sample_count = 1;
    context.time = 1;
    scene.update(context);
    try expect(scene.runtime != null);
}

test "all bundled scenes run with realistic audio frames" {
    var scene: Scene = .{};
    defer scene.deinit();
    const samples: [1024]f32 = @splat(0.25);
    const spectrum: [512]f32 = @splat(0.05);
    var context = frame;
    context.samples = &samples;
    context.spectrum = &spectrum;
    context.sample_count = samples.len;
    context.spectrum_count = spectrum.len;
    for (Scene.examples, 0..) |_, i| {
        scene.loadExample(@enumFromInt(i));
        for (0..60) |step| {
            context.time = @as(f32, @floatFromInt(step)) * context.dt;
            scene.update(context);
            if (scene.runtime == null) std.debug.print("Example failed: {s}\n", .{scene.errorMessage()});
            try expect(scene.runtime != null);
        }
        try expect(scene.errorMessage().len == 0);
        try expect(scene.params().len > 0);
    }
}

test "file watcher reloads edits, keeps a working scene after errors, and honors its toggle" {
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    const io = std.testing.io;
    const path = try std.fmt.allocPrint(std.testing.allocator, ".zig-cache/tmp/{s}/scene.lua", .{temporary.sub_path});
    defer std.testing.allocator.free(path);
    var scene: Scene = .{};
    defer scene.deinit();
    try temporary.dir.writeFile(io, .{ .sub_path = "scene.lua", .data = "return {name='First'}" });
    scene.loadFile(path);
    try strings("First", scene.name());
    var tick = frame;
    tick.dt = 1;
    try temporary.dir.writeFile(io, .{ .sub_path = "scene.lua", .data = "return {name='Second'}" });
    scene.update(tick);
    try strings("Second", scene.name());
    try temporary.dir.writeFile(io, .{ .sub_path = "scene.lua", .data = "syntax error" });
    scene.update(tick);
    try strings("Second", scene.name());
    try expect(scene.errorMessage().len > 0);
    scene.auto_reload = false;
    try temporary.dir.writeFile(io, .{ .sub_path = "scene.lua", .data = "return {name='Third'}" });
    scene.update(tick);
    try strings("Second", scene.name());
    scene.reload();
    try strings("Third", scene.name());
    try expect(scene.errorMessage().len == 0);
    // A missing file can be created later and will recover automatically.
    scene.loadFile(".zig-cache/does-not-exist/scene.lua");
    try strings("Third", scene.name());
    scene.loadFile(path);
    try strings("Third", scene.name());
    scene.unload();
    try expect(!scene.canReload());
    scene.update(tick);
    try expect(scene.runtime == null);
}

test "scene file size limit preserves the running scene and recovers after a smaller edit" {
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    const io = std.testing.io;
    const path = try std.fmt.allocPrint(std.testing.allocator, ".zig-cache/tmp/{s}/scene.lua", .{temporary.sub_path});
    defer std.testing.allocator.free(path);
    var scene: Scene = .{};
    defer scene.deinit();

    const source = try std.testing.allocator.alloc(u8, c.ZS_SOURCE_LIMIT + 1);
    defer std.testing.allocator.free(source);
    @memset(source, ' ');
    const script = "return {name='At limit'}";
    @memcpy(source[0..script.len], script);
    try temporary.dir.writeFile(io, .{ .sub_path = "scene.lua", .data = source[0..c.ZS_SOURCE_LIMIT] });
    scene.loadFile(path);
    try strings("At limit", scene.name());
    try expect(scene.errorMessage().len == 0);

    try temporary.dir.writeFile(io, .{ .sub_path = "scene.lua", .data = source });
    scene.reload();
    try strings("At limit", scene.name());
    try expect(std.mem.indexOf(u8, scene.errorMessage(), "1 MiB") != null);

    try temporary.dir.writeFile(io, .{ .sub_path = "scene.lua", .data = "return {name='Recovered'}" });
    var tick = frame;
    tick.dt = 1;
    scene.update(tick);
    try strings("Recovered", scene.name());
    try expect(scene.errorMessage().len == 0);
}

test "settings registry has unique names and valid default ranges" {
    const snapshot = settings.snapshot();
    try expect(snapshot.len <= c.ZS_MAX_SETTINGS);
    for (settings.entries, 0..) |entry, i| {
        try expect(entry.get() >= entry.min and entry.get() <= entry.max);
        for (settings.entries[i + 1 ..]) |other| try expect(!std.mem.eql(u8, entry.name, other.name));
    }
}
