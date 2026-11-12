shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Original procedural jelly-water material; no textures or external downloads.
uniform vec4 sea_tint : source_color = vec4(0.034, 0.52, 0.55, 0.93);
uniform float clock = 0.0;
uniform float wobble = 1.0;
// Each hit: x, z, time, force. Each finger: x, z, smoothed pressure, unused.
uniform vec4 hit_a = vec4(100.0, 100.0, -100.0, 0.0);
uniform vec4 hit_b = vec4(100.0, 100.0, -100.0, 0.0);
uniform vec4 hit_c = vec4(100.0, 100.0, -100.0, 0.0);
uniform vec4 hit_d = vec4(100.0, 100.0, -100.0, 0.0);
uniform vec4 finger_a = vec4(100.0, 100.0, 0.0, 0.0);
uniform vec4 finger_b = vec4(100.0, 100.0, 0.0, 0.0);

varying float v_height;
varying vec2 v_position;

float contact_dimple(vec2 p, vec4 finger) {
    if (finger.z < 0.001) { return 0.0; }
    float r = distance(p, finger.xy);
    float core = exp(-0.5 * pow(r / 1.32, 2.0));
    float shoulder = exp(-0.5 * pow((r - 2.15) / 0.82, 2.0));
    // Broad dimple and slight raised shoulder, not a steep vortex.
    return finger.z * (-0.24 * core + 0.046 * shoulder);
}

float pulse(vec2 p, vec4 hit) {
    float age = clock - hit.z;
    if (age < 0.0 || age > 5.0) { return 0.0; }
    float r = distance(p, hit.xy);
    float front = r - age * 2.45;
    float band = exp(-0.5 * pow(front / 0.80, 2.0));
    float ring = sin(front * 2.65) * band * exp(-age * 0.74);
    float soft_center = -0.44 * exp(-0.5 * pow(r / 0.96, 2.0)) * exp(-age * 2.2);
    return hit.w * (ring + soft_center);
}

float height_at(vec2 p) {
    float h = 0.030 * sin(p.x * 0.85 + clock * 0.9) * cos(p.y * 0.72 - clock * 0.62);
    h += 0.016 * sin((p.x + p.y) * 1.65 - clock * 0.94);
    h += contact_dimple(p, finger_a) + contact_dimple(p, finger_b);
    h += pulse(p, hit_a) + pulse(p, hit_b) + pulse(p, hit_c) + pulse(p, hit_d);
    return wobble * h;
}

void vertex() {
    vec2 p = VERTEX.xz;
    float h = height_at(p);
    VERTEX.y += h;
    float sample_delta = 0.07;
    float slope_x = (height_at(p + vec2(sample_delta, 0.0)) - height_at(p - vec2(sample_delta, 0.0))) / (2.0 * sample_delta);
    float slope_z = (height_at(p + vec2(0.0, sample_delta)) - height_at(p - vec2(0.0, sample_delta))) / (2.0 * sample_delta);
    NORMAL = normalize(vec3(-slope_x, 1.0, -slope_z));
    v_height = h;
    v_position = p;
}

void fragment() {
    float edge_distance = min(12.0 - abs(v_position.x), 8.75 - abs(v_position.y));
    float edge = 1.0 - smoothstep(0.0, 2.1, edge_distance);
    float undulation = 0.5 + 0.5 * sin(v_position.x * 0.44 + clock * 0.16) * cos(v_position.y * 0.66 - clock * 0.13);
    float detail = sin(v_position.x * 2.18 + clock * 0.39) * sin(v_position.y * 2.40 - clock * 0.27);
    vec3 deep_sea = vec3(0.018, 0.24, 0.34);
    vec3 jade_sea = sea_tint.rgb;
    vec3 body = mix(deep_sea, jade_sea, 0.58 + edge * 0.30 + undulation * 0.075);
    float wave_light = clamp(v_height * 1.3, -0.28, 0.28);
    body += wave_light * vec3(0.09, 0.13, 0.13);
    body += max(detail, 0.0) * vec3(0.005, 0.020, 0.017);
    ALBEDO = body;
    ROUGHNESS = 0.28;
    METALLIC = 0.015;
    SPECULAR = 0.62;
    ALPHA = clamp(sea_tint.a - edge * 0.05, 0.0, 1.0);
}
