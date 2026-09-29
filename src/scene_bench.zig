//! Native rendering probe; leaves preferences and audio devices' selections alone.
const std = @import("std");
const rl = @import("raylib");
const App = @import("App.zig");
const config = @import("core/config.zig");
const gui = @import("gui.zig");
const debug = @import("core/debug.zig");
const processor = @import("audio/processor.zig");

pub fn main() !void {
    @import("editor/State.zig").initDefaults();
    config.Window.fps_limit = 0;
    config.Window.always_on_top = false;
    config.Audio.volume = 0;
    var app = App.create(.{});
    defer app.destroy();
    processor.selectSource(.capture);
    var pcm: [config.Audio.buffer_size * 2]f32 = undefined;
    for (&pcm, 0..) |*value, i| value.* = 0.4 * @sin(@as(f32, @floatFromInt(i / 2)) * 0.09);
    std.debug.print("scene benchmark: {d}x{d}, {s}, synthetic PCM, uncapped\n", .{ rl.GetScreenWidth(), rl.GetScreenHeight(), @tagName(@import("builtin").mode) });
    for ([_]gui.Tab{ .scalar, .none }) |tab| {
        gui.onTabChange(tab);
        // Repeat in reverse order to reduce warmup/order bias.
        for ([_]c_int{ 1, 0, 0, 1 }) |buffers| {
            // Zero uses the actual application backend configuration.
            var batch: rl.rlRenderBatch = if (buffers == 0) .{} else rl.rlLoadRenderBatch(buffers, 8192);
            if (buffers != 0) rl.rlSetRenderBatchActive(&batch);
            defer {
                rl.rlSetRenderBatchActive(null);
                if (buffers != 0) rl.rlUnloadRenderBatch(batch);
            }
            var frames: [600]f64 = undefined;
            var total: debug.Timings = .{};
            for (0..frames.len + 90) |frame| {
                if (rl.WindowShouldClose()) return;
                processor.submitCapture(&pcm);
                app.frame();
                if (frame < 90) continue;
                const t = debug.latest;
                frames[frame - 90] = (t.audio + t.scene + t.ui + t.present) * 1000;
                inline for (std.meta.fields(debug.Timings)) |field| @field(total, field.name) += @field(t, field.name) * 1000 / frames.len;
            }
            std.mem.sort(f64, &frames, {}, std.sort.asc(f64));
            std.debug.print("tab={s} batch={s} mean={d:.2}ms p95={d:.2}ms p99={d:.2}ms update={d:.2} scene={d:.2} ui={d:.2} present={d:.2}\n", .{
                @tagName(tab),                 if (buffers == 0) "native" else "single", total.audio + total.scene + total.ui + total.present,
                frames[frames.len * 95 / 100], frames[frames.len * 99 / 100],            total.audio,
                total.scene,                   total.ui,                                 total.present,
            });
        }
    }
}
