## PauseMenu — RESUME / MEMORY (the fragment index) / RESTART FROM ANCHOR /
## QUIT TO TITLE. The memory index is real: only found fragments are listed.
class_name PauseMenu
extends Control

signal resume_requested
signal restart_requested
signal quit_to_title_requested

var idx := 0
var menu := []
var show_memory := false
var anim_t := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	_rebuild()

func _rebuild() -> void:
	menu = [
		{"label": "RESUME", "action": "resume"},
		{"label": "MEMORY", "action": "memory"},
		{"label": "RESTART FROM ANCHOR", "action": "restart"},
		{"label": "QUIT TO TITLE", "action": "quit"},
	]

func open() -> void:
	visible = true
	idx = 0
	show_memory = false
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false

func _process(delta: float) -> void:
	if not visible:
		return
	anim_t += delta
	if Input.is_action_just_pressed("pause"):
		if show_memory:
			show_memory = false
		else:
			close()
			resume_requested.emit()
		return
	if Input.is_action_just_pressed("move_up"):
		idx = (idx - 1 + menu.size()) % menu.size()
		AudioManager.play_sfx("sfx_ui_move", -8.0)
	if Input.is_action_just_pressed("move_down"):
		idx = (idx + 1) % menu.size()
		AudioManager.play_sfx("sfx_ui_move", -8.0)
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump"):
		_confirm()
	queue_redraw()

func _confirm() -> void:
	AudioManager.play_sfx("sfx_ui_confirm", -4.0)
	if show_memory:
		show_memory = false
		return
	match String(menu[idx]["action"]):
		"resume":
			close()
			resume_requested.emit()
		"memory":
			show_memory = true
		"restart":
			close()
			restart_requested.emit()
		"quit":
			close()
			quit_to_title_requested.emit()

func _draw() -> void:
	var vp := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.82))
	if show_memory:
		_draw_memory(vp)
		return
	if E0.mono_bold:
		draw_string(E0.mono_bold, Vector2(vp.x * 0.5 - 60.0, vp.y * 0.3), "PAUSED", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, E0.BONE)
	var my := vp.y * 0.42
	for i in menu.size():
		var sel: bool = i == idx
		var col := E0.BONE if sel else E0.PARCH
		if E0.mono:
			var label: String = menu[i]["label"]
			var lw := E0.mono.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			var lx := (vp.x - lw) * 0.5
			if sel and fmod(anim_t, 1.0) < 0.6:
				draw_string(E0.mono, Vector2(lx - 24.0, my), "\u25b8", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, E0.GOLD)
			draw_string(E0.mono, Vector2(lx, my), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
		my += 32.0
	if E0.mono:
		var hint := "CONSISTENCY %03d%% · S%d — %s" % [GameState.consistency, GameState.stage, GameState.stage_name()]
		var hw := E0.mono.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(E0.mono, Vector2((vp.x - hw) * 0.5, vp.y * 0.3 + 26.0), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, E0.CYAN)

func _draw_memory(vp: Vector2) -> void:
	if E0.mono_bold:
		draw_string(E0.mono_bold, Vector2(120.0, 90.0), "MEMORY INDEX", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, E0.BONE)
	if E0.mono:
		draw_string(E0.mono, Vector2(120.0, 114.0), "FOUND: %d / 4" % GameState.fragments.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, E0.DIM)
	var y := 160.0
	var x := 120.0
	var w := vp.x - 240.0
	# found fragments — real records only
	for frag_id in GameState.fragments:
		var def: Dictionary = GameState.FRAGMENT_DEFS.get(frag_id, {})
		if def.is_empty():
			continue
		draw_rect(Rect2(x, y - 16.0, w, 58.0), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.8))
		draw_rect(Rect2(x, y - 16.0, 3.0, 58.0), E0.GOLD)
		draw_string(E0.mono, Vector2(x + 14.0, y), String(def["code"]) + "  ·  " + String(def["title"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, E0.BONE)
		draw_string(E0.mono, Vector2(x + 14.0, y + 20.0), "STATE: " + String(def["integrity"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, E0.DIM)
		draw_string(E0.mono, Vector2(x + 14.0, y + 38.0), String(def["note"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, E0.PARCH)
		y += 70.0
	if GameState.fragments.is_empty():
		draw_string(E0.mono, Vector2(x, y), "NO FRAGMENTS FOUND. MEMORY IS NOT ISSUED. IT IS RECOVERED.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, E0.DIM)
		y += 30.0
	# the withheld sixth
	draw_string(E0.mono, Vector2(x, y + 18.0), "A SIXTH FUNDAMENTAL IS WHISPERED TO EXIST.", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.7))
	draw_string(E0.mono, Vector2(x, y + 36.0), "IT IS NOT WRITTEN ANYWHERE. THAT IS NOT THE SAME AS ABSENT.", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, E0.DIM)
	draw_string(E0.mono, Vector2(x, vp.y - 60.0), "[F] BACK", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, E0.DIM)
