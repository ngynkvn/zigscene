-- Custom 3D camera and geometry; the player and settings UI stay available.
return {
    name = "Orbital sculpture",
    mode = "replace",
    config = { shader = { noise_factor = 0, chroma_factor = 0.001 } },
    params = {
        { id = "radius", label = "Ring radius", min = 1, max = 5, default = 3 },
        { id = "speed", label = "Orbit speed", min = 0, max = 1, default = 0.2 },
        { id = "hue", label = "Base hue", min = 0, max = 359, default = 200 },
    },
    draw = function(ctx)
        local time = ctx.time * scene.param("speed")
        local energy, pulse = ctx.audio.energy, ctx.audio.pulse
        local radius, hue = scene.param("radius"), scene.param("hue")
        gfx.camera { position = {math.sin(time * 0.3) * 4, 3, 12}, target = {-1.5, 0, 0}, fov = 45 }
        gfx.sphere(0, 0, 0, 0.7 + energy, gfx.hsv(hue, 0.6, 0.9), true)
        for i = 1, 36 do
            local a = i / 36 * math.pi * 2 + time
            local x, y, z = math.cos(a) * radius, math.sin(a * 3 + time) * (0.4 + energy), math.sin(a) * radius
            local size = 0.15 + pulse * 0.12 + (ctx.audio.spectrum[i * 3] or 0) * 4
            gfx.cube(x, y, z, size, size, size, gfx.hsv(hue + i * 4, 0.7, 1), false)
            gfx.line3d(0, 0, 0, x, y, z, gfx.hsv(hue + i * 4, 0.5, 0.6, 0.4))
        end
    end,
}
