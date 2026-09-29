// ENTITY_000 — rim light for painted characters. The city is dark and the
// actors are dark; a thin bone-warm edge separates their silhouettes from
// the mid-tone mush behind them without breaking the tonalist palette.
// Edge detection: any opaque pixel whose neighbour (at rim_width texels)
// is transparent catches the light. MODULATE is preserved so hurt-flash
// shimmer, death fade and iframe blink all keep working.
shader_type canvas_item;
render_mode unshaded;

uniform vec4 rim_color : source_color = vec4(0.812, 0.784, 0.722, 1.0); // E0.BONE
uniform float rim_strength : hint_range(0.0, 1.0) = 0.45;
uniform float rim_width : hint_range(1.0, 6.0) = 2.5;

void fragment() {
        vec4 tex = texture(TEXTURE, UV);
        vec2 px = TEXTURE_PIXEL_SIZE * rim_width;
        float a_right = texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
        float a_left  = texture(TEXTURE, UV - vec2(px.x, 0.0)).a;
        float a_down  = texture(TEXTURE, UV + vec2(0.0, px.y)).a;
        float a_up    = texture(TEXTURE, UV - vec2(0.0, px.y)).a;
        float diag    = texture(TEXTURE, UV + px).a;
        float near_a  = max(max(a_right, a_left), max(max(a_down, a_up), diag));
        // rim only where the pixel itself carries paint
        float rim = (1.0 - clamp(near_a * 1.35, 0.0, 1.0)) * step(0.32, tex.a);
        vec3 col = tex.rgb + rim_color.rgb * rim * rim_strength;
        COLOR = vec4(col, tex.a) * MODULATE;
}
