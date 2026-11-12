shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 sea_tint : source_color = vec4(0.055, 0.76, 0.72, 0.86);
uniform float clock = 0.0;
uniform float wobble = 1.0;
// Each impulse stores surface x,z, time since scene start, and impulse strength.
uniform vec4 hit_a = vec4(100.0, 100.0, -100.0, 0.0);
uniform vec4 hit_b = vec4(100.0, 100.0, -100.0, 0.0);
uniform vec4 hit_c = vec4(100.0, 100.0, -100.0, 0.0);
uniform vec4 hit_d = vec4(100.0, 100.0, -100.0, 0.0);

varying float v_height;
varying vec2 v_position;

float pulse(vec2 p, vec4 hit) {
    float age = clock - hit.z;
    if (age < 0.0 || age > 6.5) { return 0.0; }
    float r = distance(p, hit.xy);
    float front = r - age * 3.3;
    return hit.w * cos(front * 4.2) * exp(-abs(front) * 0.83) * exp(-age * 0.36);
}

float height_at(vec2 p) {
    float h = 0.062 * sin(p.x * 0.85 + clock * 1.05) * cos(p.y * 0.72 - clock * 0.68);
    h += 0.030 * sin((p.x + p.y) * 1.7 - clock * 1.25);
    h += pulse(p, hit_a) + pulse(p, hit_b) + pulse(p, hit_c) + pulse(p, hit_d);
    return wobble * h;
}

void vertex() {
    vec2 p = VERTEX.xz;
    float h = height_at(p);
    VERTEX.y += h;
    float delta = 0.055;
    float slope_x = (height_at(p + vec2(delta, 0.0)) - height_at(p - vec2(delta, 0.0))) / (2.0 * delta);
    float slope_z = (height_at(p + vec2(0.0, delta)) - height_at(p - vec2(0.0, delta))) / (2.0 * delta);
    NORMAL = normalize(vec3(-slope_x, 1.0, -slope_z));
    v_height = h;
    v_position = p;
}

void fragment() {
    float swirl = sin(v_position.x * 2.9 + clock * 0.33) * sin(v_position.y * 3.4 - clock * 0.43);
    float highlight = smoothstep(0.42, 0.98, swirl);
    float turquoise = clamp(v_height * 0.65 + highlight * 0.055, -0.2, 0.2);
    ALBEDO = sea_tint.rgb + vec3(turquoise * 0.29, turquoise * 0.15, turquoise * 0.05);
    ROUGHNESS = 0.17;
    METALLIC = 0.08;
    SPECULAR = 0.91;
    ALPHA = sea_tint.a;
}
