//! Built-in scene layers. Each one draws from a `Frame`; `Builtin` owns their
//! state and draw order, so the application does not wire layers individually.
const tracy = @import("tracy");

pub const Frame = @import("graphics/Frame.zig");
pub const Highlight = @import("graphics/Highlight.zig");
pub const Layer = @import("graphics/layer.zig").Layer;
pub const Viewport = @import("graphics/Viewport.zig");

pub const Bubble = @import("graphics/visualizers/bubble.zig").Bubble;
pub const FFTSpectrum = @import("graphics/visualizers/spectrum.zig").FFTSpectrum;
const waveform = @import("graphics/visualizers/waveform.zig");
pub const WaveFormLine = waveform.WaveFormLine;
pub const WaveFormBar = waveform.WaveFormBar;
pub const Halo = @import("graphics/visualizers/halo.zig").Halo;

pub const Builtin = struct {
    halo: Halo = .{},
    wave_bars: WaveFormBar = .{},

    /// Advance time-dependent layer state. Hidden layers keep animating so
    /// showing one does not replay stale history.
    pub fn update(self: *Builtin, frame: Frame) void {
        self.halo.update(frame.dt, frame.spectrum);
        self.wave_bars.advance(frame.dt);
    }

    /// Draw the visible layers back to front. Call inside the scene viewport.
    pub fn render(self: *Builtin, frame: Frame) void {
        if (Layer.halo.visible()) self.halo.render(frame);
        {
            const context = tracy.traceNamed(@src(), "2d");
            defer context.end();
            // The shorter bars stand in front of the spectrum unless it is hovered.
            const spectrum_on_top = frame.focus.selected(.spectrum);
            if (Layer.spectrum.visible() and !spectrum_on_top) FFTSpectrum.render(frame);
            if (Layer.wave_lines.visible()) WaveFormLine.render(frame);
            if (Layer.wave_bars.visible()) self.wave_bars.render(frame);
            if (Layer.spectrum.visible() and spectrum_on_top) FFTSpectrum.render(frame);
        }
        {
            const context = tracy.traceNamed(@src(), "3d");
            defer context.end();
            if (Layer.bubble.visible()) Bubble.render(frame);
        }
    }
};
