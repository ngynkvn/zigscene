// Varying and output declarations come from the platform prelude in shader.zig.
uniform vec4 flow;          // Viewport aspect, pattern scale, distortion, phase.
uniform vec3 surfaceFinish; // Contour strength, dot coverage, grain.

float grainHash(vec2 pixel)
{
    vec3 p = fract(vec3(pixel.xyx) * vec3(0.1031, 0.11369, 0.13787));
    p += dot(p, p.yzx + 19.19);
    return fract((p.x + p.y) * p.z);
}

void main()
{
    vec2 p = (fragTexCoord - 0.5) * vec2(flow.x, 1.0) / flow.y;
    float phase = flow.w;
    vec2 drift = vec2(
        sin(7.2 * p.y + phase + 0.7 * cos(4.1 * p.x - phase)),
        cos(6.3 * p.x - phase + 0.9 * sin(5.0 * p.y + phase))
    );
    vec2 q = p + (0.17 * flow.z) * drift;
    float field = sin(7.1 * q.x + phase) + 0.85 * cos(7.9 * q.y - phase)
        + 0.50 * sin(5.4 * (q.x + q.y) + 2.0 * phase)
        + 0.28 * cos(10.0 * (q.x - 0.36 * q.y) - phase);

    // Stack fine alternating contours around the boundaries of the ink pools.
    float edge = abs(field);
    float tone = smoothstep(-0.13, 0.13, field);
    float bands = smoothstep(-0.36, 0.36, sin(28.0 * field));
    tone = mix(tone, bands, surfaceFinish.x * (1.0 - smoothstep(0.02, 0.65, edge)));

    if (surfaceFinish.y > 0.0) {
        // Warp the print grid with the same flow, using less displacement in Y
        // so the dots keep recognizable rows through the stretched areas.
        vec2 grid = (p + flow.z * drift * vec2(0.15, 0.043)) * vec2(32.0, 13.0);
        vec2 cell = fract(grid) - 0.5;
        float crowd = smoothstep(-0.75, 0.8, sin(9.0 * q.x + phase) * cos(6.0 * q.y - phase));
        float coverage = smoothstep(0.0, 0.62, surfaceFinish.y - 0.62 * crowd);
        vec2 axes = mix(vec2(0.055, 0.13), vec2(0.34, 0.36), coverage);
        float dotMask = (1.0 - smoothstep(0.78, 1.10, length(cell / axes))) * smoothstep(0.03, 0.45, coverage);
        tone = mix(tone, 1.0 - tone, dotMask);
    }

    vec3 ink = vec3(0.014, 0.010, 0.017);
    vec3 paper = mix(vec3(0.80, 0.87, 0.77), vec3(0.99, 1.0, 0.96), smoothstep(0.0, 0.78, edge));
    vec3 color = mix(ink, paper, tone);
    vec2 pixel = mod(floor(gl_FragCoord.xy) + floor(phase * 60.0), 251.0);
    float grain = (grainHash(pixel) + grainHash(pixel.yx + 17.0) - 1.0) * surfaceFinish.z;
    finalColor = vec4(clamp(color + grain, 0.0, 1.0) * fragColor.rgb, fragColor.a);
}
