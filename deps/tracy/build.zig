const std = @import("std");
pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const enable = b.option(bool, "enable", "Enable Tracy integration. Supply path to Tracy source") orelse false;
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

    const tracy_options = b.addOptions();
    tracy_options.step.name = "tracy options";
    tracy_options.addOption(bool, "enable", enable);
    tracy_options.addOption(bool, "enable_allocation", enable and enable_allocation);
    tracy_options.addOption(bool, "enable_callstack", enable and enable_callstack);

    const tracy = b.dependency("tracy", .{});
    const tracy_c = b.addTranslateC(.{
        .root_source_file = tracy.path("public/tracy/TracyC.h"),
        .target = target,
        .optimize = optimize,
    });
    const tracy_c_mod = tracy_c.createModule();
    if (enable) {
        tracy_c.defineCMacro("TRACY_ENABLE", "1");
        tracy_c_mod.addCMacro("TRACY_ENABLE", "1");
    }
    if (enable_allocation) {
        tracy_c.defineCMacro("TRACY_ALLOCATION", "1");
        tracy_c_mod.addCMacro("TRACY_ALLOCATION", "1");
    }
    if (enable_callstack) {
        tracy_c.defineCMacro("TRACY_CALLSTACK", "1");
        tracy_c_mod.addCMacro("TRACY_CALLSTACK", "1");
    }
    const tracy_mod = b.addModule("tracy", .{
        .root_source_file = b.path("src/tracy.zig"),
        .link_libcpp = true,
        .target = target,
        .optimize = optimize,
    });
    //tracy_c_mod.addCSourceFile(.{ .file = tracy.path("public/TracyClient.cpp") });
    tracy_mod.addImport("tracyC", tracy_c_mod);
    tracy_mod.addImport("options", tracy_options.createModule());
}
