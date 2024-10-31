const c = @import("tracy-c");
const std = @import("std");
const builtin = @import("builtin");
const options = @import("options");

comptime {
    if (!options.tracy_enable) @compileError("This module should not have been included if -Dtracy_enable was not set.");
}
pub const tracy_allocation = options.tracy_allocation;
pub const tracy_callstack = options.tracy_callstack;
const callstack_depth = 10;

pub inline fn frameMarkNamed(comptime name: [:0]const u8) void {
    c.___tracy_emit_frame_mark(name);
}

pub const struct____tracy_c_zone_context = extern struct {
    id: u32 = 0,
    active: c_int = 0,

    pub inline fn end(self: @This()) void {
        c.___tracy_emit_zone_end(@bitCast(self));
    }

    pub inline fn addText(self: @This(), text: []const u8) void {
        c.___tracy_emit_zone_text(@bitCast(self), text.ptr, text.len);
    }

    pub inline fn setName(self: @This(), name: []const u8) void {
        c.___tracy_emit_zone_name(@bitCast(self), name.ptr, name.len);
    }

    pub inline fn setColor(self: @This(), color: u32) void {
        c.___tracy_emit_zone_color(@bitCast(self), color);
    }

    pub inline fn setValue(self: @This(), value: u64) void {
        c.___tracy_emit_zone_value(@bitCast(self), value);
    }
};
pub const TracyCZoneCtx = struct____tracy_c_zone_context;

pub inline fn ___tracy_emit_zone_end() void {}

pub inline fn traceNamed(comptime src: std.builtin.SourceLocation, comptime name: [*:0]const u8) TracyCZoneCtx {
    if (tracy_callstack) {
        return @bitCast(c.___tracy_emit_zone_begin_callstack(&.{
            .name = name,
            .function = src.fn_name.ptr,
            .file = src.file.ptr,
            .line = src.line,
            .color = 0,
        }, callstack_depth, 1));
    } else {
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
        return @bitCast(c.___tracy_emit_zone_begin(&holder.data, 1));
    }
}
