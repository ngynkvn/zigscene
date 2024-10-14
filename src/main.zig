const std = @import("std");
const o = @import("objects.zig");
const c = @cImport({
    @cInclude("raylib.h");
    @cInclude("rlgl.h");
    @cInclude("raymath.h");
});

var curr_buffer = std.mem.zeroes([256]f32);
var curr_fft = std.mem.zeroes([256]f32);
fn callback(ptr: ?*anyopaque, n: c_uint) callconv(.C) void {
    if (ptr == null) return;
    const buffer: []f32 = @as([*]f32, @ptrCast(@alignCast(ptr)))[0..n];
    var l: f32 = 0;
    var r: f32 = 0;
    for (0..n / 2 - 1) |fi| {
        l = buffer[fi * 2 + 0];
        r = buffer[fi * 2 + 1];
        curr_buffer[fi] = l;
    }
}

pub fn main() !void {
    var t: f32 = 0.0;
    const screenWidth = 800;
    const screenHeight = 450;

    c.InitWindow(screenWidth, screenHeight, "neo");
    defer c.CloseWindow(); // Close window and OpenGL context

    c.InitAudioDevice();
    defer c.CloseAudioDevice();
    const music = c.LoadMusicStream("sounds/sample.wav");
    std.debug.assert(music.stream.sampleSize == 32);
    c.AttachAudioStreamProcessor(music.stream, callback);
    c.PlayMusicStream(music);

    const camera = initCamera();

    c.SetTargetFPS(60); // Set our game to run at 60 frames-per-second

    const cmesh = c.GenMeshCylinder(0.5, 0.7, 16);
    var cmodel = c.LoadModelFromMesh(cmesh);
    cmodel.transform = c.MatrixMultiply(cmodel.transform, c.MatrixRotateX(std.math.pi / 2.0));

    //const shader = c.LoadShader(0, "./shaders/checkers.fs");
    //const target = c.LoadRenderTexture(screenWidth, screenHeight);

    // const snd = try soundio.create();
    // defer snd.destroy();
    // try snd.connect();
    // snd.flush_events();
    // if (snd.current_backend == .None) {
    //     return error.NoBackend;
    // }
    // const default_output_index = snd.default_output_device_index();
    // if (default_output_index < 0) return error.NoOutputDeviceFound;
    // var device = snd.get_output_device(default_output_index);
    // var outstream = try device.outstream_create();
    // try outstream.open();
    // defer outstream.destroy();

    // Main game loop
    while (!c.WindowShouldClose()) { // Detect window close button or ESC key
        c.UpdateMusicStream(music);
        // c.BeginTextureMode(target);
        // {
        //     c.ClearBackground(c.WHITE);
        //     defer c.EndTextureMode();
        //     c.BeginMode3D(camera);
        //     {
        //         defer c.EndMode3D();
        //         c.rlPushMatrix();
        //         c.rlRotatef(20, 0, 1, 0);
        //         c.DrawCube(.{ .x = 0, .y = @sin(t / 2) / 3, .z = 0 }, 5, 4, 4, c.BLUE);
        //         c.rlPopMatrix();
        //         c.DrawGrid(10, 4.0);
        //     }
        // }

        // Draw
        c.BeginDrawing();
        {
            defer c.EndDrawing();
            c.ClearBackground(c.RAYWHITE);
            // c.BeginShaderMode(shader);
            // {
            //     defer c.EndShaderMode();
            //     c.DrawTextureRec(
            //         target.texture,
            //         .{ .x = 0, .y = 0, .width = @floatFromInt(target.texture.width), .height = @floatFromInt(-target.texture.height) },
            //         .{},
            //         c.WHITE,
            //     );
            // }
            c.BeginMode3D(camera);
            {
                defer c.EndMode3D();
                c.rlPushMatrix();
                c.rlRotatef(20, 0, 1, 0);
                c.DrawCube(.{ .x = 3, .y = @sin(t / 2) / 3, .z = 0 }, 5, 4, 4, c.BLUE);
                c.DrawGrid(10, 4.0);
                c.rlPopMatrix();
                c.DrawSphere(.{ .x = -5 }, 2, c.RED);
            }
        }
        t += 0.05;
    }
}

fn initCamera() c.Camera3D {

    // Define the camera to look into our 3d world
    var cam: c.Camera3D = undefined;
    cam.position = c.Vector3{ .x = 0.0, .y = 3.0, .z = 10.0 }; // Camera position
    cam.target = c.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 }; // Camera looking at point
    cam.up = c.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 }; // Camera up vector (rotation towards target)
    cam.fovy = 45.0; // Camera field-of-view Y
    cam.projection = c.CAMERA_PERSPECTIVE; // Camera projection type
    return cam;
}
