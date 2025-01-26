const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const raylib = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
        .linux_display_backend = b.option(enum { X11, Wayland, Both }, "linux_display_backend", "Linux display backend to use") orelse .X11,
    });
    const libraylib = raylib.artifact("raylib");
    libraylib.step.name = "Compile Raylib";

    b.installArtifact(libraylib);
    libraylib.root_module.addCMacro("SUPPORT_FILEFORMAT_FLAC", "1");
    // SOURCE: https://github.com/Not-Nik/raylib-zig/blob/c191e12e7c50e5dc2b1addd1e5dbd16bd405d2b5/build.zig#L119
    // (Thank you!)
    const raygui = b.dependency("raygui", .{
        .target = target,
        .optimize = optimize,
    });
    // Lest some other poor soul stumble upon here...
    // You CANNOT link and reference static functions apparently.
    // Create a wrapper function instead calling the static function
    // I wasted so much time on this (｡•́︿•̀｡)
    const raygui_c = b.addWriteFiles();
    const cfile = raygui_c.addCopyFile(b.path("raygui.c"), "raygui.c");
    raygui_c.step.name = "Generate raygui implementation";

    libraylib.installHeader(raygui.path("src/raygui.h"), "raygui.h");
    libraylib.addCSourceFile(.{
        .file = cfile,
    });
    libraylib.addIncludePath(raylib.path("src"));
    libraylib.addIncludePath(raygui.path("src"));
    libraylib.addIncludePath(raygui.path("styles/dark"));

    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("raylib.gen.c"),
        .target = target,
        .optimize = optimize,
    });
    translate_c.step.name = "Perform translate-c";
    translate_c.addIncludePath(raylib.path("src"));
    translate_c.addIncludePath(raygui.path("src"));
    translate_c.addIncludePath(raygui.path("styles/dark"));

    const module = translate_c.addModule("raylib");
    module.linkLibrary(libraylib);

    const check_step = b.step("check", "check build");
    check_step.dependOn(&libraylib.step);
    check_step.dependOn(&translate_c.step);
}
