const rl = @import("raylib");
const c = @import("settings.zig").c;
fn vec2(v: []const f32) rl.Vector2 {
    return .{ .x = v[0], .y = v[1] };
}
fn vec3(v: []const f32) rl.Vector3 {
    return .{ .x = v[0], .y = v[1], .z = v[2] };
}
fn rect(v: []const f32) rl.Rectangle {
    return .{ .x = v[0], .y = v[1], .width = v[2], .height = v[3] };
}

/// Only validated commands reach raylib; scripts cannot unbalance render state.
pub fn draw(commands: []const c.ZsCommand, default_camera: rl.Camera3D) void {
    var camera = default_camera;
    for (commands) |*command| {
        const v = &command.values;
        const color: rl.Color = .{ .r = command.color[0], .g = command.color[1], .b = command.color[2], .a = command.color[3] };
        switch (command.kind) {
            c.ZS_CLEAR => rl.ClearBackground(color),
            c.ZS_LINE => rl.DrawLineEx(vec2(v), vec2(v[2..]), v[4], color),
            c.ZS_CIRCLE => rl.DrawCircleV(vec2(v), v[2], color),
            c.ZS_RING => rl.DrawRing(vec2(v), v[2], v[3], 0, 360, 64, color),
            c.ZS_RECT => rl.DrawRectangleRec(rect(v), color),
            c.ZS_RECT_LINES => rl.DrawRectangleLinesEx(rect(v), v[4], color),
            c.ZS_TRIANGLE => rl.DrawTriangle(vec2(v), vec2(v[2..]), vec2(v[4..]), color),
            c.ZS_TEXT => rl.DrawText(@ptrCast(&command.text), @intFromFloat(v[0]), @intFromFloat(v[1]), @intFromFloat(v[2]), color),
            c.ZS_CAMERA => camera = .{ .position = vec3(v), .target = vec3(v[3..]), .up = vec3(v[6..]), .fovy = v[9], .projection = rl.CAMERA_PERSPECTIVE },
            c.ZS_LINE3D, c.ZS_SPHERE, c.ZS_CUBE => {
                rl.BeginMode3D(camera);
                switch (command.kind) {
                    c.ZS_LINE3D => rl.DrawLine3D(vec3(v), vec3(v[3..]), color),
                    c.ZS_SPHERE => if (v[10] != 0) rl.DrawSphereWires(vec3(v), v[3], 12, 16, color) else rl.DrawSphereEx(vec3(v), v[3], 12, 16, color),
                    c.ZS_CUBE => if (v[10] != 0) rl.DrawCubeWires(vec3(v), v[3], v[4], v[5], color) else rl.DrawCube(vec3(v), v[3], v[4], v[5], color),
                    else => unreachable,
                }
                rl.EndMode3D();
            },
            else => unreachable,
        }
    }
}
