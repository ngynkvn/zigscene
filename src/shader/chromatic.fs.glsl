#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

uniform float chromaFactor;
uniform float noiseFactor;

void main()
{
    vec4 r = texture(texture0, vec2(fragTexCoord.x + chromaFactor, fragTexCoord.y));
    vec4 g = texture(texture0, fragTexCoord);
    vec4 b = texture(texture0, vec2(fragTexCoord.x - chromaFactor, fragTexCoord.y));

    float noise = fract(sin(dot(fragTexCoord, vec2(12.9898, 78.233))) * 43758.5453);
    // final color is the color from the texture 
    //    times the tint color (colDiffuse)
    //    times the fragment color (interpolated vertex color)
    vec4 chroma = vec4(r.r, g.g, b.b, + r.a + g.a + b.a) + vec4(noise * noiseFactor);
    finalColor = colDiffuse*chroma;
}
