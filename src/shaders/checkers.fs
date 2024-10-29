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
uniform vec2 resolution = vec2(800, 450);

void main()
{
    float total = floor(fragTexCoord.x * float(resolution.x)/32) +
                  floor(fragTexCoord.y * float(resolution.y)/32);
    bool isEven = mod(total, 2.0) == 0.0;
    vec4 col1 = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 col2 = vec4(1.0, 1.0, 1.0, 1.0);
    finalColor = (isEven) ? col1 : col2;
}
