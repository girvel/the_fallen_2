uniform vec3 tint;
uniform float intensity;
uniform float brightness;
uniform float brightness_inside;
uniform float contrast_factor;
uniform vec3 contrast_midpoint;
uniform Image ignore;
uniform vec2 ignore_size;
uniform vec2 offset;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 it = Texel(tex, texture_coords);

    vec3 mixed_color = it.rgb;
    if (Texel(ignore, (screen_coords + offset) / ignore_size).r != 1) {
        mixed_color = mix(mixed_color, tint, intensity);
        mixed_color = mix(contrast_midpoint, mixed_color, contrast_factor);
        mixed_color *= brightness;
    } else {
        mixed_color *= brightness_inside;
    }
    return vec4(mixed_color, it.a) * color;
}
