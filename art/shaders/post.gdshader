// ENTITY_000 — full-screen grade: film grain, vignette, reality tearing,
// and the OBSERVE readout grade (cyan scanlines). Driven by FX per frame.
// Cinematic pass: radial chromatic aberration + edge desaturation so the
// corners fall away like an old lens, holding the eye centre-screen.
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float grain_amount = 0.05;
uniform float vignette_strength = 0.45;
uniform float tearing = 0.0;        // 0..1 — horizontal band displacement
uniform float observe_grade = 0.0;  // 0..1 — cyan scanline overlay
uniform float time_seed = 0.0;
uniform float ca_amount = 1.0;      // 1 world · ~0.15 reading surfaces (codex/options) — body text stays clean

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

        // Chromatic aberration: the lens fails at the edges, not the centre.
        vec2 c = uv - 0.5;
        float r2 = dot(c, c);
        vec2 ca_off = c * r2 * 0.012;
        // fade to zero exactly at the frame border — no smear strips
        float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
        ca_off *= smoothstep(0.0, 0.035, edge);
        vec2 uv_r = clamp(uv + ca_off * ca_amount, vec2(0.001), vec2(0.999));
        vec2 uv_b = clamp(uv - ca_off * ca_amount, vec2(0.001), vec2(0.999));
        vec3 col;
        col.r = texture(screen_tex, uv_r).r;
        col.g = texture(screen_tex, uv).g;
        col.b = texture(screen_tex, uv_b).b;

        // OBSERVE grade: cold cyan, desaturated, scanlined.
        if (observe_grade > 0.001) {
                float lum = dot(col, vec3(0.33, 0.33, 0.34));
                vec3 graded = lum * vec3(0.58, 0.82, 0.86) + vec3(0.0, 0.02, 0.03);
                col = mix(col, graded, observe_grade * 0.6);
                float scan = 0.93 + 0.07 * step(0.5, fract(uv.y * 360.0 + time_seed * 3.0));
                col *= mix(1.0, scan, observe_grade);
        }

        // Vignette: smooth + desaturating — the edges are memory, not presence.
        float vig = 1.0 - vignette_strength * clamp(r2 * 2.6, 0.0, 1.0);
        float lum_v = dot(col, vec3(0.33, 0.33, 0.34));
        float edge_k = clamp(r2 * 2.6, 0.0, 1.0) * vignette_strength * 0.55;
        col = mix(col, vec3(lum_v * 0.9), edge_k);
        col *= vig;

        // Grain (animated).
        float g = (hash(uv * vec2(1920.0, 1080.0) + fract(time_seed) * 61.7) - 0.5) * grain_amount;
        col += g;

        COLOR = vec4(col, 1.0);
}
