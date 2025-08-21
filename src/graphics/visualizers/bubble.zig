const std = @import("std");
const rl = @import("raylibz");

const processor = @import("../../audio/processor.zig");

comptime {
    @setFloatMode(.optimized);
}

pub const Bubble = struct {
    const Config = @import("../../core/config.zig").Visualizer.Bubble;
    // Radii
    pub fn render(camera3d: rl.Camera3D, rot_offset: f32, t: f32) void {
        var color1 = Config.color1;
        const color2 = Config.color2;
        const r_ring: f32 = Config.ring_radius;
        const r_sphere: f32 = Config.sphere_radius;
        const height_ring: f32 = Config.height_ring;
        const effect: f32 = Config.effect;
        const color_scale: f32 = Config.color_scale;
        const bubble_color_scale: f32 = Config.bubble_color_scale;
        rl.beginMode3D(camera3d);
        defer rl.endMode3D();
        rl.rlRotatef(rot_offset, 0, 1, 0);
        {
            rl.rlPushMatrix();
            rl.rlRotatef(t * 32, 1, 1, 1);
            color1.x += processor.rms_energy * bubble_color_scale;
            rl.drawSphereWires(.{}, r_sphere + processor.rms_energy * effect, 10, 10, rl.Color.hsv.vec3(color1));
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
            rl.drawCubeWires(.{}, 0.05, height_ring + @abs(v) * effect + processor.rms_energy * 0.2, 0.05, rl.Color.hsv.vec3(col));
            rl.rlPopMatrix();
        }
        rl.rlPopMatrix();
    }
};
