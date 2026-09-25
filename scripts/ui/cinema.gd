## Cinema — presentation cards: room titles on entry, the boss title with
## letterbox bars, phase flashes, and the death card. Serif big type with
## hand-letterspacing, thin rules, glitch flicker. Replaces the old
## always-on HUD room label (decluttered in the HUD pass).
class_name Cinema
extends Control

var _kind := ""            # "", "room", "boss", "phase", "death", "record"
var _t := 0.0
var _hold := 2.2
var _big := ""
var _small := ""
var _letterbox := 0.0     # 0..1 animated bar height
var _letterbox_to := 0.0
var _flicker := 0.0
var _done := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = true

func room_card(title: String, act_num: int) -> void:
	# titles look like "V — THE CHAPEL OF THE PALE SAINT"
	var parts := title.split(" \u2014 ")
	var big := title
	var small := "ACT " + String.num(act_num) if act_num > 0 else ""
	if parts.size() >= 2:
		small = "ACT " + String.num(act_num) + " \u00b7 " + parts[0]
		big = " \u2014 ".join(parts.slice(1))
	_show("room", big, small, 2.4)

func boss_card() -> void:
	_show("boss", "THE BOUND MARTYR", "ENTITY_000_001 \u00b7 THE FIRST \u00b7 THE FAILED \u00b7 THE REPURPOSED", 2.8)
	_letterbox_to = 1.0
	AudioManager.play_sfx("sfx_boss_roar", -2.0)
	FX.shake(6.0, 0.6)

func phase_card(n: int) -> void:
	var names := ["", "BOUND", "FERVOR", "UNCHAINED"]
	_show("phase", "PHASE " + ["I", "II", "III"][n - 1] + " \u2014 " + names[n], "", 1.5)

func death_card() -> void:
	_show("death", "VESSEL FAILURE", "ENTITY_000_818 \u00b7 THE RECORD RESTORES WHAT IT LOSES", 2.3)

func record_card(big: String, small: String) -> void:
	_show("record", big, small, 2.2)

func _show(kind: String, big: String, small: String, hold: float) -> void:
	_kind = kind
	_big = big
	_small = small
	_hold = hold
	_t = 0.0
	_done = false
	_flicker = 1.0
	if kind != "boss":
		_letterbox_to = 0.0
	AudioManager.play_sfx("sfx_terminal", -8.0)

func is_showing() -> bool:
	return _kind != "" and not _done

func _process(delta: float) -> void:
	if _kind.is_empty():
		return
	_t += delta
	_flicker = maxf(0.0, _flicker - delta * 3.0)
	if randf() < 0.004:
		_flicker = 0.7
	_letterbox = lerpf(_letterbox, _letterbox_to, minf(1.0, delta * 7.0))
	if _t > _hold + 1.0:
		_kind = ""
		_letterbox_to = 0.0
		_letterbox = 0.0
		_done = true
	queue_redraw()

func _alpha() -> float:
	# in 0.45, hold, out 0.7
	if _t < 0.45:
		return _t / 0.45
	return clampf(1.0 - (_t - _hold) / 0.7, 0.0, 1.0)

func _draw() -> void:
	if _kind.is_empty():
		return
	var vp := get_viewport_rect().size
	var a := _alpha()
	# --- letterbox bars (boss / death)
	if _letterbox > 0.01:
		var bh := 92.0 * _letterbox
		draw_rect(Rect2(0, 0, vp.x, bh), E0.VOID)
		draw_rect(Rect2(0, vp.y - bh, vp.x, bh), E0.VOID)
		draw_rect(Rect2(0, bh, vp.x, 1.0), Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.4))
		draw_rect(Rect2(0, vp.y - bh, vp.x, 1.0), Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.4))
	if a <= 0.01:
		return
	match _kind:
		"room":
			_draw_room(vp, a)
		"boss":
			_draw_boss(vp, a)
		"phase":
			_draw_phase(vp, a)
		"death":
			_draw_center_card(vp, a, E0.CRIMSON, E0.BONE)
		"record":
			_draw_center_card(vp, a, E0.GOLD, E0.PARCH)

func _draw_room(vp: Vector2, a: float) -> void:
	# lower-center: overline label, big serif title, expanding rule
	var cx := vp.x * 0.5
	var y := vp.y - 168.0
	if E0.mono and not _small.is_empty():
		var sw := _spaced_width(E0.mono, _small, 11, 3.0)
		_spaced_text(E0.mono, Vector2(cx - sw * 0.5, y), _small, 11, 3.0, Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, a * 0.9))
	if E0.serif:
		var size := 34
		var tw := _spaced_width(E0.serif, _big, size, 2.5)
		while tw > vp.x - 160.0 and size > 20:
			size -= 2
			tw = _spaced_width(E0.serif, _big, size, 2.5)
		var glitch := _flicker * 4.0
		if glitch > 0.05:
			_spaced_text(E0.serif, Vector2(cx - tw * 0.5 + glitch, y + 26.0), _big, size, 2.5, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, a * 0.25))
		_spaced_text(E0.serif, Vector2(cx - tw * 0.5, y + 26.0), _big, size, 2.5, Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, a))
		# rule grows outward
		var rk := clampf(_t / 0.9, 0.0, 1.0)
		var half := tw * 0.5 * rk
		draw_line(Vector2(cx - half, y + 44.0), Vector2(cx + half, y + 44.0), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, a * 0.55), 1.0)
		draw_circle(Vector2(cx - half, y + 44.0), 1.8, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, a * 0.8))
		draw_circle(Vector2(cx + half, y + 44.0), 1.8, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, a * 0.8))

func _draw_boss(vp: Vector2, a: float) -> void:
	var cx := vp.x * 0.5
	var y := vp.y * 0.42
	if E0.serif:
		var size := 58
		var tw := _spaced_width(E0.serif, _big, size, 6.0)
		while tw > vp.x - 200.0 and size > 34:
			size -= 2
			tw = _spaced_width(E0.serif, _big, size, 6.0)
		var glitch := _flicker * 7.0
		if glitch > 0.05:
			_spaced_text(E0.serif, Vector2(cx - tw * 0.5 + glitch, y), _big, size, 6.0, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, a * 0.4))
			_spaced_text(E0.serif, Vector2(cx - tw * 0.5 - glitch, y + 2.0), _big, size, 6.0, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, a * 0.3))
		_spaced_text(E0.serif, Vector2(cx - tw * 0.5, y), _big, size, 6.0, Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, a))
	if E0.mono and not _small.is_empty():
		var sw := _spaced_width(E0.mono, _small, 12, 2.0)
		_spaced_text(E0.mono, Vector2(cx - sw * 0.5, y + 34.0), _small, 12, 2.0, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, a * 0.85))
	# crossed rule
	draw_line(Vector2(cx - 210.0, y + 52.0), Vector2(cx - 12.0, y + 52.0), Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, a * 0.7), 1.0)
	draw_line(Vector2(cx + 12.0, y + 52.0), Vector2(cx + 210.0, y + 52.0), Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, a * 0.7), 1.0)
	_diamond(Vector2(cx, y + 52.0), 3.2, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, a))

func _draw_phase(vp: Vector2, a: float) -> void:
	var cx := vp.x * 0.5
	var y := vp.y * 0.30
	if E0.mono_bold:
		var size := 26
		var tw := _spaced_width(E0.mono_bold, _big, size, 5.0)
		var col := Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, a)
		if _big.contains("UNCHAINED"):
			col = Color(E0.VIOLET.r + 0.25, E0.VIOLET.g + 0.08, E0.VIOLET.b + 0.35, a)
		_spaced_text(E0.mono_bold, Vector2(cx - tw * 0.5, y), _big, size, 5.0, col)
		draw_line(Vector2(cx - tw * 0.5, y + 12.0), Vector2(cx + tw * 0.5, y + 12.0), Color(col.r, col.g, col.b, a * 0.5), 1.0)

func _draw_center_card(vp: Vector2, a: float, accent: Color, text_col: Color) -> void:
	var cx := vp.x * 0.5
	var y := vp.y * 0.42
	if E0.serif:
		var size := 44
		var tw := _spaced_width(E0.serif, _big, size, 5.0)
		while tw > vp.x - 200.0 and size > 28:
			size -= 2
			tw = _spaced_width(E0.serif, _big, size, 5.0)
		var glitch := _flicker * 5.0
		if glitch > 0.05:
			_spaced_text(E0.serif, Vector2(cx - tw * 0.5 + glitch, y), _big, size, 5.0, Color(accent.r, accent.g, accent.b, a * 0.35))
		_spaced_text(E0.serif, Vector2(cx - tw * 0.5, y), _big, size, 5.0, Color(text_col.r, text_col.g, text_col.b, a))
	if E0.mono and not _small.is_empty():
		var sw := _spaced_width(E0.mono, _small, 12, 2.0)
		_spaced_text(E0.mono, Vector2(cx - sw * 0.5, y + 32.0), _small, 12, 2.0, Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, a * 0.9))

# ------------------------------------------------------------------ helpers
func _spaced_width(font: FontFile, text: String, size: int, space: float) -> float:
	if font == null:
		return 0.0
	var w := 0.0
	for i in text.length():
		w += font.get_string_size(text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + space
	return maxf(0.0, w - space)

func _spaced_text(font: FontFile, pos: Vector2, text: String, size: int, space: float, col: Color) -> void:
	if font == null:
		return
	var x := pos.x
	for i in text.length():
		draw_string(font, Vector2(x, pos.y), text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
		x += font.get_string_size(text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + space

func _diamond(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
	draw_colored_polygon(pts, col)
