shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Deformable four-wall gelatin volume, visually linked to the sea surface.
uniform float clock = 0.0;
uniform float wobble = 1.0;
uniform float edge_shake = 0.0;
uniform vec4 hit_a = vec4(100.0,100.0,-100.0,0.0);
uniform vec4 hit_b = vec4(100.0,100.0,-100.0,0.0);
uniform vec4 hit_c = vec4(100.0,100.0,-100.0,0.0);
uniform vec4 hit_d = vec4(100.0,100.0,-100.0,0.0);
uniform vec4 finger_a = vec4(100.0,100.0,0.0,0.0);
uniform vec4 finger_b = vec4(100.0,100.0,0.0,0.0);
varying float v_layer;
varying vec2 v_pos;
varying float v_curve;
float contact_dimple(vec2 p, vec4 finger) {
    if (finger.z < 0.001) {return 0.0;}
    float r = distance(p, finger.xy);
    float core = exp(-0.5 * pow(r / 1.32, 2.0));
    float shoulder = exp(-0.5 * pow((r - 2.15) / 0.82, 2.0));
    return finger.z * (-0.24 * core + 0.046 * shoulder);
}
float pulse(vec2 p, vec4 hit) {
    float age = clock - hit.z;
    if (age < 0.0 || age > 5.0) {return 0.0;}
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
    h += pulse(p,hit_a) + pulse(p,hit_b) + pulse(p,hit_c) + pulse(p,hit_d);
    return wobble*h;
}
void vertex() {
    vec2 p = VERTEX.xz;
    float t = clamp((VERTEX.y + 0.82) / 1.01, 0.0, 1.0);
    float flexible = t*t*(3.0 - 2.0*t);
    float h = height_at(p);
    VERTEX.y += h * flexible; // Continuous with surface at upper edge.
    float bend = (0.016 * sin(clock*1.6 + p.x*0.57 + p.y*0.45)
                + edge_shake * 0.20 * sin(clock*6.6 + p.x*0.32 - p.y*0.25)) * flexible;
    VERTEX.xz += NORMAL.xz * bend;
    v_layer = t;
    v_pos = p;
    v_curve = abs(bend);
}
void fragment() {
    float t = v_layer;
    float rivulets = sin(v_pos.x*1.25 + clock*0.17 + sin(v_pos.y*0.72)) *
                     cos(v_pos.y*1.08 - clock*0.18);
    float fine = sin(v_pos.x*4.6 + clock*0.31)*cos(v_pos.y*5.0);
    vec3 deep = vec3(0.009, 0.105, 0.142);
    vec3 glowing_edge = vec3(0.052, 0.405, 0.392);
    vec3 col = mix(deep, glowing_edge, pow(t, 0.66));
    col += rivulets * vec3(0.008,0.022,0.019) + fine*vec3(0.003,0.006,0.005);
    float fresnel = pow(1.0-clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.2);
    col = mix(col, vec3(0.12,0.49,0.46), 0.25*fresnel);
    ALBEDO = max(col,vec3(0.0));
    ROUGHNESS = 0.22;
    SPECULAR = 0.63;
    METALLIC = 0.0;
    ALPHA = mix(0.92,0.78,t);
}