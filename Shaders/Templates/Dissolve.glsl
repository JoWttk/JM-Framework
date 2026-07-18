extern number progress;
extern vec3 edgeColor;
extern number edgeWidth;

float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 screenCoord)
{
    vec4 pixel = Texel(tex, texCoord);
    if (pixel.a <= 0.0) return vec4(0.0);

    float noise = hash(floor(screenCoord / 2.0));

    if (noise < progress) return vec4(0.0);

    float edge = smoothstep(progress, progress + edgeWidth, noise);
    vec3 finalColor = mix(edgeColor, pixel.rgb, edge);

    return vec4(finalColor, pixel.a) * color;
}