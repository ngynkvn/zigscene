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
    raylib_lib.installHeader(raygui.path("src/raygui.h"), "raygui.h");

    b.installArtifact(raylib_lib);

    const raylib_c2z = b.addTranslateC(.{
        .root_source_file = b.path("raylib.gen.c"),
        .target = target,
        .optimize = optimize,
    });
    raylib_c2z.addIncludePath(raylib_c.path("src"));
    raylib_c2z.addIncludePath(raygui.path("src"));

    const raylib_mod = raylib_c2z.addModule("raylibc");
    raylib_mod.linkLibrary(raylib_lib);

    const raylibz_mod = b.addModule("raylibz", .{
        .root_source_file = b.path("src/raylibz.zig"),
        .target = target,
        .optimize = optimize,
    });
    raylibz_mod.addImport("raylibc", raylib_mod);
    raylibz_mod.linkLibrary(raylib_lib);

    const gen_rl_tool_exe = b.addExecutable(.{
        .name = "gen-rl-tool",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tool/gen.rl.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const gen_rl_tool_cmd = b.addRunArtifact(gen_rl_tool_exe);
    gen_rl_tool_cmd.addFileArg(raylib_mod.root_source_file.?);

    const stdout = gen_rl_tool_cmd.captureStdOut();
    const update_src = b.addUpdateSourceFiles();
    update_src.addCopyFileToSource(stdout, "src/gen/raylib.generated.zig");

    const gen_rl_tool_step = b.step("gen:rl-c2zig", "generate the raylib.gen.zig file");
    gen_rl_tool_step.dependOn(&gen_rl_tool_cmd.step);
    gen_rl_tool_step.dependOn(&update_src.step);

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
    const test_gen_exe = b.addTest(.{
        .name = "test-gen",
        .root_module = gen_rl_tool_exe.root_module,
    });
    test_step.dependOn(&b.addRunArtifact(test_exe).step);
    test_step.dependOn(&b.addRunArtifact(test_gen_exe).step);

    const check_step = b.step("check", "check build");
    check_step.dependOn(&raylib_lib.step);
    check_step.dependOn(&raylib_c2z.step);
    check_step.dependOn(&gen_rl_tool_exe.step);
    check_step.dependOn(&example_bouncing_ball.step);
}
