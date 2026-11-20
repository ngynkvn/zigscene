const std = @import("std");

const c = @import("tracy-c");
const options = @import("options");
pub const tracy_allocation = options.tracy_allocation;
pub const tracy_callstack = options.tracy_callstack;

comptime {
    if (!options.tracy_enable) @compileError("This module should not have been included if -Dtracy_enable was not set.");
}
const callstack_depth = 10;

pub inline fn frameMarkNamed(comptime name: [:0]const u8) void {
    c.___tracy_emit_frame_mark(name);
}

pub const struct____tracy_c_zone_context = extern struct {
    id: u32 = 0,
    active: c_int = 0,

    fn toC(self: @This()) c.TracyCZoneCtx {
        return .{ .id = self.id, .active = self.active };
    }

    pub inline fn end(self: @This()) void {
        c.___tracy_emit_zone_end(self.toC());
    }

    pub inline fn addText(self: @This(), text: []const u8) void {
        c.___tracy_emit_zone_text(self.toC(), text.ptr, text.len);
    }

    pub inline fn setName(self: @This(), name: []const u8) void {
        c.___tracy_emit_zone_name(self.toC(), name.ptr, name.len);
    }

    pub inline fn setColor(self: @This(), color: u32) void {
        c.___tracy_emit_zone_color(self.toC(), color);
    }

    pub inline fn setValue(self: @This(), value: u64) void {
        c.___tracy_emit_zone_value(self.toC(), value);
    }
};
pub const TracyCZoneCtx = struct____tracy_c_zone_context;

pub inline fn ___tracy_emit_zone_end() void {}

pub inline fn traceNamed(comptime src: std.lang.SourceLocation, comptime name: [*:0]const u8) TracyCZoneCtx {
    const context = if (tracy_callstack) callstack: {
        break :callstack c.___tracy_emit_zone_begin_callstack(&.{
            .name = name,
            .function = src.fn_name.ptr,
            .file = src.file.ptr,
            .line = src.line,
            .color = 0,
        }, callstack_depth, 1);
    } else no_callstack: {
        const holder = struct {
            pub var data: c.___tracy_source_location_data = undefined;
        };
        holder.data = c.___tracy_source_location_data{
            .name = name,
            .function = src.fn_name.ptr,
            .file = src.file.ptr,
            .line = src.line,
            .color = 0,
        };
        break :no_callstack c.___tracy_emit_zone_begin(&holder.data, 1);
    };
    return .{ .id = context.id, .active = context.active };
}
