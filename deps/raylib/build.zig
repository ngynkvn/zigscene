const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const web = target.result.os.tag == .emscripten;
    const emscripten_include = b.option([]const u8, "emscripten-include", "Path to Emscripten's sysroot headers");
    const linux_display_backend = b.option(enum { X11, Wayland, Both }, "linux_display_backend", "Linux display backend to use") orelse .X11;

    // The upstream web build installs its own SDK. Resolve the source through
    // its desktop configuration so the web library can use our active SDK.
    const raylib = b.dependency("raylib", .{
        .target = if (web) b.resolveTargetQuery(.{}) else target,
        .optimize = if (web) .safe else optimize,
        .linux_display_backend = linux_display_backend,
    });
    const libraylib = if (web)
        buildWebLibrary(b, raylib, target, optimize, emscripten_include orelse return error.MissingEmscriptenHeaders)
    else
        raylib.artifact("raylib");
    libraylib.step.name = "Compile Raylib";
    b.addNamedLazyPath("miniaudio-include", raylib.path("src/external"));

    // The scene, shader and UI scissors flush several times per frame. Rotating
    // upload buffers avoids rewriting a VBO that the GPU is still consuming.
    if (!web) libraylib.root_module.addCMacro("RL_DEFAULT_BATCH_BUFFERS", "12");

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
    var raygui_c = b.addWriteFile("raygui.c",
        \\#define RAYGUI_IMPLEMENTATION
        \\#include "raygui.h"
        \\#include "style_dark.h"
        \\void RayguiDark(void){ GuiLoadStyleDark(); };
    );
    raygui_c.step.name = "Generate raygui implementation";

    libraylib.installHeader(raygui.path("src/raygui.h"), "raygui.h");
    libraylib.root_module.addCSourceFile(.{
        .file = raygui_c.getDirectory().path(b, "raygui.c"),
    });
    libraylib.root_module.addIncludePath(raylib.path("src"));
    libraylib.root_module.addIncludePath(raygui.path("src"));
    libraylib.root_module.addIncludePath(raygui.path("styles/dark"));

    const file = b.addWriteFile("raylib.gen.c",
        \\#include "raylib.h"
        \\#include "raymath.h"
        \\#include "rlgl.h"
        \\#include "raygui.h"
        \\void RayguiDark(void);
    );
    file.step.name = "Generate c file for zig translation";
    const translate_c = b.addTranslateC(.{
        .root_source_file = file.getDirectory().path(b, "raylib.gen.c"),
        .target = target,
        .optimize = optimize,
    });
    translate_c.step.name = "Perform translate-c";
    translate_c.addIncludePath(raylib.path("src"));
    translate_c.addIncludePath(raygui.path("src"));
    translate_c.addIncludePath(raygui.path("styles/dark"));
    if (emscripten_include) |include| translate_c.addIncludePath(b.graph.cwdRelativePath(include));

    const module = translate_c.addModule("raylib");
    module.linkLibrary(libraylib);

    const check_step = b.step("check", "check build");
    check_step.dependOn(&libraylib.step);
    check_step.dependOn(&translate_c.step);
}

fn buildWebLibrary(
    b: *std.Build,
    raylib: *std.Build.Dependency,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
    emscripten_include: []const u8,
) *std.Build.Step.Compile {
    const module = b.createModule(.{ .target = target, .optimize = optimize, .link_libc = true });
    module.addCMacro("PLATFORM_WEB", "");
    module.addCMacro("GRAPHICS_API_OPENGL_ES2", "");
    module.addIncludePath(b.graph.cwdRelativePath(emscripten_include));
    module.addCSourceFiles(.{
        .root = raylib.path("src"),
        .files = &.{ "rcore.c", "rshapes.c", "rtextures.c", "rtext.c", "rmodels.c", "raudio.c" },
        .flags = &.{"-std=gnu99"},
    });
    return b.addLibrary(.{ .name = "raylib", .linkage = .static, .root_module = module });
}
