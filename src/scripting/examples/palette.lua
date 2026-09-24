-- A config can be just data. Add callbacks when you want animation.
return {
    name = "Electric palette",
    mode = "overlay",
    config = {
        scene = { wave_lines = false, wave_bars = true, spectrum = true, bubble = false, halo = true },
        shader = { noise_factor = 0, chroma_factor = 0.0015 },
        wave_bars = { amplitude = 75, color1 = { h = 190, s = 0.8, v = 1 }, color2 = { h = 290 } },
        halo = { radius = 170, depth = 130 },
    },
    params = {
        { id = "speed", label = "Hue speed", min = 0, max = 60, default = 12 },
    },
    update = function(ctx)
        scene.set("halo.hue", (190 + ctx.time * scene.param("speed")) % 359)
    end,
}
