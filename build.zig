const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zigscene",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    // Dependencies
    const raylib = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
    });
    const libraylib = raylib.artifact("raylib");
    libraylib.defineCMacro("SUPPORT_FILEFORMAT_FLAC", null);
    // SOURCE: https://github.com/Not-Nik/raylib-zig/blob/c191e12e7c50e5dc2b1addd1e5dbd16bd405d2b5/build.zig#L119
    // (Thank you!)
    const raygui = b.dependency("raygui", .{
        .target = target,
        .optimize = optimize,
    });

    var gen = b.addWriteFiles();
    libraylib.step.dependOn(&gen.step);

    const raygui_c_path = gen.add("raygui.c",
        \\#define RAYGUI_IMPLEMENTATION
        \\#include "raygui.h"
    );
    libraylib.addCSourceFile(.{
        .file = raygui_c_path,
        .flags = &[_][]const u8{
            "-std=gnu99",
            "-D_GNU_SOURCE",
            "-DGL_SILENCE_DEPRECATION=199309L",
            "-fno-sanitize=undefined", // https://github.com/raysan5/raylib/issues/3674
        },
    });
    libraylib.addIncludePath(raylib.path("src"));
    libraylib.addIncludePath(raygui.path("src"));
    libraylib.addIncludePath(raygui.path("styles/dark"));
    libraylib.installHeader(raygui.path("src/raygui.h"), "raygui.h");
    libraylib.installHeader(raygui.path("styles/dark/style_dark.h"), "style_dark.h");
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
    exe_unit_tests.linkLibrary(libraylib);
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    const check_step = b.step("check", "Check build");
    check_step.dependOn(&exe.step);
    check_step.dependOn(test_step);
}
