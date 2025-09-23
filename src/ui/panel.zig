const std = @import("std");
const rl = @import("raylibz");
const deque = @import("../deque.zig");
const Deque = deque.Deque;

pub const PADDING: f32 = 8;

pub const LayZ = struct {
    pub const NodeType = union(enum) {
        group: void,
        panel: struct {
            title: []const u8,
        },
        slider: struct {
            value: *f32,
        },
        label: struct {
            text: []const u8,
            // bounds: rl.Rectangle,
        },
    };
    pub const Direction = enum {
        horizontal,
        vertical,
    };
    pub const Node = struct {
        parent: ?usize = null,
        tag: NodeType = .{ .group = undefined },
        direction: Direction = .horizontal,
        gap: f32 = 8,
        layout: Layout = .{},
        bounds: rl.Rectangle = .{ .x = 0, .y = 0, .width = 0, .height = 0 },
    };
    const LayoutOption = union(enum) {
        fit: void,
        fill: void,
        fixed: f32,
    };
    pub const Layout = struct {
        x: f32 = 0,
        y: f32 = 0,
        width: LayoutOption = .fit,
        height: LayoutOption = .fit,
    };
    const NodeList = std.ArrayList(Node);
    nodes: NodeList,
    state: struct {
        current: ?usize,
        render_buffer: [1024]Node,
        rendered: NodeList,
    },
    pub fn init(buffer: []Node) LayZ {
        var self: LayZ = .{
            .nodes = NodeList.initBuffer(buffer),
            .state = .{
                .current = null,
                .render_buffer = [_]Node{undefined} ** 1024,
                .rendered = undefined,
            },
        };
        self.state.rendered = NodeList.initBuffer(&self.state.render_buffer);
        return self;
    }
    pub fn beginLayout(self: *LayZ) void {
        self.state.current = null;
        self.state.rendered.shrinkRetainingCapacity(0);
        self.nodes.shrinkRetainingCapacity(0);
    }
    pub fn endLayout(self: *LayZ) []Node {
        var stack_buffer = [_]?usize{null} ** 128;
        var stack = Deque(?usize).initBuffer(&stack_buffer);
        stack.pushBackBounded(null) catch unreachable;
        while (stack.popFront()) |parent| {
            var roots = self.nodeIterator();
            while (roots.nextWhereParent(parent)) |r| {
                const root, const ri = r;
                self.state.rendered.appendBounded(root) catch unreachable;
                var left_offset: f32 = 0;
                var top_offset: f32 = 0;
                var children = self.nodeIterator();
                while (children.nextWhereParent(ri)) |c| {
                    var child, const ci = c;
                    child.bounds.x += root.bounds.x + left_offset;
                    child.bounds.y += root.bounds.y + top_offset;
                    switch (root.direction) {
                        .horizontal => {
                            left_offset += child.bounds.width;
                        },
                        .vertical => {
                            top_offset += child.bounds.height;
                        },
                    }
                    self.nodes.items[ci] = child;
                }
                stack.pushBackBounded(ri) catch unreachable;
            }
        }
        return self.state.rendered.items;
    }
    pub fn startElement(self: *LayZ, node: Node) void {
        self.nodes.appendBounded(.{
            .parent = self.state.current,
            .tag = node.tag,
            .direction = node.direction,
            .bounds = node.bounds,
        }) catch unreachable;
        self.state.current = self.nodes.items.len - 1;
    }
    pub fn endElement(self: *LayZ) void {
        const i = self.state.current orelse return;
        const child: *Node = &self.nodes.items[i];

        self.state.current = self.nodes.items[i].parent;
        const parent: *Node = &self.nodes.items[child.parent orelse return];

        switch (parent.direction) {
            .horizontal => {
                parent.bounds.height = @max(parent.bounds.height, child.bounds.height + child.bounds.y);
            },
            .vertical => {
                parent.bounds.width = @max(parent.bounds.width, child.bounds.width + child.bounds.x);
            },
        }
    }

    pub fn nodeIterator(self: *LayZ) NodeIterator {
        return NodeIterator{ .context = self, .index = 0 };
    }
    const NodeIterator = struct {
        context: *LayZ,
        index: usize,
        pub fn nextWhereParent(self: *NodeIterator, parent_idx: ?usize) ?struct { Node, usize } {
            while (self.next()) |node| {
                if (node.parent == parent_idx) return .{ node, self.index - 1 };
            }
            return null;
        }
        pub fn next(self: *NodeIterator) ?Node {
            if (self.index >= self.context.nodes.items.len) return null;
            const node = self.context.nodes.items[self.index];
            self.index += 1;
            return node;
        }
    };
};

const tunable_fmt = "{d:6.2}";
const vlen = std.fmt.count(tunable_fmt, .{0}) + 5;
var txt = [_]u8{0} ** 256;
var value_buffer = [_]u8{0} ** vlen;
var editing_buffer = [_]u8{0} ** vlen;
