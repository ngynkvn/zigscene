const std = @import("std");
const o = @import("objects.zig");
const c = @cImport({
    @cInclude("raylib.h");
    @cInclude("rlgl.h");
    @cInclude("raymath.h");
    @cInclude("miniaudio.h");
    @cInclude("dr_wav.h");
});

pub fn main() !void {
    var t: f32 = 0.0;
    const screenWidth = 800;
    const screenHeight = 450;

    c.InitWindow(screenWidth, screenHeight, "neo");
    defer c.CloseWindow(); // Close window and OpenGL context

    try initAudio();

    const camera = initCamera();

    c.SetTargetFPS(60); // Set our game to run at 60 frames-per-second

    const cmesh = c.GenMeshCylinder(0.5, 0.7, 16);
    var cmodel = c.LoadModelFromMesh(cmesh);
    cmodel.transform = c.MatrixMultiply(cmodel.transform, c.MatrixRotateX(std.math.pi / 2.0));

    const shader = c.LoadShader(0, "./shaders/checkers.fs");
    const target = c.LoadRenderTexture(screenWidth, screenHeight);

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
        c.BeginTextureMode(target);
        {
            c.ClearBackground(c.WHITE);
            defer c.EndTextureMode();
            c.BeginMode3D(camera);
            {
                defer c.EndMode3D();
                c.rlPushMatrix();
                c.rlRotatef(20, 0, 1, 0);
                c.DrawCube(.{ .x = 0, .y = @sin(t / 2) / 3, .z = 0 }, 5, 4, 4, c.BLUE);
                c.rlPopMatrix();
                c.DrawGrid(10, 4.0);
            }
        }
        // Draw
        c.BeginDrawing();
        {
            defer c.EndDrawing();
            c.ClearBackground(c.RAYWHITE);
            c.BeginShaderMode(shader);
            {
                defer c.EndShaderMode();
                c.DrawTextureRec(
                    target.texture,
                    .{ .x = 0, .y = 0, .width = @floatFromInt(target.texture.width), .height = @floatFromInt(-target.texture.height) },
                    .{},
                    c.WHITE,
                );
            }
            c.BeginMode3D(camera);
            {
                defer c.EndMode3D();
                c.rlPushMatrix();
                c.rlRotatef(20, 0, 1, 0);
                c.DrawCube(.{ .x = 0, .y = @sin(t / 2) / 3, .z = 0 }, 5, 4, 4, c.BLUE);
                c.rlPopMatrix();
                c.DrawGrid(10, 4.0);
            }
        }
        t += 0.05;
    }
}

var context = c.ma_context{};
var device = c.ma_device{};
fn initAudio() !void {
    // Init audio context
    const ctxConfig = c.ma_context_config_init();
    //    c.ma_log_callback_init(OnLog, NULL);

    var result = c.ma_context_init(0, 0, &ctxConfig, &context);
    if (result != c.MA_SUCCESS) {
        return error.NoAudio;
    }

    // Init audio device
    // NOTE: Using the default device. Format is floating point because it simplifies mixing
    var config = c.ma_device_config_init(c.ma_device_type_playback);
    config.playback.pDeviceID = 0; // NULL for the default playback AUDIO.System.device
    config.playback.format = c.ma_format_f32;
    config.playback.channels = 2;
    config.sampleRate = 0;
    config.dataCallback = null;
    config.pUserData = null;

    result = c.ma_device_init(&context, &config, &device);
    errdefer _ = c.ma_context_uninit(&context);
    if (result != c.MA_SUCCESS) {
        return error.NoAudio;
    }

    // Keep the device running the whole time. May want to consider doing something a bit smarter and only have the device running
    // while there's at least one sound being played
    result = c.ma_device_start(&device);
    errdefer _ = c.ma_device_uninit(&device);
    if (result != c.MA_SUCCESS) {
        return error.NoAudio;
    }
    var pwav = c.drwav{};
    const success = c.drwav_init_file(&pwav, "./sounds/sample.wav", 0);
    if (success == 0) {
        std.debug.print("{}\n", .{success});
        return error.FailedInit;
    }
    std.debug.print("{}\n", .{pwav.bytesRemaining});
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
