const std = @import("std");

pub fn build(b: *std.Build, target: std.Build.ResolvedTarget) *std.Build.Step.Compile {
    const source = b.dependency("lua_source", .{});
    const module = b.createModule(.{ .target = target, .optimize = .ReleaseSafe, .link_libc = true });
    module.addIncludePath(source.path("src"));
    if (target.result.os.tag == .emscripten) {
        module.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ b.sysroot.?, "cache/sysroot/include" }) });
    }
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
    return b.addLibrary(.{ .name = "scene-lua", .linkage = .static, .root_module = module });
}

pub fn attach(b: *std.Build, module: *std.Build.Module, lib: *std.Build.Step.Compile) void {
    module.addIncludePath(b.path("src/scripting"));
    module.linkLibrary(lib);
}
