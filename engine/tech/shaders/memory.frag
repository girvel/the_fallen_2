vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 it = Texel(tex, texture_coords);
    return vec4(mix(it.rgb, vec3(.1, .1, .1), .9), it.a);
    // return vec4(vec3(dot(it.rgb, vec3(0.299, 0.587, 0.114))), it.a);
}
