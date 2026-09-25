## SystemLog — cold cyan system messages, typewritten, top-center. The world
## files its objections here: stage changes, corrections, anchor receipts.
class_name SystemLog
extends Control

var entries: Array = []   # {text, shown, t, color}
const MAX_ENTRIES := 4

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.consistency_stage_changed.connect(_on_stage)
	EventBus.correction_spawned.connect(func(_p): push("CORRECTION FILED.", "warn"))

func push(text: String, mode := "system") -> void:
	var col := E0.CYAN
	match mode:
		"warn":
			col = E0.GOLD
		"danger":
			col = E0.CRIMSON
		"quiet":
			col = E0.DIM
	entries.append({"text": text, "shown": 0, "t": 0.0, "color": col, "mode": mode})
	while entries.size() > MAX_ENTRIES:
		entries.pop_front()

func _on_stage(stage: int) -> void:
	var names := ["", "WHISPERS", "ENVIRONMENTAL INCONSISTENCIES", "NPC AWARENESS",
		"THE CENSOR HUNTS", "REALITY ACTIVELY HUNTS", "HIDDEN STRUCTURES"]
	push("CONSISTENCY %03d%% — STAGE %d: %s" % [GameState.consistency, stage, names[clampi(stage, 1, 6)]],
		"danger" if stage >= 4 else "warn")
	FX.stage_transition_glitch(stage)

func _process(delta: float) -> void:
	var dirty := false
	for e in entries:
		e["t"] += delta
		if e["t"] < 6.0:
			e["shown"] = mini(int(ceil(60.0 * delta)) + int(e["shown"]), String(e["text"]).length())
		dirty = true
	for i in range(entries.size() - 1, -1, -1):
		if entries[i]["t"] > 7.0:
			entries.remove_at(i)
			dirty = true
	if dirty:
		queue_redraw()

func _draw() -> void:
	var vp := get_viewport_rect().size
	var y := 64.0
	if GameState.boss_defeated == false and _boss_active():
		y = 92.0
	for e in entries:
		var text: String = e["text"].substr(0, int(e["shown"]))
		var alpha := 1.0
		if e["t"] > 6.0:
			alpha = clampf(1.0 - (e["t"] - 6.0), 0.0, 1.0)
		if E0.mono:
			var w := E0.mono.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			var x := (vp.x - w) * 0.5
			var col: Color = e["color"]
			draw_rect(Rect2(x - 8, y - 13, w + 16, 19), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.55 * alpha))
			draw_string(E0.mono, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(col.r, col.g, col.b, alpha))
		y += 24.0

func _boss_active() -> bool:
	var game := get_tree().get_first_node_in_group("game")
	return game != null and game.get("boss") != null
