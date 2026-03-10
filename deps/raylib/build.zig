const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raygui = b.dependency("raygui", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib_c = b.dependency("raylibc", .{
        .target = target,
        .optimize = optimize,
        .linux_display_backend = b.option(enum { X11, Wayland, Both }, "linux_display_backend", "Linux display backend to use") orelse .X11,
    });
    const raylib_lib = raylib_c.artifact("raylib");
    raylib_lib.root_module.addCMacro("SUPPORT_FILEFORMAT_FLAC", "1");
    raylib_lib.root_module.addCSourceFile(.{ .file = b.path("raygui.gen.c") });
    raylib_lib.addIncludePath(raylib_c.path("src"));
    raylib_lib.addIncludePath(raygui.path("src"));
    raylib_lib.addIncludePath(raygui.path("."));
    raylib_lib.installHeader(raygui.path("src/raygui.h"), "raygui.h");
    b.installArtifact(raylib_lib);

    const t = b.addTranslateC(.{
        .root_source_file = b.path("raylib.gen.c"),
        .target = target,
        .optimize = optimize,
    });
    t.addIncludePath(raylib_c.path("src"));
    t.addIncludePath(raygui.path("src"));

    const raylib_mod = t.createModule();
    raylib_mod.linkLibrary(raylib_lib);

    const raylibz_mod = b.addModule("raylibz", .{
        .root_source_file = b.path("src/raylibz.zig"),
        .target = target,
        .optimize = optimize,
    });
    raylibz_mod.addImport("raylibc", raylib_mod);

    const example_bouncing_ball = b.addExecutable(.{
        .name = "bouncing_ball",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/bouncing_ball.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    example_bouncing_ball.root_module.addImport("raylibz", raylibz_mod);
    const example_cmd = b.addRunArtifact(example_bouncing_ball);
    const run_example_step = b.step("run", "run the example");
    run_example_step.dependOn(&example_cmd.step);

    const test_step = b.step("test", "test the library");
    const test_exe = b.addTest(.{
        .name = "raylibz",
        .root_module = raylibz_mod,
    });
    test_step.dependOn(&b.addRunArtifact(test_exe).step);

    const check_step = b.step("check", "check build");
    check_step.dependOn(&raylib_lib.step);
    check_step.dependOn(&example_bouncing_ball.step);
}
