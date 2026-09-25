## EndScreen — the aftermath: the question, the ledger of what you spent,
## and nothing else. Ends on a question, not an answer.
class_name EndScreen
extends Control

signal return_to_title

var anim_t := 0.0
var stats := {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false

func open(p_stats: Dictionary) -> void:
	stats = p_stats
	visible = true
	anim_t = 0.0
	AudioManager.play_music("aftermath")
	AudioManager.play_ambient("wind", 0.25)

func _process(delta: float) -> void:
	if not visible:
		return
	anim_t += delta
	if anim_t > 2.0 and (Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack")):
		visible = false
		return_to_title.emit()
	queue_redraw()

func _draw() -> void:
	var vp := get_viewport_rect().size
	var fade := clampf(anim_t / 2.0, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, vp), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.92 * fade))
	var cy := vp.y * 0.34
	if E0.mono:
		var pre := "RESTORATION: 0.1% · ATTEMPT 818 · RECORD CLOSED"
		var pw := E0.mono.get_string_size(pre, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(E0.mono, Vector2((vp.x - pw) * 0.5, cy), pre, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, fade))
	# the question — serif, slow to appear
	if E0.serif:
		var q := "IF YOU WERE CREATED FOR A PURPOSE \u2014"
		var q2 := "DO YOU HAVE THE RIGHT TO REJECT IT?"
		var qa := clampf((anim_t - 0.8) / 1.6, 0.0, 1.0)
		var qw := E0.serif.get_string_size(q, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
		draw_string(E0.serif, Vector2((vp.x - qw) * 0.5, cy + 60.0), q, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, qa))
		var qw2 := E0.serif.get_string_size(q2, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
		draw_string(E0.serif, Vector2((vp.x - qw2) * 0.5, cy + 108.0), q2, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, qa))
	# the ledger — every number real
	if E0.mono and anim_t > 2.2:
		var rows := [
			["EDITS MADE", str(stats.get("edits", 0))],
			["CONSISTENCY SPENT", str(stats.get("spent", 0))],
			["CONSISTENCY REMAINING", "%03d%% · S%d" % [GameState.consistency, GameState.stage]],
			["FRAGMENTS RECOVERED", "%d / 4" % GameState.fragments.size()],
			["DISSIPATED", str(stats.get("dissipated", 0))],
			["DEATHS", str(stats.get("deaths", 0))],
			["TIME IN THE CITY", _fmt_time(int(stats.get("elapsed", 0)))],
		]
		var y := vp.y * 0.62
		var lx := vp.x * 0.5 - 170.0
		for row in rows:
			var label: String = row[0]
			var value: String = row[1]
			draw_string(E0.mono, Vector2(lx, y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, E0.DIM)
			draw_string(E0.mono, Vector2(lx + 260.0, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, E0.PARCH)
			y += 22.0
		# judgment lines
		var judgment := ""
		if stats.get("spent", 0) == 0:
			judgment = "YOU TOUCHED NOTHING. THE CITY REMEMBERS THAT TOO."
		elif GameState.consistency <= 40:
			judgment = "YOU SPENT DEEPLY. THE SEAMS SHOWED YOU THEIR SECRETS."
		elif GameState.fragments.size() >= 4:
			judgment = "YOU LISTENED. THAT WAS NEVER REQUIRED OF YOU."
		if not judgment.is_empty():
			draw_string(E0.mono, Vector2(lx, y + 12.0), judgment, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.8))
	if anim_t > 3.0 and E0.mono:
		if fmod(anim_t, 1.2) < 0.75:
			var foot := "[F] RETURN TO THE TITLE \u2014 THE RECORD STANDS"
			var fw := E0.mono.get_string_size(foot, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			draw_string(E0.mono, Vector2((vp.x - fw) * 0.5, vp.y - 40.0), foot, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, E0.DIM)
		var credit := "A VERTICAL SLICE · END OF RECORD"
		var cw := E0.mono.get_string_size(credit, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_string(E0.mono, Vector2((vp.x - cw) * 0.5, vp.y - 20.0), credit, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.5))

func _fmt_time(seconds: int) -> String:
	var m := seconds / 60
	var s := seconds % 60
	return "%02d:%02d" % [m, s]
