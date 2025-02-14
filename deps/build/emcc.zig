const std = @import("std");
const builtin = @import("builtin");

// TODO:
const emccOutputDir = "zig-out" ++ std.fs.path.sep_str ++ "web" ++ std.fs.path.sep_str;
const emccOutputFile = "index.html";

// Links a set of items together using emscripten.
//
// Will accept objects and static libraries as items to link. As for files to
// include, it is recomended to have a single resources directory and just pass
// the entire directory instead of passing every file individually. The entire
// path given will be the path to read the file within the program. So, if
// "resources/image.png" is passed, your program will use "resources/image.png"
// as the path to load the file.
//
// TODO: Test if shared libraries are accepted, I don't remember if emcc can
//       link a shared library with a project or not.
// TODO: Add a parameter that allows a custom output directory.
pub fn linkWithEmscripten(
    b: *std.Build,
    itemsToLink: []const *std.Build.Step.Compile,
) !*std.Build.Step.Run {
    const emccExe = switch (builtin.os.tag) {
        .windows => "emcc.bat",
        else => "emcc",
    };
    var emcc_run_arg = try b.allocator.alloc(u8, b.sysroot.?.len + emccExe.len + 1);
    defer b.allocator.free(emcc_run_arg);

    if (b.sysroot == null) {
        emcc_run_arg = try std.fmt.bufPrint(emcc_run_arg, "{s}", .{emccExe});
    } else {
        emcc_run_arg = try std.fmt.bufPrint(
            emcc_run_arg,
            "{s}" ++ std.fs.path.sep_str ++ "{s}",
            .{ b.sysroot.?, emccExe },
        );
    }

    // Create the output directory because emcc can't do it.
    const mkdir_command = b.addSystemCommand(&[_][]const u8{ "mkdir", "-p", emccOutputDir });

    // Actually link everything together.
    const emcc_command = b.addSystemCommand(&[_][]const u8{emcc_run_arg});

    for (itemsToLink) |item| {
        emcc_command.addFileArg(item.getEmittedBin());
        emcc_command.step.dependOn(&item.step);
    }
    // This puts the file in zig-out/htmlout/index.html.
    emcc_command.step.dependOn(&mkdir_command.step);
    emcc_command.addArgs(&[_][]const u8{
        "-o",
        emccOutputDir ++ emccOutputFile,
        "-sFULL-ES3=1",
        "-sUSE_GLFW=3",
        "-sASYNCIFY",
        "-sASSERTIONS",
        "-sINITIAL_MEMORY=81264640",
        "-O3",
        "--profiling",
        "--emrun",
    });
    return emcc_command;
}

pub fn emscriptenRunStep(b: *std.Build) !*std.Build.Step.Run {
    // If compiling on windows , use emrun.bat.
    const emrunExe = switch (builtin.os.tag) {
        .windows => "emrun.bat",
        else => "emrun",
    };
    var emrun_run_arg = try b.allocator.alloc(u8, b.sysroot.?.len + emrunExe.len + 1);
    defer b.allocator.free(emrun_run_arg);

    if (b.sysroot == null) {
        emrun_run_arg = try std.fmt.bufPrint(emrun_run_arg, "{s}", .{emrunExe});
    } else {
        emrun_run_arg = try std.fmt.bufPrint(emrun_run_arg, "{s}" ++ std.fs.path.sep_str ++ "{s}", .{ b.sysroot.?, emrunExe });
    }

    const run_cmd = b.addSystemCommand(&[_][]const u8{ emrun_run_arg, emccOutputDir ++ emccOutputFile });
    return run_cmd;
}
pub const Options = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.Mode,
};

pub fn addStepWeb(b: *std.Build, o: Options) !void {
    const run_option = b.step("web", "Build and run for web");
    if (o.target.result.os.tag != .emscripten) return;

    const run_step = try emscriptenRunStep(b);
    run_option.dependOn(&run_step.step);

    const raylib = b.dependency("raylib", .{
        .target = o.target,
        .optimize = o.optimize,
    });
    const libraylib = raylib.artifact("raylib");

    const exe_lib = b.addStaticLibrary(.{
        .name = "zigscene",
        .root_source_file = b.path("src/main.zig"),
        .target = o.target,
        .optimize = o.optimize,
    });

    const cache_include = b.pathResolve(&.{ b.sysroot.?, "cache", "sysroot", "include" });
    exe_lib.addIncludePath(.{ .cwd_relative = cache_include });

    // Note that raylib itself isn't actually added to the exe_lib
    // output file, so it also needs to be linked with emscripten.
    exe_lib.root_module.addImport("raylib", raylib.module("raylib"));

    const link_step = try linkWithEmscripten(b, &[_]*std.Build.Step.Compile{ exe_lib, libraylib });

    run_step.step.dependOn(&link_step.step);
}

pub fn hookSysrootIfNeeded(b: *std.Build, target: std.Build.ResolvedTarget) void {
    if (target.result.os.tag != .emscripten) return;

    b.sysroot = b.sysroot orelse r: {
        if (std.c.getenv("EMSDK")) |sdkpath| {
            const p = sdkpath[0..std.mem.len(sdkpath)];
            const path = b.pathJoin(&.{ p, "/upstream/emscripten" });
            break :r path;
        }
        @panic("Pass '--sysroot \"$EMSDK/upstream/emscripten\"' or set $EMSDK");
    };
}
