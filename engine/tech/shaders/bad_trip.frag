uniform float sidebar_w;
uniform float degree;  // normalized

float INTENSITY = 15.;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    screen_coords /= vec2(love_ScreenSize.x - sidebar_w, love_ScreenSize.y);
    vec2 d = screen_coords - vec2(.5);

    float scalar_offset = degree * dot(d, d) * INTENSITY;
    vec2 offset = vec2(cos(scalar_offset), sin(scalar_offset));
    texture_coords = mod(texture_coords + offset, 1);

    vec4 it = Texel(tex, texture_coords);
    vec3 mixed_color = mix(vec3(.5), it.rgb, 1 + 3 * degree);
    return vec4(mixed_color, it.a) * color;
}
