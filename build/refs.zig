const std = @import("std");
const zig = std.zig;
const Node = zig.Ast.Node;

/// Print source code from raymath input
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();
    const sfile = std.io.getStdOut().writer();
    var bufw = std.io.bufferedWriter(sfile);
    var bw = bufw.writer();

    // TODO: input files
    const src = @embedFile("raymath.zig");

    var ast = try zig.Ast.parse(allocator, src, .zig);
    defer ast.deinit(allocator);
    const decls = ast.rootDecls();

    for (ast.rootDecls()) |rd| {
        switch (assessDecl(ast, rd)) {
            .semi => {
                const source = ast.getNodeSource(rd);
                _ = try bw.print(
                    \\{s};
                    \\
                , .{source});
            },
            .nosemi => {
                const source = ast.getNodeSource(rd);
                _ = try bw.print(
                    \\{s}
                    \\
                , .{source});
            },
            .none => {},
        }
    }
    std.debug.print("{}/{} checked", .{ ndecls, decls.len });
    try bufw.flush();
}
var ndecls: usize = 0;

fn assessDecl(ast: zig.Ast, i: Node.Index) enum { semi, nosemi, none } {
    const node = ast.nodes.get(i);
    const src = ast.getNodeSource(i);
    switch (node.tag) {
        .simple_var_decl => {
            ndecls += 1;
            const span = ast.tokenToSpan(node.main_token);
            const s_iden = span.end + 1;
            const ident = std.mem.sliceTo(ast.source[s_iden..], ' ');
            if (std.mem.eql(u8, "__", ident[0..2])) return .none;
            std.debug.print(
                \\======simpleVarDecl================
                \\{s}
                \\
            , .{ident});
            return .semi;
        },
        .fn_proto_multi, .fn_proto_simple => {
            //ndecls += 1;
        },
        .fn_decl => {
            ndecls += 1;
            var p = [1]Node.Index{0};
            const f = ast.fullFnProto(&p, i) orelse return .none;
            const fname = ast.tokenSlice(f.name_token orelse return .none);
            if (std.mem.eql(u8, "__", fname[0..2])) return .none;
            std.debug.print(
                \\=======fullFnProto=========
                \\{}
                \\................
                \\{s}
                \\.......................
                \\=======================
                \\
                \\
            , .{ node.tag, fname });
            return .nosemi;
        },
        else => {
            std.debug.print(
                \\=======!{s}!=========
                \\{s}
                \\=======================
                \\
                \\
            , .{ @tagName(node.tag), src });
        },
    }
    return .none;
}
