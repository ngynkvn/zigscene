const bubble = @import("graphics/visualizers/bubble.zig");
pub const Bubble = bubble.Bubble;
const spectrum = @import("graphics/visualizers/spectrum.zig");
pub const FFTSpectrum = spectrum.FFTSpectrum;
const waveform = @import("graphics/visualizers/waveform.zig");
pub const WaveFormLine = waveform.WaveFormLine;
pub const WaveFormBar = waveform.WaveFormBar;

pub inline fn onWindowResize(width: i32, height: i32) void {
    spectrum.onWindowResize(width, height);
    waveform.onWindowResize(width, height);
}
