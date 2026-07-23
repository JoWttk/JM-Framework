extern number radius;
extern vec2 center;
extern number aspect;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords)
{
    vec4 pixel = Texel(tex, uv);
    vec2 pos = uv - center;
    pos.x *= aspect;
    number dist = length(pos);
    number t = clamp((radius - dist) / 0.25, 0.0, 1.0);
    return mix(vec4(0.0, 0.0, 0.0, 1.0), pixel, t) * color;
}