## DialogueBox — typewriter dialogue with per-line conditions. Speakers are
## the world itself: clerks, martyrs, withheld things, and the SYSTEM.
class_name DialogueBox
extends Control

var game
var speaker := ""
var lines: Array = []
var line_idx := 0
var chars_shown := 0
var active := false
var key := ""
var _blink := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func set_game(p_game) -> void:
	game = p_game

func open(dialogue_key: String) -> void:
	var conv: Dictionary = game.dialogues.get(dialogue_key, {})
	if conv.is_empty():
		push_warning("DialogueBox: missing conversation " + dialogue_key)
		return
	key = dialogue_key
	speaker = String(conv.get("speaker", "SYSTEM"))
	lines = []
	for line in conv.get("lines", []):
		var cond := String(line.get("cond", ""))
		if EntityData._condition_holds(cond, GameState.stage, GameState.flags, GameState.consistency):
			lines.append(String(line["text"]))
	if lines.is_empty():
		return
	line_idx = 0
	chars_shown = 0
	active = true
	visible = true
	EventBus.dialogue_started.emit(speaker)

func advance() -> bool:
	## F: complete the line, then move on. Returns true when dialogue closed.
	if not active:
		return false
	var full: String = lines[line_idx]
	if chars_shown < full.length():
		chars_shown = full.length()
		return false
	line_idx += 1
	if line_idx >= lines.size():
		close()
		return true
	chars_shown = 0
	return false

func close() -> void:
	active = false
	visible = false
	EventBus.dialogue_finished.emit(key)

func _process(delta: float) -> void:
	if active:
		chars_shown = mini(chars_shown + int(ceil(42.0 * delta)), lines[line_idx].length())
		_blink += delta
		queue_redraw()

func _draw() -> void:
	if not active:
		return
	var vp := get_viewport_rect().size
	var w := minf(860.0, vp.x - 80.0)
	var x := (vp.x - w) * 0.5
	var y := vp.y - 190.0
	var h := 130.0
	# panel
	draw_rect(Rect2(x - 14, y - 14, w + 28, h + 28), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.88))
	draw_rect(Rect2(x - 14, y - 14, w + 28, h + 28), E0.ASH, false, 1.0)
	draw_rect(Rect2(x - 14, y - 14, 3.0, h + 28), _speaker_color())
	# speaker
	if E0.mono_bold:
		draw_string(E0.mono_bold, Vector2(x, y + 4), speaker, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, _speaker_color())
	# wrapped text
	var text: String = lines[line_idx].substr(0, chars_shown)
	var wrapped := _wrap(text, w - 20.0, 15)
	var yy := y + 30.0
	for ln in wrapped:
		if E0.mono:
			draw_string(E0.mono, Vector2(x + 6, yy), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, E0.PARCH)
		yy += 22.0
	# line counter + continue hint
	var done_line: bool = chars_shown >= lines[line_idx].length()
	if done_line and fmod(_blink, 0.9) < 0.55:
		if E0.mono:
			draw_string(E0.mono, Vector2(x + w - 90.0, y + h - 2.0), "[F] \u2588", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, E0.DIM)
	if E0.mono:
		draw_string(E0.mono, Vector2(x, y + h - 2.0), "%d/%d" % [line_idx + 1, lines.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.6))

func _speaker_color() -> Color:
	if speaker == "SYSTEM" or speaker.begins_with("TERMINAL"):
		return E0.CYAN
	if speaker == "THE PENITENT":
		return E0.BONE
	if speaker.contains("MARTYR"):
		return E0.CRIMSON
	if speaker.contains("MEASURER"):
		return E0.PARCH
	return E0.GOLD

func _wrap(text: String, width: float, size: int) -> PackedStringArray:
	var out := PackedStringArray()
	var line := ""
	for word in text.split(" "):
		var candidate := (line + " " + word).strip_edges(true, false)
		var w := 0.0
		if E0.mono:
			w = E0.mono.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		if w > width and not line.is_empty():
			out.append(line)
			line = word
		else:
			line = candidate
	if not line.is_empty():
		out.append(line)
	return out
