-- Beat-driven color and motion for the built-in layers.
local hue, level, kick = 190, 0, 0
return {
    name = "Electric palette",
    mode = "overlay",
    config = {
        scene = { wave_lines = false, wave_bars = true, spectrum = true, bubble = false, halo = true },
        shader = { noise_factor = 0, chroma_factor = 0.0015 },
        wave_bars = { amplitude = 75, color1 = { h = 190, s = 0.8, v = 1 }, color2 = { h = 290 } },
        halo = { radius = 150, depth = 110 },
    },
    params = {
        { id = "speed", label = "Hue speed", min = 0, max = 60, default = 12 },
        { id = "response", label = "Audio response", min = 0, max = 4, default = 1.8 },
    },
    update = function(ctx)
        local dt = math.min(ctx.dt, 0.1)
        local response = scene.param("response")
        local active = ctx.audio.playing or ctx.audio.capturing
        -- Soft compression brings quiet passages forward without clipping loud ones.
        local target = active and (1 - math.exp(-ctx.audio.rms * response * 5)) or 0
        level = level + (target - level) * (1 - math.exp(-dt / (target > level and 0.035 or 0.24)))
        kick = kick * math.exp(-dt / 0.22)
        if active and ctx.audio.beat then kick = math.min(1, response * 0.65) end
        hue = (hue + dt * scene.param("speed") * (1 + level * 2 + kick)) % 359
        scene.set("halo.hue", hue)
        scene.set("halo.radius", 150 + level * 38 + kick * 25)
        scene.set("halo.depth", 110 + level * 65 + kick * 35)
        scene.set("halo.spin", 0.12 + level * 0.3 + kick * 0.2)
        scene.set("wave_bars.amplitude", 65 + level * 25 + kick * 10)
        scene.set("wave_bars.color1.h", hue)
        scene.set("wave_bars.color2.h", (hue + 85 + kick * 25) % 359)
        scene.set("wave_bars.trail_color.h", (hue + 45) % 359)
        scene.set("spectrum.gain", 1.5 + level * 2 + kick)
        scene.set("shader.chroma_factor", 0.0008 + level * 0.001 + kick * 0.0012)
    end,
}
