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
