const std = @import("std");
const emcc = @import("deps/build/emcc.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

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

    const raylib = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
    });

    const run_option = b.step("web", "Build and run for web");
    if (target.result.os.tag == .emscripten) {
        const run_step = try emcc.emscriptenRunStep(b);
        run_option.dependOn(&run_step.step);

        const exe_lib = b.addStaticLibrary(.{
            .name = "zigscene",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });
        const cache_include = b.pathResolve(&.{ b.sysroot.?, "cache", "sysroot", "include" });
        exe_lib.addIncludePath(.{ .cwd_relative = cache_include });
        exe_lib.root_module.addImport("raylib", raylib.module("raylib"));
        exe_lib.root_module.addImport("tracy", tracy_mod);
        const link_step = try emcc.linkWithEmscripten(b, &[_]*std.Build.Step.Compile{ exe_lib, raylib.artifact("raylib") });
        run_step.step.dependOn(&link_step.step);
    }

    const exe = b.addExecutable(.{
        .name = "zigscene",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addOptions("options", opts);

    b.installArtifact(exe);
    exe.root_module.addImport("raylib", raylib.module("raylib"));
    exe.root_module.addImport("tracy", tracy_mod);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_unit_tests.root_module.addImport("raylib", raylib.module("raylib"));
    exe_unit_tests.root_module.addImport("tracy", tracy.module("tracy"));
    exe_unit_tests.root_module.addOptions("options", opts);

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

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
        const optimize = .ReleaseSafe;
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
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });
        release_exe.root_module.addOptions("options", opts);
        release_exe.root_module.addImport("raylib", raylib.module("raylib"));
        release_exe.root_module.addImport("tracy", tracy_mod);
        release_step.dependOn(&b.addInstallArtifact(release_exe, .{ .dest_dir = .{ .override = .{ .custom = try t.zigTriple(b.allocator) } } }).step);
    }
}
