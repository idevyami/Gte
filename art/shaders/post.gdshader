// ENTITY_000 — full-screen grade: film grain, vignette, reality tearing,
// and the OBSERVE readout grade (cyan scanlines). Driven by FX per frame.
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float grain_amount = 0.05;
uniform float vignette_strength = 0.45;
uniform float tearing = 0.0;        // 0..1 — horizontal band displacement
uniform float observe_grade = 0.0;  // 0..1 — cyan scanline overlay
uniform float time_seed = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// Reality tearing: occasional displaced horizontal bands.
	float tick = floor(time_seed * 9.0);
	float row = floor(uv.y * 96.0);
	float band = step(0.93 - tearing * 0.6, hash(vec2(row, tick)));
	float shift = (hash(vec2(row, tick + 7.0)) - 0.5) * tearing * 0.07;
	uv.x += band * shift;

	vec3 col = texture(screen_tex, uv).rgb;

	// OBSERVE grade: cold cyan, desaturated, scanlined.
	if (observe_grade > 0.001) {
		float lum = dot(col, vec3(0.33, 0.33, 0.34));
		vec3 graded = lum * vec3(0.58, 0.82, 0.86) + vec3(0.0, 0.02, 0.03);
		col = mix(col, graded, observe_grade * 0.6);
		float scan = 0.93 + 0.07 * step(0.5, fract(uv.y * 360.0 + time_seed * 3.0));
		col *= mix(1.0, scan, observe_grade);
	}

	// Vignette.
	vec2 c = uv - 0.5;
	float vig = 1.0 - vignette_strength * dot(c, c) * 2.3;
	col *= clamp(vig, 0.0, 1.0);

	// Grain (animated).
	float g = (hash(uv * vec2(1920.0, 1080.0) + fract(time_seed) * 61.7) - 0.5) * grain_amount;
	col += g;

	COLOR = vec4(col, 1.0);
}
