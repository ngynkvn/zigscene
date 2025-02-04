const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
        .linux_display_backend = b.option(enum { X11, Wayland, Both }, "linux_display_backend", "Linux display backend to use") orelse .X11,
    });

    const raylib_lib = raylib_dep.artifact("raylib");
    raylib_lib.root_module.addCMacro("SUPPORT_FILEFORMAT_FLAC", "1");
    b.installArtifact(raylib_lib);

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
    raylib_lib.addCSourceFile(.{
        .file = b.path("raygui.gen.c"),
    });
    raylib_lib.addIncludePath(raylib_dep.path("src"));
    raylib_lib.addIncludePath(raygui.path("src"));
    raylib_lib.addIncludePath(raygui.path("styles/dark"));

    const raylib_ctoz = b.addTranslateC(.{
        .root_source_file = b.path("raylib.gen.c"),
        .target = target,
        .optimize = optimize,
    });
    raylib_ctoz.addIncludePath(raylib_dep.path("src"));
    raylib_ctoz.addIncludePath(raygui.path("src"));

    const raylib_mod = raylib_ctoz.addModule("raylib");
    raylib_mod.linkLibrary(raylib_lib);
    b.addNamedLazyPath("raygui-styles", raygui.path("styles"));

    const check_step = b.step("check", "check build");
    check_step.dependOn(&raylib_lib.step);
    check_step.dependOn(&raylib_ctoz.step);
}
