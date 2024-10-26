const std = @import("std");
const emcc = @import("deps/build/emcc.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    emcc.hookSysrootIfNeeded(b, target);

    const opts = b.addOptions();
    const enable = b.option(bool, "tracy", "Enable Tracy integration. Supply path to Tracy source") orelse false;
    const enable_callstack = b.option(
        bool,
        "tracy_callstack",
        "Include callstack information with Tracy data. Does nothing if -Dtracy is not provided",
    ) orelse enable;
    const enable_allocation = b.option(
        bool,
        "tracy_allocation",
        "Include allocation information with Tracy data. Does nothing if -Dtracy is not provided",
    ) orelse enable;

    // const enable_ttyz = b.option(
    //     bool,
    //     "enable_ttyz",
    //     "Hook into console for debug information.",
    // ) orelse true;
    // opts.addOption(bool, "enable_ttyz", enable_ttyz);

    const tracy = b.dependency("tracy", .{
        .target = target,
        .optimize = optimize,
        .enable = enable,
        .tracy_callstack = enable_callstack,
        .tracy_allocation = enable_allocation,
    });

    const raylib = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
    });

    const run_option = b.step("web", "Build and run for web");
    if (target.result.os.tag == .emscripten) {
        const run_step = try emcc.emscriptenRunStep(b);
        run_option.dependOn(&run_step.step);
    }

    const exe = b.addExecutable(.{
        .name = "zigscene",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addOptions("options", opts);
    // if (enable_ttyz) {
    //     const ttyz = b.dependency("ttyz", .{
    //         .target = target,
    //         .optimize = optimize,
    //     });
    //
    //     exe.root_module.addImport("ttyz", ttyz.module("ttyz"));
    // }

    b.installArtifact(exe);
    exe.root_module.addImport("raylib", raylib.module("raylib"));
    exe.root_module.addImport("tracy", tracy.module("tracy"));
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
}
