extern number flashAmount;

vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 screenCoord)
{
    vec4 pixel = Texel(tex, texCoord);
    vec3 flashed = mix(pixel.rgb, vec3(1.0), flashAmount);
    return vec4(flashed, pixel.a) * color;
}