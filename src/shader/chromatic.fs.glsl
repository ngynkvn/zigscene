// Varying and output declarations come from the platform prelude in shader.zig.
uniform sampler2D texture0;
uniform vec4 colDiffuse;

uniform float chromaFactor;
uniform float noiseFactor;
uniform float backgroundAlpha;
uniform float time;

void main()
{
    vec4 r = texture(texture0, vec2(fragTexCoord.x + chromaFactor, fragTexCoord.y));
    vec4 g = texture(texture0, fragTexCoord);
    vec4 b = texture(texture0, vec2(fragTexCoord.x - chromaFactor, fragTexCoord.y));
    // Each channel samples a shifted copy of the same layer; summing their
    // coverage would make translucent pixels up to three times as opaque.
    float alpha = max(max(r.a, g.a), b.a);
    float grain = fract(sin(dot(fragTexCoord + fract(time), vec2(12.9898, 78.233))) * 43758.5453) * noiseFactor;
    // Grain covers empty areas only as far as the window background does, so
    // it never makes a transparent background more opaque than chosen.
    finalColor = colDiffuse*vec4(vec3(r.r, g.g, b.b) + grain, alpha + grain*backgroundAlpha);
}
