## FX — camera shake, hitstop, the time-scale stack (hitstop overrides OBSERVE
## dilation), full-screen post shader (grain / vignette / tearing / observe
## grade), fade transitions, and stage-driven corruption.
extends Node

const POST_SHADER := preload("res://art/shaders/post.gdshader")

var _post_layer: CanvasLayer
var _post_rect: ColorRect
var _post_mat: ShaderMaterial
var _fade_rect: ColorRect
var _fade_layer: CanvasLayer

# shake state
var _shake_amount := 0.0
var _shake_time := 0.0
var _shake_dur := 0.0
var _shake_offset := Vector2.ZERO

# time-scale stack
var _hitstop_until_msec := 0
var _observe_active := false

# post uniforms (lerped)
var _tear_pulse := 0.0
var _observe_grade := 0.0
var _grade_target := 0.0

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        _post_layer = CanvasLayer.new()
        _post_layer.layer = 90
        add_child(_post_layer)
        _post_rect = ColorRect.new()
        _post_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
        _post_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _post_mat = ShaderMaterial.new()
        _post_mat.shader = POST_SHADER
        _post_rect.material = _post_mat
        _post_layer.add_child(_post_rect)
        # Fade sits above post.
        _fade_layer = CanvasLayer.new()
        _fade_layer.layer = 95
        add_child(_fade_layer)
        _fade_rect = ColorRect.new()
        _fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
        _fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _fade_rect.color = Color(0, 0, 0, 0)
        _fade_layer.add_child(_fade_rect)

func _process(delta: float) -> void:
        var stage: int = maxi(1, GameState.stage)
        # --- shake decay
        if _shake_time < _shake_dur:
                _shake_time += delta
                var k := 1.0 - _shake_time / _shake_dur
                _shake_offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_amount * k
        else:
                _shake_offset = Vector2.ZERO
        # --- time scale stack: hitstop > observe > normal
        var msec := Time.get_ticks_msec()
        var scale := 1.0
        if msec < _hitstop_until_msec:
                scale = E0.HITSTOP_SCALE
        elif _observe_active:
                scale = E0.OBSERVE_TIME_SCALE
        if Engine.time_scale != scale:
                Engine.time_scale = scale
        # --- post uniforms
        _tear_pulse = maxf(0.0, _tear_pulse - delta * 1.8)
        var baseline_tear: float = [0.0, 0.02, 0.05, 0.09, 0.16, 0.26][clampi(stage - 1, 0, 5)]
        var grain: float = [0.035, 0.05, 0.065, 0.08, 0.1, 0.13][clampi(stage - 1, 0, 5)]
        _observe_grade = lerpf(_observe_grade, _grade_target, minf(1.0, delta * 6.0))
        _post_mat.set_shader_parameter("grain_amount", grain)
        _post_mat.set_shader_parameter("vignette_strength", 0.42 + 0.05 * stage)
        _post_mat.set_shader_parameter("tearing", baseline_tear + _tear_pulse)
        _post_mat.set_shader_parameter("observe_grade", _observe_grade)
        _post_mat.set_shader_parameter("time_seed", float(msec % 100000) * 0.001)
        _post_rect.queue_redraw()

# ------------------------------------------------------------------ api
func shake(amount: float, duration := 0.25) -> void:
        _shake_amount = maxf(_shake_amount, amount)
        _shake_dur = maxf(_shake_dur, duration)
        _shake_time = 0.0

func get_shake_offset() -> Vector2:
        return _shake_offset

func hitstop(duration := 0.06) -> void:
        _hitstop_until_msec = Time.get_ticks_msec() + int(duration * 1000.0)

func set_observe(active: bool) -> void:
        _observe_active = active
        _grade_target = 1.0 if active else 0.0

func tear_pulse(strength := 1.0) -> void:
        _tear_pulse = minf(1.2, _tear_pulse + strength * 0.35)
        AudioManager.play_sfx("sfx_glitch", -6.0)

func stage_transition_glitch(stage: int) -> void:
        tear_pulse(1.4 + 0.1 * stage)
        shake(4.0 + stage, 0.3 + 0.05 * stage)

func fade_out(duration := 0.4) -> void:
        var tween := create_tween().set_ignore_time_scale()
        tween.tween_property(_fade_rect, "color:a", 1.0, duration)

func fade_in(duration := 0.4) -> void:
        var tween := create_tween().set_ignore_time_scale()
        tween.tween_property(_fade_rect, "color:a", 0.0, duration)

func is_faded() -> bool:
        return _fade_rect.color.a > 0.95

# ------------------------------------------------------------------ bursts
var _burst_world: Node2D = null

func set_burst_world(w: Node2D) -> void:
        _burst_world = w

## One-shot particle burst in world space. Kinds:
##   dust   — soft grey puffs (landings, footsteps, rolls)
##   ash    — blood-ash scatter (hits, deaths)
##   spark  — hot flecks (metal, machine impacts)
##   ember  — rising gold embers
##   glitch — cyan/violet static squares (null children, the censor)
##   gold   — slow golden rise (anchors, fragments, reveals)
func burst(pos: Vector2, kind := "ash", dir := 0.0, count := -1) -> Burst:
        if _burst_world == null or not is_instance_valid(_burst_world):
                return null
        var b := Burst.new()
        b.setup(pos, kind, dir, count)
        _burst_world.add_child(b)
        return b

class Burst:
        extends Node2D
        var parts: Array = []
        var life := 0.0
        var max_life := 1.0
        var kind := "ash"
        var _t := 0.0

        func setup(pos: Vector2, p_kind: String, dir: float, count: int) -> void:
                global_position = pos
                kind = p_kind
                var n := count
                var rng := RandomNumberGenerator.new()
                rng.seed = int(Time.get_ticks_msec()) + randi()
                match kind:
                        "dust":
                                max_life = 0.62
                                if n < 0:
                                        n = 10
                                for i in n:
                                        var spread := randf_range(0.3, 1.0)
                                        var a := dir + randf_range(-1.1, 1.1)
                                        parts.append({
                                                "p": Vector2(randf_range(-6.0, 6.0), randf_range(-3.0, 2.0)),
                                                "v": Vector2(cos(a) * 46.0 * spread, -randf_range(16.0, 52.0) * spread),
                                                "g": Vector2(0.0, 58.0),
                                                "r": randf_range(1.6, 4.2),
                                                "a0": randf_range(0.22, 0.4),
                                                "ph": randf() * TAU,
                                        })
                        "ash":
                                max_life = 0.7
                                if n < 0:
                                        n = 13
                                for i in n:
                                        var a := randf() * TAU
                                        var sp := randf_range(60.0, 170.0)
                                        var blood := rng.randf() < 0.45
                                        parts.append({
                                                "p": Vector2.ZERO,
                                                "v": Vector2(cos(a) * sp, sin(a) * sp * 0.7 - 40.0),
                                                "g": Vector2(0.0, 260.0),
                                                "r": randf_range(1.2, 3.0),
                                                "a0": randf_range(0.5, 0.85),
                                                "blood": blood,
                                        })
                        "spark":
                                max_life = 0.38
                                if n < 0:
                                        n = 9
                                for i in n:
                                        var a := randf() * TAU
                                        var sp := randf_range(180.0, 330.0)
                                        parts.append({
                                                "p": Vector2.ZERO,
                                                "v": Vector2(cos(a) * sp, sin(a) * sp * 0.6 - 60.0),
                                                "g": Vector2(0.0, 420.0),
                                                "r": randf_range(0.9, 1.7),
                                                "a0": randf_range(0.7, 1.0),
                                        })
                                var mat := CanvasItemMaterial.new()
                                mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
                                material = mat
                        "ember":
                                max_life = 1.1
                                if n < 0:
                                        n = 7
                                for i in n:
                                        parts.append({
                                                "p": Vector2(randf_range(-8.0, 8.0), 0.0),
                                                "v": Vector2(randf_range(-14.0, 14.0), -randf_range(30.0, 70.0)),
                                                "g": Vector2(0.0, -8.0),
                                                "r": randf_range(1.0, 2.2),
                                                "a0": randf_range(0.35, 0.7),
                                                "ph": randf() * TAU,
                                        })
                                var mat := CanvasItemMaterial.new()
                                mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
                                material = mat
                        "glitch":
                                max_life = 0.5
                                if n < 0:
                                        n = 11
                                for i in n:
                                        parts.append({
                                                "p": Vector2(randf_range(-20.0, 20.0), randf_range(-34.0, 4.0)),
                                                "v": Vector2(randf_range(-50.0, 50.0), randf_range(-24.0, 24.0)),
                                                "g": Vector2.ZERO,
                                                "r": randf_range(1.5, 3.5),
                                                "a0": randf_range(0.5, 0.9),
                                                "sq": true,
                                                "cyan": rng.randf() < 0.6,
                                                "ph": randf() * TAU,
                                        })
                        "gold":
                                max_life = 1.3
                                if n < 0:
                                        n = 14
                                for i in n:
                                        parts.append({
                                                "p": Vector2(randf_range(-10.0, 10.0), randf_range(-4.0, 4.0)),
                                                "v": Vector2(randf_range(-10.0, 10.0), -randf_range(26.0, 60.0)),
                                                "g": Vector2(0.0, -4.0),
                                                "r": randf_range(1.0, 2.4),
                                                "a0": randf_range(0.4, 0.8),
                                                "ph": randf() * TAU,
                                        })
                                var mat := CanvasItemMaterial.new()
                                mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
                                material = mat
                        _:
                                max_life = 0.5
                z_index = 20

        func _process(delta: float) -> void:
                _t += delta
                if _t >= max_life:
                        queue_free()
                        return
                for m in parts:
                        var v: Vector2 = m["v"]
                        v += (m["g"] as Vector2) * delta
                        m["v"] = v
                        m["p"] = (m["p"] as Vector2) + v * delta
                queue_redraw()

        func _draw() -> void:
                var k := 1.0 - _t / max_life
                var ease := k * k
                match kind:
                        "dust":
                                for m in parts:
                                        var a: float = m["a0"] * ease
                                        var col := Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, a)
                                        var r: float = m["r"] * (1.0 + (1.0 - k) * 1.6)
                                        draw_circle(m["p"], r, col)
                        "ash":
                                for m in parts:
                                        var a: float = m["a0"] * ease
                                        var col := Color(E0.BLOOD.r, E0.BLOOD.g, E0.BLOOD.b, a) if m.get("blood", false) else Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, a * 0.7)
                                        draw_circle(m["p"], float(m["r"]), col)
                        "spark":
                                for m in parts:
                                        var a: float = m["a0"] * ease
                                        var v: Vector2 = m["v"]
                                        draw_line(m["p"], (m["p"] as Vector2) - v.normalized() * 7.0, Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, a), 1.6)
                                        draw_circle(m["p"], 0.9, Color(1.0, 0.95, 0.85, a))
                        "ember":
                                for m in parts:
                                        var flick := 0.55 + 0.45 * sin(_t * 18.0 + float(m["ph"]))
                                        var a: float = m["a0"] * ease * flick
                                        draw_circle(m["p"], float(m["r"]), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, a))
                        "glitch":
                                for m in parts:
                                        var a: float = m["a0"] * (1.0 if fmod(_t * 17.0 + float(m["ph"]), 2.0) < 1.4 else 0.25)
                                        var col := Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, a) if m.get("cyan", true) else Color(E0.VIOLET.r + 0.2, E0.VIOLET.g, E0.VIOLET.b + 0.25, a)
                                        var r: float = m["r"]
                                        draw_rect(Rect2(m["p"] - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), col)
                        "gold":
                                for m in parts:
                                        var flick := 0.6 + 0.4 * sin(_t * 6.0 + float(m["ph"]))
                                        var a: float = m["a0"] * minf(1.0, k * 2.0) * flick
                                        draw_circle(m["p"], float(m["r"]), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, a))
                                        draw_circle(m["p"], float(m["r"]) * 2.4, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, a * 0.25))
