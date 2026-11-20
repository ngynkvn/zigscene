const std = @import("std");

pub const Library = struct {
    artifact: *std.Build.Step.Compile,
    bindings: *std.Build.Module,
};

pub fn build(b: *std.Build, target: std.Build.ResolvedTarget, emscripten_include: ?[]const u8) Library {
    const source = b.dependency("lua_source", .{});
    const module = b.createModule(.{ .target = target, .optimize = .safe, .link_libc = true });
    module.addIncludePath(source.path("src"));
    if (emscripten_include) |include| module.addIncludePath(b.graph.cwdRelativePath(include));
    // Lua's protected calls need the same setjmp lowering as emcc on wasm.
    const c_flags: []const []const u8 = if (target.result.os.tag == .emscripten)
        &.{ "-std=c99", "-mllvm", "-enable-emscripten-sjlj" }
    else
        &.{"-std=c99"};
    module.addCSourceFiles(.{
        .root = source.path("src"),
        .files = &.{ "lapi.c", "lcode.c", "lctype.c", "ldebug.c", "ldo.c", "ldump.c", "lfunc.c", "lgc.c", "llex.c", "lmem.c", "lobject.c", "lopcodes.c", "lparser.c", "lstate.c", "lstring.c", "ltable.c", "ltm.c", "lundump.c", "lvm.c", "lzio.c", "lauxlib.c", "lbaselib.c", "lmathlib.c", "lstrlib.c", "ltablib.c", "lutf8lib.c" },
        .flags = c_flags,
    });
    module.addIncludePath(b.path("src/scripting"));
    module.addCSourceFile(.{ .file = b.path("src/scripting/lua_scene.c"), .flags = c_flags });
    const artifact = b.addLibrary(.{ .name = "scene-lua", .linkage = .static, .root_module = module });

    const translate = b.addTranslateC(.{
        .root_source_file = b.path("src/scripting/lua_scene.h"),
        .target = target,
        .optimize = .safe,
        .link_libc = true,
    });
    if (emscripten_include) |include| translate.addIncludePath(b.graph.cwdRelativePath(include));
    const bindings = translate.createModule();
    bindings.linkLibrary(artifact);
    return .{ .artifact = artifact, .bindings = bindings };
}
