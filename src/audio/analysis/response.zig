//! Distinguish sudden level changes from gradual swells without beat-history warmup.
pub fn isOnset(rms: f32, previous_rms: f32) bool {
    // Relative detection still works at quiet playback volumes. The small floor
    // keeps near-silent input noise from repeatedly opening the attack path.
    return rms > @max(0.0001, previous_rms * 1.35);
}
