const std = @import("std");
const mem = std.mem;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();
    var args = std.process.args();
    _ = args.next();
    const src_file = args.next().?;
    std.debug.print("src_file: {s}\n", .{src_file});

    const source = std.fs.cwd().readFileAllocOptions(allocator, src_file, 1024 * 1024, null, .@"8", 0) catch |err| {
        return err;
    };
    const ast = try std.zig.Ast.parse(allocator, source, .zig);
    var fixups = Ast.Render.Fixups{};
    var stdout = std.fs.File.stdout().writer(&.{});

    const root_decls = ast.rootDecls();
    for (root_decls) |n| {
        try visitRootDecl(allocator, ast, n, &fixups);
    }
    try ast.render(allocator, &stdout.interface, fixups);
}

fn visitRootDecl(arena: std.mem.Allocator, ast: Ast, n: Node.Index, fixups: *Ast.Render.Fixups) !void {
    switch (ast.nodeTag(n)) {
        .fn_decl => {
            var buffer: [1]Node.Index = undefined;
            const fdecl = ast.fullFnProto(&buffer, n).?;
            const name = ast.tokenSlice(fdecl.name_token.?);
            if (mem.startsWith(u8, name, "__")) {
                try fixups.omit_nodes.put(arena, n, {});
            }
        },
        .simple_var_decl => {
            const init_expr = omitCompileError(ast, n);
            if (init_expr) |i| {
                // std.debug.print("omitting node: {s}\n", .{ast.getNodeSource(i)});
                try fixups.omit_nodes.put(arena, i, {});
            }
        },
        else => {},
    }
}
const Ast = std.zig.Ast;
const Node = std.zig.Ast.Node;
fn omitCompileError(ast: Ast, decl: Node.Index) ?Node.Index {
    const fdecl: Ast.full.VarDecl = ast.simpleVarDecl(decl);
    const main_token = ast.nodeMainToken(decl);
    const name_token = main_token + 1;
    const name = ast.tokenSlice(name_token);

    if (mem.startsWith(u8, name, "__") or
        mem.startsWith(u8, name, "MAC") or
        mem.startsWith(u8, name, "va_list") or
        mem.startsWith(u8, name, "HUGE") or
        mem.startsWith(u8, name, "NAN"))
    {
        return decl;
    }

    const i = fdecl.ast.init_node.unwrap() orelse return null;
    switch (ast.nodeTag(i)) {
        .builtin_call, .builtin_call_comma, .builtin_call_two, .builtin_call_two_comma => {
            const call_identifier = ast.getNodeSource(i);
            if (mem.startsWith(u8, call_identifier, "@compileError")) {
                return decl;
            } else return null;
        },
        else => {
            std.debug.print("node: {s}\n", .{ast.getNodeSource(i)});
            std.debug.print("tag: {}\n", .{ast.nodeTag(i)});
            return null;
        },
    }
}
