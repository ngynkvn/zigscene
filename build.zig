const std = @import("std");
const emcc = @import("src/build/emcc.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    emcc.hookSysrootIfNeeded(b, target);

    // Dependencies
    const raylib = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
    });
    const libraylib = raylib.artifact("raylib");
    libraylib.root_module.addCMacro("SUPPORT_FILEFORMAT_FLAC", "1");
    libraylib.addIncludePath(raylib.path("src"));

    const cimgui = b.dependency("cimgui", .{});
    const cimgui_lib = cimgui.module("cimgui");

    try emcc.addStepWeb(b, .{
        .lib = libraylib,
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "zigscene",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);
    exe.root_module.addImport("cimgui", cimgui_lib);
    exe.linkLibrary(libraylib);
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
    exe_unit_tests.root_module.addImport("cimgui", cimgui_lib);
    exe_unit_tests.linkLibrary(libraylib);
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    const check_step = b.step("check", "Check build");
    check_step.dependOn(&exe.step);
    check_step.dependOn(test_step);
}
