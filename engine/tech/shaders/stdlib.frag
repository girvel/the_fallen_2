uniform vec4 palette[%s];

vec4 match(vec4 color) {
    float min_distance = 1;
    vec4 closest_color;
    for (int i = 0; i < %s; i++) {
        vec4 current_color = palette[i];
        float distance = (
            pow(current_color.r - color.r, 2) +
            pow(current_color.g - color.g, 2) +
            pow(current_color.b - color.b, 2)
        );
  
        if (distance < min_distance) {
            min_distance = distance;
            closest_color = current_color;
        }
    }
    return closest_color;
}

