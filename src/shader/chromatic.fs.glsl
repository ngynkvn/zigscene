#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

// NOTE: Add here your custom variables
uniform float amount;

void main()
{
    vec4 r = texture(texture0, vec2(fragTexCoord.x + amount, fragTexCoord.y));
    vec4 g = texture(texture0, fragTexCoord);
    vec4 b = texture(texture0, vec2(fragTexCoord.x - amount, fragTexCoord.y));

    float noise = fract(sin(dot(fragTexCoord, vec2(12.9898, 78.233))) * 43758.5453);
    // final color is the color from the texture 
    //    times the tint color (colDiffuse)
    //    times the fragment color (interpolated vertex color)
    vec4 chroma = vec4(r.r, g.g, b.b, 1.0) + vec4(noise * 0.1);
    finalColor = colDiffuse*chroma;
}
