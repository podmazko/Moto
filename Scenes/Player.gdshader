shader_type spatial;
render_mode unshaded, depth_draw_opaque;

// ------------------------
//     UNIFORMS
// ------------------------

uniform sampler2D texture_normal : filter_nearest, repeat_enable;
uniform float normal_depth : hint_range(0.0, 1.0) = 0.3;

// 🎨 Градиент для цвета блика
uniform sampler2D gradient_texture : filter_linear, hint_default_white;

// Направление света (ручное)
uniform vec3 light_direction = vec3(-0.4, -0.6, -0.4);
uniform vec3 light_color = vec3(1.0);

// Сила блика
uniform float specular_strength : hint_range(0.0, 4.0) = 1.5;

// Сила влияния градиента
uniform float gradient_intensity : hint_range(0.0, 2.0) = 1.0;

// ------------------------
//     MAIN FRAGMENT
// ------------------------

void fragment() {
    // Базовый цвет
    vec3 base_color = vec3(0.5);

    // Вектор камеры
    vec3 view_dir = normalize(VIEW);

    // Нормаль из normal map
    vec3 nmap = texture(texture_normal, UV * 2.0).rgb * 2.0 - 1.0;
    vec3 N = normalize(mix(NORMAL, nmap, normal_depth));

    // Направление света
    vec3 L = normalize(-light_direction);

    // Вектор отражения
    vec3 R = reflect(-L, N);

    // Угол отражения
    float angle = clamp(dot(R, view_dir), 0.0, 1.0);

    // 🎨 Получаем цвет из градиента
    // берём 1D текстуру, координата = angle
    vec3 grad_color = texture(gradient_texture, vec2(angle, 0.5)).rgb;

    // Усиление блика
    float glow = pow(angle, 3.0) * specular_strength;

    // Финальный цвет
    vec3 final_color = base_color + grad_color * glow * gradient_intensity * light_color;

    ALBEDO = final_color;

    // Лёгкое свечение цветом градиента
    EMISSION = grad_color * glow * 0.25;
}
