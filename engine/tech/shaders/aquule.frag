vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 it = Texel(tex, texture_coords);
    vec3 mixed_color = mix(vec3(.5), it.rgb, 1.2);
    return vec4(mixed_color, it.a) * color;
}
