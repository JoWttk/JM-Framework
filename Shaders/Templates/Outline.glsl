extern vec2 texSize;
extern vec4 quadBounds;
extern vec4 outlineColor;

vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 screenCoord)
{
    // Check if current texCoord is within the quad bounds
    if (texCoord.x < quadBounds.x || texCoord.x > quadBounds.z ||
        texCoord.y < quadBounds.y || texCoord.y > quadBounds.w) {
        return vec4(0.0);
    }

    vec4 pixel = Texel(tex, texCoord);
    if (pixel.a > 0.0) return pixel * color;

    vec2 offset = 1.0 / texSize;
    float alpha = 0.0;
    
    // Only sample neighbors that are also within quad bounds
    vec2 rightCoord = texCoord + vec2(offset.x, 0.0);
    vec2 leftCoord = texCoord - vec2(offset.x, 0.0);
    vec2 upCoord = texCoord + vec2(0.0, offset.y);
    vec2 downCoord = texCoord - vec2(0.0, offset.y);
    
    if (rightCoord.x <= quadBounds.z) alpha += Texel(tex, rightCoord).a;
    if (leftCoord.x >= quadBounds.x) alpha += Texel(tex, leftCoord).a;
    if (upCoord.y <= quadBounds.w) alpha += Texel(tex, upCoord).a;
    if (downCoord.y >= quadBounds.y) alpha += Texel(tex, downCoord).a;

    if (alpha > 0.0) return outlineColor;
    return vec4(0.0);
}
