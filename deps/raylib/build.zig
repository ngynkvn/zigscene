const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const raylib = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
    });
    const libraylib = raylib.artifact("raylib");
    b.installArtifact(libraylib);
    libraylib.root_module.addCMacro("SUPPORT_FILEFORMAT_FLAC", "1");
    // SOURCE: https://github.com/Not-Nik/raylib-zig/blob/c191e12e7c50e5dc2b1addd1e5dbd16bd405d2b5/build.zig#L119
    // (Thank you!)
    const raygui = b.dependency("raygui", .{
        .target = target,
        .optimize = optimize,
    });
    const libraygui = b.addStaticLibrary(.{
        .name = "raygui",
        .target = target,
        .optimize = optimize,
    });
    libraygui.addIncludePath(raylib.path("src"));
    libraygui.defineCMacro("RAYGUI_IMPLEMENTATION", "1");
    libraygui.addCSourceFiles(.{
        .root = raygui.path("."),
        .files = &.{"src/raygui.h"},
    });
    b.installArtifact(libraygui);

    var raylib_c = b.addWriteFile("raylib.c",
        \\#include "raylib.h"
        \\#include "raymath.h"
        \\#include "rlgl.h"
        \\#define RAYGUI_IMPLEMENTATION
        \\#include "raygui.h"
        \\#include "style_dark.h"
    );
    _ = raylib_c.addCopyDirectory(raylib.path("src"), ".", .{ .include_extensions = &.{"h"} });
    _ = raylib_c.addCopyFile(raygui.path("src/raygui.h"), "raygui.h");
    _ = raylib_c.addCopyFile(raygui.path("styles/dark/style_dark.h"), "style_dark.h");

    const translate_c = b.addTranslateC(.{
        .root_source_file = raylib_c.getDirectory().path(b, "raylib.c"),
        .target = b.graph.host,
        .optimize = optimize,
        .link_libc = true,
    });
    translate_c.addIncludePath(raygui.path("src"));
    const module = translate_c.addModule("raylib");
    module.linkLibrary(libraylib);
    b.getInstallStep().dependOn(&b.addInstallFile(translate_c.getOutput(), "c.zig").step);

    const check_step = b.step("check", "check build");
    check_step.dependOn(&libraylib.step);
    check_step.dependOn(&translate_c.step);
}
