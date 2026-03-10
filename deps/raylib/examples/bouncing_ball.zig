const std = @import("std");
const rl = @import("raylibz");

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() void {
    // Initialization
    //---------------------------------------------------------
    var screenWidth: i32 = 800;
    var screenHeight: i32 = 450;

    rl.setConfigFlags(.{ .msaa_4x_hint = true, .window_highdpi = true });
    rl.Window.init(screenWidth, screenHeight, "raylib [shapes] example - bouncing ball");

    var ballPosition = rl.Vector2{ .x = @as(f32, @floatFromInt(rl.Window.getScreenWidth())) / 4, .y = @as(f32, @floatFromInt(rl.Window.getScreenHeight())) / 2 };
    var ballSpeed = rl.Vector2{ .x = 5, .y = 5 };
    const ballRadius: f32 = 20;

    var pause = false;
    var framesCounter: c_int = 0;

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //----------------------------------------------------------

    // Main game loop
    while (!rl.Window.shouldClose()) // Detect window close button or ESC key
    {
        std.debug.print("framesCounter: {}\n", .{framesCounter});
        // Update
        //-----------------------------------------------------
        if (rl.isKeyPressed(rl.Key.SPACE)) pause = !pause;

        if (!pause) {
            ballPosition.x += ballSpeed.x;
            ballPosition.y += ballSpeed.y;

            // Check walls collision for bouncing
            screenWidth = rl.Window.getScreenWidth();
            screenHeight = rl.Window.getScreenHeight();
            if ((ballPosition.x >= (@as(f32, @floatFromInt(screenWidth)) - ballRadius)) or (ballPosition.x <= ballRadius)) ballSpeed.x *= -1.0;
            if ((ballPosition.y >= (@as(f32, @floatFromInt(screenHeight)) - ballRadius)) or (ballPosition.y <= ballRadius)) ballSpeed.y *= -1.0;
        } else framesCounter += 1;
        //-----------------------------------------------------

        // Draw
        //-----------------------------------------------------
        rl.beginDrawing();

        rl.clearBackground(rl.RAYWHITE);

        rl.drawCircleV(ballPosition, ballRadius, rl.MAROON);
        rl.drawText("PRESS SPACE to PAUSE BALL MOVEMENT", 10, rl.Window.getScreenHeight() - 25, 20, rl.LIGHTGRAY);

        // On pause, we draw a blinking message
        if (pause and (@mod(@divTrunc(framesCounter, 30), 2)) == 0) rl.drawText("PAUSED", 350, 200, 30, rl.GRAY);

        rl.drawFPS(10, 10);

        rl.endDrawing();
        //-----------------------------------------------------
    }

    // De-Initialization
    //---------------------------------------------------------
    rl.Window.close(); // Close window and OpenGL context
    //----------------------------------------------------------
}
