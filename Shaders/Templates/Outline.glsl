extern vec2 texSize;
extern vec4 outlineColor;

vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 screenCoord)
{
    vec4 pixel = Texel(tex, texCoord);
    if (pixel.a > 0.0) return pixel * color;

    vec2 offset = 1.0 / texSize;
    float alpha = 0.0;
    alpha += Texel(tex, texCoord + vec2(offset.x, 0.0)).a;
    alpha += Texel(tex, texCoord - vec2(offset.x, 0.0)).a;
    alpha += Texel(tex, texCoord + vec2(0.0, offset.y)).a;
    alpha += Texel(tex, texCoord - vec2(0.0, offset.y)).a;

    if (alpha > 0.0) return outlineColor;
    return vec4(0.0);
}