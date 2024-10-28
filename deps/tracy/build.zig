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
    tracy_options.addOption(bool, "tracy_allocation", tracy_allocation);
    tracy_options.addOption(bool, "tracy_callstack", tracy_callstack);

    const tracy_defines = [_][]const u8{
        "TRACY_ENABLE",
        "TRACY_ALLOCATION",
        "TRACY_CALLSTACK",
    };
    const tracy = b.dependency("tracy", .{});
    const tracy_c = b.addTranslateC(.{
        .root_source_file = tracy.path("public/tracy/TracyC.h"),
        .target = target,
        .optimize = optimize,
    });
    for (tracy_defines) |macro| tracy_c.defineCMacro(macro, "1");

    const tracy_c_mod = tracy_c.createModule();
    tracy_c_mod.addCSourceFile(.{ .file = tracy.path("public/TracyClient.cpp") });
    for (tracy_defines) |macro| tracy_c_mod.addCMacro(macro, "1");

    const tracy_mod = b.addModule("tracy", .{
        .root_source_file = b.path("src/tracy.zig"),
        .link_libcpp = true,
        .target = target,
        .optimize = optimize,
    });
    tracy_mod.addImport("tracy-c", tracy_c_mod);
    tracy_mod.addImport("options", tracy_options.createModule());

    const tracy_stub = b.addModule("tracy-stub", .{ .root_source_file = b.path("src/tracy-stub.zig") });
    tracy_stub.addImport("options", tracy_options.createModule());
}
