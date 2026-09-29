## TheHeart — THE HEART OF THE DESIGN. Grown, not built. It beats; the
## rotors must be aligned to its rhythm. Observable; its fuel is sealed.
class_name TheHeart
extends EntityNode

var beat_t := 0.0
var aligned_cache := false

func setup_heart() -> void:
	setup("HEART_OF_THE_DESIGN", "HEART_OF_THE_DESIGN", "heart")
	extra["anchor_y"] = 70.0
	extra["br_w"] = 180.0
	extra["br_h"] = 150.0

func _refresh_prompt() -> void:
	prompt = "OBSERVE THE HEART"

func interact(game) -> void:
	if GameState.has_flag(GameState.F_HEART_ALIGNED):
		game.system_message("IT BEATS IN SEQUENCE NOW. YOU DID THAT. IT HAS NOT STOPPED SINCE.")
	else:
		game.system_message("THE ROTORS ARE DE-SYNCED FROM THE RHYTHM. READ THEM WITH [TAB] — THE SEQUENCE IS IN THEIR MEMORY.")

func _process(delta: float) -> void:
	anim_t += delta
	var bpm := 60.0
	if GameState.has_flag(GameState.F_HEART_ALIGNED):
		bpm = 78.0
	beat_t += delta * bpm / 60.0
	queue_redraw()

func _draw() -> void:
	# the machine-heart: a great dark chamber in a cage of pipes and tracery
	var beat := pow(maxf(0.0, sin(beat_t * TAU)), 3.0)
	var scale_k := 1.0 + beat * 0.04
	# pipe cage
	for i in 6:
		var a := PI * (0.1 + 0.8 * i / 5.0)
		var dir := Vector2(cos(a), sin(a) * -0.8)
		draw_line(dir * 60.0, dir * 96.0, E0.ASH, 7.0)
		draw_circle(dir * 96.0, 5.0, E0.DIRTY_STONE)
	# the chamber
	var col := E0.BLOOD.lerp(E0.CRIMSON, beat)
	var r := 52.0 * scale_k
	draw_circle(Vector2(0, -70.0), r, E0.CHARCOAL)
	draw_circle(Vector2(0, -70.0), r - 7.0, col)
	draw_circle(Vector2(0, -70.0), r - 18.0, col.darkened(0.35))
	# veins of gold when aligned
	if GameState.has_flag(GameState.F_HEART_ALIGNED):
		for i in 5:
			var a := TAU * i / 5.0 + anim_t * 0.3
			draw_line(Vector2(0, -70.0) + Vector2(cos(a), sin(a)) * (r - 6.0),
				Vector2(0, -70.0) + Vector2(cos(a), sin(a)) * (r + 14.0 + beat * 6.0),
				Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.5), 2.0)
	# heat shimmer glow
	draw_circle(Vector2(0, -70.0), r + 30.0, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.05 + 0.03 * beat))
	# mount
	draw_rect(Rect2(-30, -26, 60, 26), E0.DIRTY_STONE)
	for i in 3:
		draw_rect(Rect2(-24 + i * 18, -32, 10, 8), E0.ASH)
	# cable-tracery rising into the dark
	draw_line(Vector2(-40, -110), Vector2(-70, -160), E0.ASH, 2.0)
	draw_line(Vector2(40, -110), Vector2(74, -158), E0.ASH, 2.0)
	draw_line(Vector2(0, -126), Vector2(0, -170), E0.ASH, 2.0)
