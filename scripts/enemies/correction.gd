## Correction — a small glitch mote the system files near you at stage 4+.
## Touching one costs 2 consistency and 6 HP. They are the world's paperwork.
class_name Correction
extends Node2D

var life_t := 0.0
var anim_t := 0.0
var contact_cd := 0.0

func _ready() -> void:
	EventBus.correction_spawned.emit(global_position)

func _process(delta: float) -> void:
	anim_t += delta
	life_t += delta
	contact_cd = maxf(0.0, contact_cd - delta)
	var player := get_tree().get_first_node_in_group("player") as Player
	if player and player.hp > 0:
		var to_p := player.global_position - global_position
		var sp := 46.0 + 12.0 * GameState.stage
		global_position += to_p.limit_length(120.0).normalized() * sp * delta
		if to_p.length() < 18.0 and contact_cd <= 0.0:
			contact_cd = 1.5
			player.take_damage(6, global_position)
			GameState.spend(E0.CORRECTION_TOUCH_DRAIN, "correction")
			FX.tear_pulse(0.4)
			_burst()
	if life_t > 12.0:
		_burst()

func _burst() -> void:
	queue_free()

func _draw() -> void:
	# a diamond of broken data, red where it stings
	var j := Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
	var pulse := 0.5 + 0.5 * sin(anim_t * 13.0)
	var size := 7.0 + 3.0 * pulse
	var col := Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.5 + 0.4 * pulse)
	draw_colored_polygon(PackedVector2Array([
		j + Vector2(0, -size), j + Vector2(size * 0.6, 0), j + Vector2(0, size), j + Vector2(-size * 0.6, 0),
	]), col)
	draw_colored_polygon(PackedVector2Array([
		j + Vector2(0, -size * 0.5), j + Vector2(size * 0.3, 0), j + Vector2(0, size * 0.5), j + Vector2(-size * 0.3, 0),
	]), Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.6))
	for i in 2:
		var a := anim_t * 3.0 + i * PI
		draw_line(j + Vector2(cos(a), sin(a)) * 8.0, j + Vector2(cos(a), sin(a)) * 12.0,
			Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.3), 1.0)
