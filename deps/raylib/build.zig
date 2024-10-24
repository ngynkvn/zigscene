const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const raylib = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
    });
    const libraylib = raylib.artifact("raylib");
    libraylib.root_module.addCMacro("SUPPORT_FILEFORMAT_FLAC", "1");
    // SOURCE: https://github.com/Not-Nik/raylib-zig/blob/c191e12e7c50e5dc2b1addd1e5dbd16bd405d2b5/build.zig#L119
    // (Thank you!)
    const raygui = b.dependency("raygui", .{
        .target = target,
        .optimize = optimize,
    });

    {
        var gen = b.addWriteFiles();
        libraylib.step.dependOn(&gen.step);

        const raygui_c_path = gen.add("raygui.c",
            \\#define RAYGUI_IMPLEMENTATION
            \\#include "raygui.h"
        );
        libraylib.addCSourceFile(.{ .file = raygui_c_path });
        libraylib.addIncludePath(raylib.path("src"));
        libraylib.addIncludePath(raygui.path("src"));
    }

    {
        var gen = b.addWriteFiles();
        const path = gen.addCopyDirectory(raylib.path("src"), ".", .{ .include_extensions = &.{"h"} });
        _ = gen.addCopyFile(raygui.path("src/raygui.h"), "raygui.h");
        _ = gen.addCopyFile(raygui.path("styles/dark/style_dark.h"), "style_dark.h");

        const raylib_c = gen.add("raylib.c",
            \\#include <stdlib.h> 
            \\#include <memory.h> 
            \\#include "raylib.h"
            \\#include "raygui.h"
            \\#include "raymath.h"
            \\#include "rlgl.h"
            \\#include "style_dark.h"
        );
        const translate_c = b.addTranslateC(.{
            .root_source_file = raylib_c,
            .target = target,
            .optimize = optimize,
        });
        translate_c.addIncludePath(path);
        const entrypoint = translate_c.getOutput();
        const module = b.addModule("raylib", .{
            .root_source_file = entrypoint,
            .target = target,
            .optimize = optimize,
        });
        module.linkLibrary(libraylib);
    }
}
