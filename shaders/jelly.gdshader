shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Mobile-friendly procedural translucent gelatin sea.
// Contacts and ring impulses are sampled identically by boats in harbor.gd.
uniform vec4 sea_tint : source_color = vec4(0.030, 0.34, 0.42, 0.97);
uniform float clock = 0.0;
uniform float wobble = 1.0;
uniform vec4 hit_a = vec4(100.0, 100.0, -100.0, 0.0);
uniform vec4 hit_b = vec4(100.0, 100.0, -100.0, 0.0);
uniform vec4 hit_c = vec4(100.0, 100.0, -100.0, 0.0);
uniform vec4 hit_d = vec4(100.0, 100.0, -100.0, 0.0);
uniform vec4 finger_a = vec4(100.0, 100.0, 0.0, 0.0);
uniform vec4 finger_b = vec4(100.0, 100.0, 0.0, 0.0);

varying float v_height;
varying float v_crest;
varying vec2 v_position;

float contact_dimple(vec2 p, vec4 finger) {
    if (finger.z < 0.001) { return 0.0; }
    float r = distance(p, finger.xy);
    float core = exp(-0.5 * pow(r / 1.32, 2.0));
    float shoulder = exp(-0.5 * pow((r - 2.15) / 0.82, 2.0));
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
    float step_size = 0.08;
    float slope_x = (height_at(p + vec2(step_size, 0.0)) - height_at(p - vec2(step_size, 0.0))) / (2.0 * step_size);
    float slope_z = (height_at(p + vec2(0.0, step_size)) - height_at(p - vec2(0.0, step_size))) / (2.0 * step_size);
    NORMAL = normalize(vec3(-slope_x, 1.0, -slope_z));
    v_crest = length(vec2(slope_x, slope_z));
    v_height = h;
    v_position = p;
}
void fragment() {
    // Deep water toward the town, translucent jade in the foreground and at edges.
    vec2 p = v_position;
    float edge_distance = min(12.0 - abs(p.x), 8.75 - abs(p.y));
    float edge = 1.0 - smoothstep(0.1, 2.9, edge_distance);
    float depth = smoothstep(-8.0, 8.75, p.y);
    float marbling = sin(p.x * 0.58 + sin(p.y * 0.48 + clock * 0.12)) * cos(p.y * 0.63 - clock * 0.16);
    float softer = sin(p.x * 1.17 - p.y * 0.54 + clock * 0.25) * sin(p.y * 1.26 + clock * 0.09);
    float tiny = sin(p.x * 5.3 + clock * 0.43) * cos(p.y * 5.1 - clock * 0.29);
    vec3 ink_blue = vec3(0.010, 0.115, 0.195);
    vec3 sea_jade = vec3(0.030, 0.315, 0.365);
    float blend_amount = clamp(0.42 + depth * 0.25 + edge * 0.26 + marbling * 0.085, 0.0, 1.0);
    vec3 body = mix(ink_blue, sea_jade, blend_amount);
    body += vec3(0.001, 0.012, 0.013) * softer + vec3(0.000, 0.005, 0.006) * tiny;
    body += clamp(v_height, -0.24, 0.24) * vec3(0.12, 0.16, 0.16);
    float crest = smoothstep(0.06, 0.26, v_crest);
    body += crest * vec3(0.020, 0.065, 0.068);
    // Soft sky reflection, strongest at grazing angles; avoid blinding white highlights.
    float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
    body = mix(body, vec3(0.22, 0.45, 0.49), fresnel * 0.23);
    ALBEDO = clamp(body, vec3(0.0), vec3(1.0));
    ROUGHNESS = 0.19 + 0.05 * (1.0 - crest);
    METALLIC = 0.0;
    SPECULAR = 0.55;
    ALPHA = clamp(sea_tint.a - edge * 0.10, 0.0, 1.0);
}