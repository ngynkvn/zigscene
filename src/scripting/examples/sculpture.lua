-- Audio-driven geometry; the camera glides steadily while the sculpture dances.
local phase, level, kick = 0, 0, 0
local bands = {}
local tau = math.pi * 2
return {
    name = "Orbital sculpture",
    mode = "replace",
    config = { shader = { noise_factor = 0, chroma_factor = 0.001 } },
    params = {
        { id = "radius", label = "Ring radius", min = 1, max = 5, default = 3 },
        { id = "speed", label = "Orbit speed", min = 0, max = 1, default = 0.35 },
        { id = "hue", label = "Base hue", min = 0, max = 359, default = 200 },
        { id = "response", label = "Audio response", min = 0, max = 4, default = 1.8 },
    },
    update = function(ctx)
        local dt = math.min(ctx.dt, 0.1)
        local response = scene.param("response")
        local active = ctx.audio.playing or ctx.audio.capturing
        local target = active and (1 - math.exp(-ctx.audio.rms * response * 5)) or 0
        level = level + (target - level) * (1 - math.exp(-dt / (target > level and 0.035 or 0.26)))
        kick = kick * math.exp(-dt / 0.24)
        if active and ctx.audio.beat then kick = math.min(1, response * 0.65) end
        phase = (phase + dt * scene.param("speed") * (1 + level * 2.5 + kick)) % tau
        for i = 1, 36 do
            local bin = 2 + math.floor(((i - 1) / 35)^2 * math.max(0, #ctx.audio.spectrum - 2))
            local spectral = active and (ctx.audio.spectrum[bin] or 0) or 0
            local value = 1 - math.exp(-spectral * response * 60)
            local previous = bands[i] or 0
            bands[i] = previous + (value - previous) * (1 - math.exp(-dt / (value > previous and 0.03 or 0.2)))
        end
    end,
    draw = function(ctx)
        local radius = scene.param("radius")
        local hue = scene.param("hue") + level * 30
        local camera_time = ctx.time * scene.param("speed") * 0.3
        gfx.camera { position = {math.sin(camera_time) * 4, 3, 12}, target = {-1.5, 0, 0}, fov = 45 }
        gfx.sphere(0, 0, 0, 0.65 + level * 0.45 + kick * 0.25, gfx.hsv(hue, 0.6, 0.95), true)
        gfx.sphere(0, 0, 0, 1 + level * 0.6 + kick * 0.5, gfx.hsv(hue + 45, 0.5, 0.75, 0.4), true)
        for i = 1, 36 do
            local spectral = bands[i] or 0
            local a = i / 36 * tau + phase
            local orbit = radius * (1 + level * 0.12 + kick * 0.1) + spectral * 0.35
            local x, y, z = math.cos(a) * orbit, math.sin(a * 3 + phase) * (0.3 + level * 0.9 + spectral * 0.5), math.sin(a) * orbit
            local size = 0.12 + spectral * 0.3 + kick * 0.12
            gfx.cube(x, y, z, size, size * (1 + spectral * 2), size, gfx.hsv(hue + i * 4 + spectral * 40, 0.7, 1), false)
            gfx.line3d(0, 0, 0, x, y, z, gfx.hsv(hue + i * 4, 0.5, 0.6 + spectral * 0.4, 0.3 + kick * 0.25))
            if i % 2 == 0 then
                local b = i / 36 * tau - phase * 1.3
                gfx.sphere(math.cos(b) * orbit * 0.7, math.sin(b) * orbit * 0.7, math.sin(b * 2) * (0.4 + level),
                    0.06 + spectral * 0.09 + kick * 0.05, gfx.hsv(hue + 120 + i * 3, 0.5, 1), false)
            end
        end
    end,
}
