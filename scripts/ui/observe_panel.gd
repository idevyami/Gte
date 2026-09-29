## ObservePanel — the readout. Rendered in the exact locked format:
## dotted leaders, modifiable properties in gold, costs in crimson, sealed
## rows that unseal as reality thins. The world is data; data can be edited.
class_name ObservePanel
extends Control

var game
var receipt := ""          # last modification receipt lines
var receipt_t := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func set_game(p_game) -> void:
	game = p_game

func show_receipt(lines: Array) -> void:
	receipt = "\n".join(PackedStringArray(lines))
	receipt_t = 3.2

func _process(delta: float) -> void:
	if receipt_t > 0.0:
		receipt_t -= delta
	visible = game != null and game.observe_active
	if visible:
		queue_redraw()

func _draw() -> void:
	if game == null or not game.observe_active:
		return
	if game.observe_targets.is_empty():
		return
	var target = game.observe_targets[game.observe_idx]
	if target == null or not is_instance_valid(target):
		return
	var data: EntityData = target.data
	var vp := get_viewport_rect().size
	var w := 430.0
	var h := 470.0
	var x := vp.x - w - 24.0
	var y := 64.0
	# panel
	draw_rect(Rect2(x, y, w, h), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.9))
	draw_rect(Rect2(x, y, w, h), E0.ASH, false, 1.0)
	draw_rect(Rect2(x, y, w, 3.0), E0.CYAN)
	var pad := 16.0
	var cx := x + pad
	var cy := y + 26.0
	# header
	if E0.mono_bold:
		draw_string(E0.mono_bold, Vector2(cx, cy), "> OBSERVE \u2014 TARGET: " + data.display, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, E0.CYAN)
	cy += 26.0
	# dotted fields
	var props := data.visible_properties(GameState.stage, GameState.flags)
	var target_props: Array = []
	for p in props:
		target_props.append(p)
	_field("ID", data.id_number, cy, cx, w - pad * 2.0); cy += 22.0
	_field("TYPE", data.type, cy, cx, w - pad * 2.0); cy += 22.0
	_field("STATE", data.state, cy, cx, w - pad * 2.0); cy += 22.0
	# properties block
	if E0.mono:
		draw_string(E0.mono, Vector2(cx, cy), "PROPERTIES..", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, E0.DIM)
	cy += 20.0
	var mod_idx := 0
	for p in target_props:
		var is_selected: bool = p["modifiable"] and mod_idx == game.observe_prop_idx
		var line_col := E0.PARCH
		var val_text := _fmt(p["value"])
		if p["sealed"]:
			line_col = Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.55)
			val_text = "SEALED"
		elif p["modifiable"]:
			line_col = E0.GOLD
		if is_selected:
			line_col = E0.BONE
		if E0.mono:
			var sel_arrow := "> " if is_selected else "   "
			var cost_text := ""
			if p["modifiable"] and int(p["cost"]) > 0:
				cost_text = "  [\u2212%d]" % int(p["cost"])
			var preview := ""
			if is_selected:
				var nv = data.next_value(String(p["name"]))
				if String(_fmt(nv)) != val_text:
					preview = "  \u2192 " + _fmt(nv)
			var line := sel_arrow + String(p["name"]) + "=" + val_text + preview + cost_text
			draw_string(E0.mono, Vector2(cx + 8.0, cy), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, line_col)
		if p["modifiable"]:
			mod_idx += 1
		cy += 19.0
	cy += 4.0
	_field("PURPOSE", "\u201c%s\u201d" % data.purpose, cy, cx, w - pad * 2.0, true); cy += 22.0
	if not data.memory.is_empty():
		_field("MEMORY", data.memory, cy, cx, w - pad * 2.0, true); cy += 22.0
	if data.belief > 0.0:
		_field("BELIEF", "%.0f" % data.belief, cy, cx, w - pad * 2.0); cy += 22.0
		# belief bar
		draw_rect(Rect2(cx + 8.0, cy - 12.0, 160.0, 6), E0.ASH)
		draw_rect(Rect2(cx + 8.0, cy - 12.0, 160.0 * clampf(data.belief / 100.0, 0.0, 1.0), 6), E0.GOLD)
	for note in data.notes:
		if E0.mono:
			draw_string(E0.mono, Vector2(cx + 8.0, cy), String(note), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.8))
		cy += 17.0
	# receipt
	if receipt_t > 0.0 and not receipt.is_empty():
		if E0.mono:
			var ry := y + h - 108.0
			draw_rect(Rect2(cx, ry - 14.0, w - pad * 2.0, 86.0), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.6))
			var yy := ry
			for ln in receipt.split("\n"):
				var col := E0.PARCH
				if ln.contains("CONSISTENCY"):
					col = E0.CRIMSON
				elif ln.begins_with(">"):
					col = E0.CYAN
				elif ln.contains("ACK"):
					col = E0.GOLD
				draw_string(E0.mono, Vector2(cx + 6.0, yy), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(col.r, col.g, col.b, clampf(receipt_t, 0.0, 1.0)))
				yy += 17.0
	# footer help
	if E0.mono:
		var foot := "TAB: NEXT / EXIT   W/S: SELECT   E: MODIFY"
		draw_string(E0.mono, Vector2(cx, y + h - 18.0), foot, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, E0.DIM)

func _field(name: String, value: String, y: float, x: float, width: float, small := false) -> void:
	if E0.mono == null:
		return
	var size := 12 if small else 12
	var label := name + " "
	var dots := ".".repeat(maxi(2, int((width * 0.42) / 7.0) - name.length()))
	draw_string(E0.mono, Vector2(x, y), label + dots, HORIZONTAL_ALIGNMENT_LEFT, -1, size, E0.DIM)
	draw_string(E0.mono, Vector2(x + width * 0.44, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, E0.PARCH)

func _fmt(v: Variant) -> String:
	match typeof(v):
		TYPE_BOOL:
			return "true" if v else "false"
		TYPE_INT, TYPE_FLOAT:
			return str(v)
		_:
			return String(v)
