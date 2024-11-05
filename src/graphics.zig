const spectrum = @import("graphics/visualizers/spectrum.zig");
const waveform = @import("graphics/visualizers/waveform.zig");
const bubble = @import("graphics/visualizers/bubble.zig");
pub const FFTSpectrum = spectrum.FFTSpectrum;
pub const WaveFormLine = waveform.WaveFormLine;
pub const WaveFormBar = waveform.WaveFormBar;
pub const Bubble = bubble.Bubble;

pub inline fn onWindowResize(width: i32, height: i32) void {
    spectrum.onWindowResize(width, height);
    waveform.onWindowResize(width, height);
}
