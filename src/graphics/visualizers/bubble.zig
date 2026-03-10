const std = @import("std");
const rl = @import("raylibz");
const controls = @import("../../core/controls.zig");

const processor = @import("../../audio/processor.zig");

comptime {
    @setFloatMode(.optimized);
}

pub const Bubble = struct {
    pub var ring_radius: f32 = 3.25;
    pub var sphere_radius: f32 = 3;
    pub var height_ring: f32 = 0.1;
    pub var effect: f32 = 0.5;
    pub var color_scale: f32 = 45;
    pub var bubble_color_scale: f32 = 40;

    pub var color1 = rl.Vector3{ .x = 195, .y = 0.5, .z = 1 };
    pub var color2 = rl.Vector3{ .x = 117, .y = 1, .z = 1 };
    pub const Settings = std.StaticStringMap(controls.Setting).initComptime(.{
        .{ "ring_radius", controls.Setting{ .scalar = .{ .value = &ring_radius, .range = .{ 0.1, 8 } } } },
        .{ "sphere_radius", controls.Setting{ .scalar = .{ .value = &sphere_radius, .range = .{ 0.1, 4 } } } },
        .{ "effect", controls.Setting{ .scalar = .{ .value = &effect, .range = .{ 0.1, 1 } } } },
        .{ "color_scale", controls.Setting{ .scalar = .{ .value = &color_scale, .range = .{ 0.0, 100 } } } },
        .{ "bubble_scale", controls.Setting{ .scalar = .{ .value = &bubble_color_scale, .range = .{ 0.0, 100 } } } },
        .{ "height_ring", controls.Setting{ .scalar = .{ .value = &height_ring, .range = .{ 0.0, 1 } } } },
        .{ "color1", controls.Setting{ .color = .{ .value = &color1.x } } },
        .{ "color2", controls.Setting{ .color = .{ .value = &color2.x } } },
    });
    // Radii
    pub fn render(camera3d: rl.Camera3D, rot_offset: f32, t: f32) void {
        const r_ring: f32 = ring_radius;
        const r_sphere: f32 = sphere_radius;
        rl.beginMode3D(camera3d);
        defer rl.endMode3D();
        rl.rlRotatef(rot_offset, 0, 1, 0);
        {
            rl.rlPushMatrix();
            rl.rlRotatef(t * 32, 1, 1, 1);
            color1.x += processor.rms_energy * bubble_color_scale;
            rl.drawSphereWires(.{}, r_sphere + processor.rms_energy * effect, 10, 10, rl.Color.hsv.from(color1));
            rl.rlPopMatrix();
        }
        rl.rlPushMatrix();
        rl.rlRotatef(t * 32, 0.1, 0.1, 1);
        const tsteps = std.math.tau / @as(f32, @floatFromInt(processor.curr_buffer.len));
        for (processor.curr_buffer, 0..) |v, i| {
            const r = r_ring +
                (effect * processor.rms_energy) +
                (@abs(v) * effect);

            const angle_rad = @as(f32, @floatFromInt(i)) * tsteps;
            const x = @cos(angle_rad) * r;
            const y = @sin(angle_rad) * r;

            rl.rlPushMatrix();
            rl.rlTranslatef(x, y, 0);
            rl.rlRotatef(90 + (angle_rad * 180 / std.math.pi), 0, 0, 1);

            var col = color2;
            col.x += processor.rms_energy * color_scale + @abs(v) * 30;
            rl.drawCubeWires(.{}, 0.05, height_ring + @abs(v) * effect + processor.rms_energy * 0.2, 0.05, rl.Color.hsv.from(col));
            rl.rlPopMatrix();
        }
        rl.rlPopMatrix();
    }
};
