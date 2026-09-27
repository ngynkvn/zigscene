-- Full 2D scene. Edit/save while running; the app reloads this file automatically.
local angle, level, kick, since_beat = 0, 0, 0, 1
local bars, echoes = {}, {}
local tau = math.pi * 2
return {
    name = "Spectral orbit",
    mode = "replace",
    config = { shader = { noise_factor = 0, chroma_factor = 0.0008 } },
    params = {
        { id = "radius", label = "Orbit radius", min = 60, max = 260, default = 150 },
        { id = "response", label = "Audio response", min = 0, max = 4, default = 1.8 },
        { id = "speed", label = "Rotation speed", min = -1, max = 1, default = 0.18 },
        { id = "hue", label = "Base hue", min = 0, max = 359, default = 190 },
    },
    update = function(ctx)
        local dt = math.min(ctx.dt, 0.1)
        local response = scene.param("response")
        local active = ctx.audio.playing or ctx.audio.capturing
        local target = active and (1 - math.exp(-ctx.audio.rms * response * 5)) or 0
        level = level + (target - level) * (1 - math.exp(-dt / (target > level and 0.03 or 0.22)))
        kick = kick * math.exp(-dt / 0.2)
        since_beat = since_beat + dt
        for i = #echoes, 1, -1 do
            echoes[i].age = echoes[i].age + dt
            if echoes[i].age >= 0.7 then table.remove(echoes, i) end
        end
        if active and ctx.audio.beat and since_beat >= 0.14 and response > 0 then
            kick = math.min(1, response * 0.65)
            if #echoes == 4 then table.remove(echoes, 1) end
            echoes[#echoes + 1] = { age = 0, strength = kick }
            since_beat = 0
        end
        angle = (angle + dt * scene.param("speed") * (1 + level * 3 + kick * 2)) % tau
        for i = 1, 96 do
            -- Spread low frequencies across more spokes; omit the DC bin.
            local bin = 2 + math.floor(((i - 1) / 95)^2 * math.max(0, #ctx.audio.spectrum - 2))
            local spectral = active and (ctx.audio.spectrum[bin] or 0) or 0
            local value = 1 - math.exp(-spectral * response * 55)
            local previous = bars[i] or 0
            bars[i] = previous + (value - previous) * (1 - math.exp(-dt / (value > previous and 0.025 or 0.18)))
        end
    end,
    draw = function(ctx)
        local cx, cy = ctx.width * 0.61, ctx.height * 0.44
        local response = scene.param("response")
        local radius = math.min(scene.param("radius"), ctx.height * 0.22, ctx.width * 0.18)
        local hue = scene.param("hue") + level * 35 + kick * 20
        local r = radius * (1 + level * 0.18 + kick * 0.12)
        gfx.ring(cx, cy, r * 0.65, r * 0.65 + 1 + kick * 4, gfx.hsv(hue, 0.6, 0.9, 0.6))
        for _, echo in ipairs(echoes) do
            local progress = echo.age / 0.7
            local size = radius * (0.7 + progress * 1.2)
            gfx.ring(cx, cy, size, size + 1 + (1 - progress) * 3,
                gfx.hsv(hue + progress * 60, 0.5, 1, (1 - progress)^2 * echo.strength * 0.6))
        end
        for i = 1, 96 do
            local spectral = bars[i] or 0
            local a = angle + i / 96 * tau
            local length = radius * (0.035 + spectral * 0.55 + kick * 0.12)
            local x, y = math.cos(a), math.sin(a)
            gfx.line(cx + x * r, cy + y * r, cx + x * (r + length), cy + y * (r + length),
                2 + spectral * 2, gfx.hsv(hue + i * 1.4 + spectral * 35, 0.65, 0.65 + spectral * 0.35))
        end
        for i = 1, 6 do
            local a = -angle * 1.5 + i / 6 * tau
            local distance = r * (0.8 + 0.08 * math.sin(angle * 2 + i))
            gfx.circle(cx + math.cos(a) * distance, cy + math.sin(a) * distance,
                2 + level * 3 + kick * 3, gfx.hsv(hue + i * 25, 0.5, 1, 0.8))
        end
        local previous_x, previous_y
        for i = 1, #ctx.audio.samples, 4 do
            local x = cx - radius + (i - 1) / math.max(1, #ctx.audio.samples - 1) * radius * 2
            local sample = (ctx.audio.playing or ctx.audio.capturing) and ctx.audio.samples[i] or 0
            local y = cy + math.max(-1, math.min(1, sample * response)) * radius * 0.65
            if previous_x then gfx.line(previous_x, previous_y, x, y, 2, {0.8, 0.95, 1, 0.8}) end
            previous_x, previous_y = x, y
        end
        gfx.text("S P E C T R A L   O R B I T", cx - 120, cy + radius * 1.9 + 20, 18, {0.5, 0.7, 0.8, 1})
    end,
}
