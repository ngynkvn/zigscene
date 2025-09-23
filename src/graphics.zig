const bubble = @import("graphics/visualizers/bubble.zig");
const spectrum = @import("graphics/visualizers/spectrum.zig");
const waveform = @import("graphics/visualizers/waveform.zig");
pub const Bubble = bubble.Bubble;
pub const FFTSpectrum = spectrum.FFTSpectrum;
pub const WaveFormLine = waveform.WaveFormLine;
pub const WaveFormBar = waveform.WaveFormBar;

pub fn onWindowResize(width: i32, height: i32) void {
    spectrum.onWindowResize(width, height);
    waveform.onWindowResize(width, height);
}
