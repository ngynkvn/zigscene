const std = @import("std");
pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const tracy_enable = b.option(bool, "tracy_enable", "Enable Tracy integration. Supply path to Tracy source") orelse false;
    const tracy_callstack = b.option(
        bool,
        "tracy_callstack",
        "Include callstack information with Tracy data. Does nothing if -Dtracy_enable is not provided",
    ) orelse tracy_enable;
    const tracy_allocation = b.option(
        bool,
        "tracy_allocation",
        "Include allocation information with Tracy data. Does nothing if -Dtracy_enable is not provided",
    ) orelse tracy_enable;

    const tracy_options = b.addOptions();
    tracy_options.step.name = "tracy options";
    tracy_options.addOption(bool, "tracy_enable", tracy_enable);
    tracy_options.addOption(bool, "tracy_allocation", tracy_enable and tracy_allocation);
    tracy_options.addOption(bool, "tracy_callstack", tracy_enable and tracy_callstack);

    const tracy = b.dependency("tracy", .{});
    const tracy_genc = b.addWriteFile("tracy.c",
        \\#define TRACY_ENABLE 1
        \\#include "tracy/TracyC.h"
    );
    const subdir = tracy_genc.addCopyDirectory(tracy.path("public"), ".", .{ .include_extensions = &.{ "h", "hpp" } });
    const tracy_c = b.addTranslateC(.{
        .root_source_file = subdir.path(b, "tracy.c"),
        .target = target,
        .optimize = optimize,
    });
    const libtracy = b.addStaticLibrary(.{
        .name = "tracy",
        .root_source_file = tracy_c.getOutput(),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    libtracy.root_module.addCMacro("TRACY_ENABLE", "1");
    b.installArtifact(libtracy);

    const tracy_c_mod = tracy_c.createModule();
    tracy_c_mod.addAnonymousImport("tracy-c", .{
        .root_source_file = tracy_c.getOutput(),
        .target = target,
        .optimize = optimize,
    });
    tracy_c_mod.linkLibrary(libtracy);

    tracy_c.defineCMacro("TRACY_ENABLE", "1");
    tracy_c_mod.addCMacro("TRACY_ENABLE", "1");
    tracy_c.defineCMacro("TRACY_ALLOCATION", "1");
    tracy_c.defineCMacro("TRACY_CALLSTACK", "1");
    const tracy_mod = b.addModule("tracy", .{
        .root_source_file = b.path("src/tracy.zig"),
        .link_libcpp = true,
        .target = target,
        .optimize = optimize,
    });
    tracy_c_mod.addCSourceFile(.{ .file = tracy.path("public/TracyClient.cpp") });
    tracy_mod.linkLibrary(libtracy);
    tracy_mod.addImport("tracyC", tracy_c_mod);
    tracy_mod.addImport("options", tracy_options.createModule());
}
