const std = @import("std");
const o = @import("objects.zig");
const r = @cImport({
    @cInclude("raylib.h");
    @cInclude("rlgl.h");
    @cInclude("raymath.h");
});

pub fn main() void {
    var t: f32 = 0.0;
    const screenWidth = 800;
    const screenHeight = 450;

    r.InitWindow(screenWidth, screenHeight, "neo");
    defer r.CloseWindow(); // Close window and OpenGL context

    const camera = initCamera();

    r.SetTargetFPS(60); // Set our game to run at 60 frames-per-second

    const cmesh = r.GenMeshCylinder(0.5, 0.7, 16);
    var cmodel = r.LoadModelFromMesh(cmesh);
    cmodel.transform = r.MatrixMultiply(cmodel.transform, r.MatrixRotateX(std.math.pi / 2.0));

    const shader = r.LoadShader(0, "./shaders/sobel.fs");
    const target = r.LoadRenderTexture(screenWidth, screenHeight);

    // Main game loop
    while (!r.WindowShouldClose()) { // Detect window close button or ESC key
        r.BeginTextureMode(target);
        {
            r.ClearBackground(r.WHITE);
            defer r.EndTextureMode();
            r.BeginMode3D(camera);
            {
                defer r.EndMode3D();
                r.rlPushMatrix();
                r.rlRotatef(20, 0, 1, 0);
                r.DrawCube(.{ .x = 0, .y = @sin(t / 2) / 3, .z = 0 }, 5, 4, 4, r.BLUE);
                r.rlPopMatrix();
                r.DrawGrid(10, 4.0);
            }
        }
        // Draw
        r.BeginDrawing();
        {
            defer r.EndDrawing();
            r.ClearBackground(r.RAYWHITE);
            r.BeginShaderMode(shader);
            {
                defer r.EndShaderMode();
                r.DrawTextureRec(
                    target.texture,
                    .{ .x = 0, .y = 0, .width = @floatFromInt(target.texture.width), .height = @floatFromInt(-target.texture.height) },
                    .{},
                    r.WHITE,
                );
            }
            r.BeginMode3D(camera);
            {
                defer r.EndMode3D();
                r.rlPushMatrix();
                r.rlRotatef(20, 0, 1, 0);
                r.DrawCube(.{ .x = 0, .y = @sin(t / 2) / 3, .z = 0 }, 5, 4, 4, r.BLUE);
                r.rlPopMatrix();
                r.DrawGrid(10, 4.0);
            }
        }
        t += 0.05;
    }
}

fn initCamera() r.Camera3D {

    // Define the camera to look into our 3d world
    var cam: r.Camera3D = undefined;
    cam.position = r.Vector3{ .x = 0.0, .y = 3.0, .z = 10.0 }; // Camera position
    cam.target = r.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 }; // Camera looking at point
    cam.up = r.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 }; // Camera up vector (rotation towards target)
    cam.fovy = 45.0; // Camera field-of-view Y
    cam.projection = r.CAMERA_PERSPECTIVE; // Camera projection type
    return cam;
}
