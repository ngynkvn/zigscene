const std = @import("std");

const lua = @import("deps/build/lua.zig");
const emcc = @import("deps/build/emcc.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const emscripten_dir = if (target.result.os.tag == .emscripten) try emcc.sdkDir(b) else null;
    const emscripten_include = if (emscripten_dir) |dir| b.pathJoin(&.{ dir, "cache", "sysroot", "include" }) else null;

    const lua_lib = lua.build(b, target, emscripten_include);
    const opts = b.addOptions();
    const tracy_enable = b.option(bool, "tracy_enable", "Enable Tracy integration. Supply path to Tracy source") orelse false;
    const enable_callstack = b.option(
        bool,
        "tracy_callstack",
        "Include callstack information with Tracy data. Does nothing if -Dtracy is not provided",
    ) orelse tracy_enable;
    const enable_allocation = b.option(
        bool,
        "tracy_allocation",
        "Include allocation information with Tracy data. Does nothing if -Dtracy is not provided",
    ) orelse tracy_enable;

    const tracy = b.dependency("tracy", .{
        .target = target,
        .optimize = optimize,
        .tracy_enable = tracy_enable,
        .tracy_callstack = enable_callstack,
        .tracy_allocation = enable_allocation,
    });
    const tracy_mod = tracy.module(if (target.query.isNative() and tracy_enable) "tracy" else "tracy-stub");

    // Keep the graphics backend optimized while debugging the application's Zig
    // code. Its per-vertex C work otherwise dominates development frame times.
    const raylib_optimize = b.option(std.lang.Optimize, "raylib-optimize", "Optimization mode for the graphics backend") orelse
        (if (optimize == .debug) .safe else optimize);
    const raylib = b.dependency("raylib", .{
        .target = target,
        .optimize = raylib_optimize,
        .@"emscripten-include" = emscripten_include,
    });

    const web_step = b.step("web", "Build the web application");
    const web_run_step = b.step("web-run", "Build and run the web application");
    if (emscripten_dir) |dir| {
        const run_step = emcc.runStep(b, dir);
        web_run_step.dependOn(&run_step.step);

        const exe_lib = b.addLibrary(.{
            .name = "zigscene",
            .use_lld = if (target.result.os.tag == .linux) false else null,
            .root_module = b.createModule(.{ .root_source_file = b.path("src/main.zig"), .target = target, .optimize = optimize }),
        });
        exe_lib.root_module.addIncludePath(b.graph.cwdRelativePath(emscripten_include.?));
        exe_lib.root_module.addImport("lua-scene", lua_lib.bindings);
        exe_lib.root_module.addOptions("options", opts);
        exe_lib.root_module.addImport("raylib", raylib.module("raylib"));
        exe_lib.root_module.addImport("tracy", tracy_mod);
        exe_lib.root_module.addCSourceFile(.{ .file = b.path("src/audio/picker.c") });
        const link_step = emcc.link(b, dir, &.{ exe_lib, raylib.artifact("raylib"), lua_lib.artifact });
        web_step.dependOn(&link_step.step);
        run_step.step.dependOn(&link_step.step);
    }

    const exe = b.addExecutable(.{
        .name = "zigscene",
        .use_lld = if (target.result.os.tag == .linux) false else null,
        .root_module = b.createModule(.{ .root_source_file = b.path(if (b.option(bool, "scene-bench", "Measure built-in scene frame times") orelse false) "src/scene_bench.zig" else if (b.option(bool, "ui-smoke", "Render editor screenshots for local visual QA") orelse false) "src/ui_smoke.zig" else if (b.option(bool, "pet-smoke", "Check desktop pet control transitions") orelse false) "src/pet_smoke.zig" else "src/main.zig"), .target = target, .optimize = optimize }),
    });
    exe.root_module.addImport("lua-scene", lua_lib.bindings);
    exe.root_module.addOptions("options", opts);

    b.installArtifact(exe);
    exe.root_module.addImport("raylib", raylib.module("raylib"));
    exe.root_module.addImport("tracy", tracy_mod);
    if (target.result.os.tag != .emscripten) addCapture(b, exe.root_module, raylib);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .use_lld = if (target.result.os.tag == .linux) false else null,
        .root_module = b.createModule(.{ .root_source_file = b.path("src/main.zig"), .target = target, .optimize = optimize }),
    });
    exe_unit_tests.root_module.addImport("lua-scene", lua_lib.bindings);
    exe_unit_tests.root_module.addImport("raylib", raylib.module("raylib"));
    exe_unit_tests.root_module.addImport("tracy", tracy_mod);
    exe_unit_tests.root_module.addOptions("options", opts);
    if (target.result.os.tag != .emscripten) {
        addCapture(b, exe_unit_tests.root_module, raylib);
        exe_unit_tests.root_module.addCMacro("ZIGSCENE_CAPTURE_TEST", "1");
        exe_unit_tests.root_module.addCSourceFile(.{ .file = b.path("tests/audio_refill_worker.c") });
    }

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
    const queue_tests = b.addTest(.{
        .root_module = b.createModule(.{ .root_source_file = b.path("src/audio_test.zig"), .target = target, .optimize = optimize }),
    });
    test_step.dependOn(&b.addRunArtifact(queue_tests).step);

    const check_step = b.step("check", "Check build");
    check_step.dependOn(&exe.step);
    check_step.dependOn(test_step);

    try addReleaseStep(b, opts);
}

const release_targets: []const std.Target.Query = &.{
    .{}, // Native
    .{ .cpu_arch = .x86_64, .os_tag = .windows },

    // TODO: fix linux builds because of wayland
    // .{ .cpu_arch = .aarch64, .os_tag = .linux },
    // .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    // .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
};

fn addReleaseStep(b: *std.Build, opts: *std.Build.Step.Options) !void {
    const release_step = b.step("release-build", "Create set of releases for distribution");
    for (release_targets) |t| {
        const target = b.resolveTargetQuery(t);
        const optimize: std.lang.Optimize = .safe;
        const tracy = b.dependency("tracy", .{
            .target = target,
            .optimize = optimize,
        });
        const tracy_mod = tracy.module("tracy-stub");

        const raylib = b.dependency("raylib", .{
            .target = target,
            .optimize = optimize,
        });
        const release_exe = b.addExecutable(.{
            .name = "zigscene",
            .use_lld = if (target.result.os.tag == .linux) false else null,
            .root_module = b.createModule(.{ .root_source_file = b.path("src/main.zig"), .target = target, .optimize = optimize }),
        });
        release_exe.root_module.addImport("lua-scene", lua.build(b, target, null).bindings);
        release_exe.root_module.addOptions("options", opts);
        release_exe.root_module.addImport("raylib", raylib.module("raylib"));
        release_exe.root_module.addImport("tracy", tracy_mod);
        addCapture(b, release_exe.root_module, raylib);
        release_step.dependOn(&b.addInstallArtifact(release_exe, .{ .dest_dir = .{ .override = .{ .custom = try t.zigTriple(b.allocator) } } }).step);
    }
}

fn addCapture(b: *std.Build, module: *std.Build.Module, raylib: *std.Build.Dependency) void {
    module.addIncludePath(raylib.namedLazyPath("miniaudio-include"));
    module.addCSourceFile(.{ .file = b.path("src/audio/capture.c") });
    module.addCSourceFile(.{ .file = b.path("src/audio/refill_worker.c") });
    module.addCSourceFile(.{ .file = b.path("src/audio/preview_decoder.c") });
    const dialogs = b.addLibrary(.{ .name = "audio-dialogs", .root_module = b.createModule(.{ .target = module.resolved_target.?, .optimize = .safe, .link_libc = true }) });
    dialogs.root_module.addCSourceFile(.{ .file = b.path("deps/tinyfiledialogs/tinyfiledialogs.c"), .flags = &.{"-Wno-deprecated-declarations"} });
    module.linkLibrary(dialogs);
    if (module.resolved_target.?.result.os.tag == .windows) {
        module.linkSystemLibrary("comdlg32", .{});
        module.linkSystemLibrary("ole32", .{});
        module.linkSystemLibrary("shell32", .{});
    }
}
