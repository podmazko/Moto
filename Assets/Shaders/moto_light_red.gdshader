shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform sampler2D light_ramp : filter_nearest;
uniform sampler2D specular_texture : source_color;
uniform sampler2D light_texture : source_color;
uniform sampler2D shadow_texture : source_color;

uniform vec2 light_uv_scale = vec2(1.0);

uniform float normal_smoothness : hint_range(0.0, 1.0) = 0.15;

uniform vec3 light_color = vec3(1.0);     // цвет 1-го источника света
uniform vec3 light_direction = vec3(-0.3, -0.7, -0.4); // направление (нормализуйте!)
uniform vec3 highlight_tone = vec3(1.0);
uniform vec3 light_tone = vec3(0.8);
uniform vec3 shadow_tone = vec3(0.2);

void fragment() {
    vec3 N = normalize(NORMAL);

    // Нормаль сглаживаем к направлению источника
    N = normalize(mix(N, -light_direction, normal_smoothness));

    // Toon Lambert
    float NdotL = clamp(dot(N, -light_direction), 0.0, 1.0);

    // Ramp (1D)
    float ramp_value = texture(light_ramp, vec2(NdotL, 0.0)).r;

    // Локальные текстуры (свет/тень)
    vec3 light_tex  = light_tone  * texture(light_texture,  UV * light_uv_scale).rgb;
    vec3 shadow_tex = shadow_tone * texture(shadow_texture, UV * light_uv_scale).rgb;

    // Смешивание через ramp
    vec3 toon_light = mix(light_tex, shadow_tex, ramp_value);

    // Спекуляр
    vec3 spec = texture(specular_texture, UV * light_uv_scale).rgb * highlight_tone * ramp_value;

    ALBEDO = toon_light * light_color + spec;
}
