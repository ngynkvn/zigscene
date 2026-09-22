const std = @import("std");
const builtin = @import("builtin");

const output_dir = "zig-out" ++ std.fs.path.sep_str ++ "web" ++ std.fs.path.sep_str;
const output_file = "index.html";

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
pub fn link(
    b: *std.Build,
    itemsToLink: []const *std.Build.Step.Compile,
) !*std.Build.Step.Run {
    const emccExe = switch (builtin.os.tag) {
        .windows => "emcc.bat",
        else => "emcc",
    };
    const emcc_path = b.pathJoin(&.{ b.sysroot.?, emccExe });

    // Create the output directory because emcc can't do it.
    const mkdir_command = b.addSystemCommand(&[_][]const u8{ "mkdir", "-p", output_dir });

    // Actually link everything together.
    const emcc_command = b.addSystemCommand(&[_][]const u8{emcc_path});

    for (itemsToLink) |item| {
        emcc_command.addFileArg(item.getEmittedBin());
        emcc_command.step.dependOn(&item.step);
    }
    // This puts the deployable bundle in zig-out/web.
    emcc_command.step.dependOn(&mkdir_command.step);
    emcc_command.addArgs(&[_][]const u8{
        "-o",
        output_dir ++ output_file,
        "-sFULL-ES3=1",
        "-sUSE_GLFW=3",
        "-sALLOW_MEMORY_GROWTH=1",
        "-O3",
    });
    return emcc_command;
}

pub fn runStep(b: *std.Build) !*std.Build.Step.Run {
    // If compiling on windows , use emrun.bat.
    const emrunExe = switch (builtin.os.tag) {
        .windows => "emrun.bat",
        else => "emrun",
    };
    const emrun_path = b.pathJoin(&.{ b.sysroot.?, emrunExe });
    const run_cmd = b.addSystemCommand(&[_][]const u8{ emrun_path, output_dir ++ output_file });
    return run_cmd;
}

pub fn hookSysrootIfNeeded(b: *std.Build, target: std.Build.ResolvedTarget) void {
    if (target.result.os.tag != .emscripten) return;

    b.sysroot = b.sysroot orelse r: {
        if (b.graph.environ_map.get("EMSDK")) |p| {
            const path = b.pathJoin(&.{ p, "/upstream/emscripten" });
            break :r path;
        }
        @panic("Pass '--sysroot \"$EMSDK/upstream/emscripten\"' or set $EMSDK");
    };
}
