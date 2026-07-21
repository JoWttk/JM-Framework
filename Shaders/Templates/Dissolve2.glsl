uniform float progress;   // 0 = fully solid, 1 = fully gone
uniform vec3 edgeColor;   // glow color eating through the sprite

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 screenCoord) {
    vec4 texColor = Texel(tex, texCoord);
    if (texColor.a < 0.01) {
        discard;
    }

    float n = noise(texCoord * 18.0) * 0.75 + noise(texCoord * 42.0) * 0.25;

    if (n < progress) {
        discard;
    }

    float edge = smoothstep(progress, progress + 0.09, n);
    vec3 finalColor = mix(edgeColor, texColor.rgb, edge);

    return vec4(finalColor, texColor.a) * color;
}