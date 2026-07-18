uniform vec2 lightPos;
uniform float lightRadius;
uniform float lightSoftness;
uniform float maxDarkness;

vec4 effect(vec4 color, Image texture, vec2 texCoord, vec2 screenCoord)
{
    float dist = distance(screenCoord, lightPos);
    float alpha = smoothstep(lightRadius - lightSoftness, lightRadius, dist);
    alpha = alpha * maxDarkness;
    return vec4(0.02, 0.02, 0.05, alpha);
}