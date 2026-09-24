//! Rasterize the static track once; playback only changes the two tinted slices.
const std = @import("std");
const rl = @import("raylib");
const Preview = @import("../audio/WaveformPreview.zig");
const ui = @import("theme.zig");
const WaveformCache = @This();

pub const colors = [_]rl.Color{
    .{ .r = 244, .g = 107, .b = 112, .a = 255 },
    .{ .r = 105, .g = 220, .b = 150, .a = 255 },
    .{ .r = 100, .g = 174, .b = 255, .a = 255 },
};

texture: ?rl.RenderTexture2D = null,
revision: u64 = 0,

pub fn deinit(self: *WaveformCache) void {
    if (self.texture) |texture| rl.UnloadRenderTexture(texture);
    self.* = .{};
}

pub fn draw(self: *WaveformCache, preview: *const Preview, bounds: rl.Rectangle, played: f32) void {
    if (preview.len == 0) return;
    const scale = rl.GetWindowScaleDPI();
    const pixel_width: i32 = @intFromFloat(@max(1, @round(bounds.width * @max(1, scale.x))));
    const pixel_height: i32 = @intFromFloat(@max(1, @round(bounds.height * @max(1, scale.y))));
    if (self.texture == null or self.texture.?.texture.width != pixel_width or self.texture.?.texture.height != pixel_height) {
        self.deinit();
        const texture = rl.LoadRenderTexture(pixel_width, pixel_height);
        if (!rl.IsRenderTextureValid(texture)) {
            rl.UnloadRenderTexture(texture);
            return;
        }
        self.texture = texture;
        self.rasterize(preview);
    } else if (self.revision != preview.revision) self.rasterize(preview);

    const texture = self.texture.?.texture;
    const w: f32 = @floatFromInt(texture.width);
    const h: f32 = @floatFromInt(texture.height);
    const split = std.math.clamp(played, 0, 1);
    // Keep alpha opaque even in a transparent window. Dimming RGB instead of
    // alpha avoids exposing the desktop beneath the unplayed section.
    if (split > 0) rl.DrawTexturePro(texture, ui.rect(0, 0, w * split, -h), ui.rect(bounds.x, bounds.y, bounds.width * split, bounds.height), .{}, 0, rl.WHITE);
    if (split < 1) rl.DrawTexturePro(texture, ui.rect(w * split, 0, w * (1 - split), -h), ui.rect(bounds.x + bounds.width * split, bounds.y, bounds.width * (1 - split), bounds.height), .{}, 0, .{ .r = 166, .g = 166, .b = 166, .a = 255 });
}

fn rasterize(self: *WaveformCache, preview: *const Preview) void {
    const texture = self.texture.?;
    const columns: usize = @intCast(texture.texture.width);
    const height: f32 = @floatFromInt(texture.texture.height);
    const center = height / 2;
    const amplitude = height * 0.44;
    rl.BeginTextureMode(texture);
    defer rl.EndTextureMode();
    rl.ClearBackground(ui.background);
    for (0..columns) |column| {
        const bin = preview.column(column, columns);
        const x: f32 = @floatFromInt(column);
        const peak_height = @min(1, bin.peak) * amplitude;
        const rms_height = @min(1, bin.rms()) * amplitude;
        var offset: f32 = 0;
        for (bin.bandWeights(), colors) |weight, color| {
            const peak_color = rl.Color{
                .r = @intCast((@as(u16, color.r) + ui.background.r) / 2),
                .g = @intCast((@as(u16, color.g) + ui.background.g) / 2),
                .b = @intCast((@as(u16, color.b) + ui.background.b) / 2),
                .a = 255,
            };
            const band_height = peak_height * weight;
            if (band_height > 0) {
                rl.DrawRectangleRec(ui.rect(x, center - offset - band_height, 1, band_height), peak_color);
                rl.DrawRectangleRec(ui.rect(x, center + offset, 1, band_height), peak_color);
                const body_height = @min(band_height, @max(0, rms_height - offset));
                if (body_height > 0) {
                    rl.DrawRectangleRec(ui.rect(x, center - offset - body_height, 1, body_height), color);
                    rl.DrawRectangleRec(ui.rect(x, center + offset, 1, body_height), color);
                }
            }
            offset += band_height;
        }
    }
    self.revision = preview.revision;
}
