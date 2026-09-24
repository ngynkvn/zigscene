-- Full 2D scene. Edit/save while running; the app reloads this file automatically.
local angle = 0
local tau = math.pi * 2
return {
    name = "Spectral orbit",
    mode = "replace",
    config = { shader = { noise_factor = 0, chroma_factor = 0.0008 } },
    params = {
        { id = "radius", label = "Orbit radius", min = 60, max = 260, default = 150 },
        { id = "response", label = "Audio response", min = 0, max = 4, default = 1.5 },
        { id = "speed", label = "Rotation speed", min = -1, max = 1, default = 0.08 },
        { id = "hue", label = "Base hue", min = 0, max = 359, default = 190 },
    },
    update = function(ctx)
        angle = (angle + ctx.dt * scene.param("speed")) % tau
    end,
    draw = function(ctx)
        local cx, cy = ctx.width * 0.61, ctx.height * 0.44
        local response = scene.param("response")
        local radius = math.min(scene.param("radius"), ctx.height * 0.28)
        local hue = scene.param("hue")
        local energy = ctx.audio.energy * response
        local pulse = ctx.audio.pulse
        gfx.ring(cx, cy, radius * 0.65, radius * 0.65 + 1 + pulse * 3, gfx.hsv(hue, 0.6, 0.8, 0.4))
        for i = 1, 96 do
            local a = angle + i / 96 * tau
            local bin = 1 + math.floor((i / 96)^2 * (#ctx.audio.spectrum - 1))
            local spectral = ctx.audio.spectrum[bin] or 0
            local r = radius + energy * 30
            local length = 6 + math.min(120, spectral * 500 * response) + pulse * 12
            local x, y = math.cos(a), math.sin(a)
            gfx.line(cx + x * r, cy + y * r, cx + x * (r + length), cy + y * (r + length), 3, gfx.hsv(hue + i * 1.4, 0.65, 1))
        end
        local previous_x, previous_y
        for i = 1, #ctx.audio.samples, 4 do
            local x = cx - radius + (i - 1) / math.max(1, #ctx.audio.samples - 1) * radius * 2
            local y = cy + ctx.audio.samples[i] * radius * 0.5 * response
            if previous_x then gfx.line(previous_x, previous_y, x, y, 2, {0.8, 0.95, 1, 0.8}) end
            previous_x, previous_y = x, y
        end
        gfx.text("S P E C T R A L   O R B I T", cx - 120, cy + radius + 60, 18, {0.5, 0.7, 0.8, 1})
    end,
}
