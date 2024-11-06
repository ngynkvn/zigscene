#version 100

// Precision qualifiers required for GLSL ES
precision mediump float;

// Input vertex attributes (from vertex shader)
varying vec2 fragTexCoord;
varying vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// NOTE: Add here your custom variables
uniform float chromaFactor;
uniform float noiseFactor;

// Helper function to generate pseudo-random noise
float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void main()
{
    vec4 r = texture2D(texture0, vec2(fragTexCoord.x + chromaFactor, fragTexCoord.y));
    vec4 g = texture2D(texture0, fragTexCoord);
    vec4 b = texture2D(texture0, vec2(fragTexCoord.x - chromaFactor, fragTexCoord.y));

    float noise = rand(fragTexCoord);
    vec4 chroma = vec4(r.r, g.g, b.b, 1.0) + vec4(noise * noiseFactor);
    gl_FragColor = colDiffuse * chroma;
}
