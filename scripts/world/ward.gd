## WardBarrier — belief as physics. A wall held up by nothing you can kill,
## only by things that can stop believing. Belief is computed live from the
## chanters; the ward admits the bearer of the Pale Saint relic or one who has
## joined the ritual; it collapses when belief runs out.
class_name WardBarrier
extends EntityNode

var chanters: Array = []          # live Believer nodes feeding it
var passable := false
var broken := false
var _body: StaticBody2D
var _body_shape: CollisionShape2D

func setup_ward(p_instance: String, height: float) -> void:
	setup("WARD_BARRIER", p_instance, "ward")
	extra["height"] = height
	extra["anchor_y"] = height * 0.5
	extra["br_w"] = 40.0
	extra["br_h"] = height + 8.0

func _ready() -> void:
	super()
	_body = StaticBody2D.new()
	_body.collision_layer = E0.L_WORLD
	_body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(18.0, float(extra["height"]))
	shape.shape = rect
	shape.position = Vector2(0, -float(extra["height"]) * 0.5)
	_body.add_child(shape)
	_body_shape = shape
	add_child(_body)
	prompt = "THE WARD"

func belief_now() -> float:
	## 12 hands hold it up: each living chanter sustains 25 belief. Dead or
	## ABANDONED chanters sustain nothing. The relic bearer joins the count.
	var live_count := 0
	for c in chanters:
		if is_instance_valid(c) and not c.is_dead() and c.is_chanting():
			live_count += 1
	var relic_bonus := 25.0 if GameState.has_flag(GameState.F_RELIQ_CARRIED) else 0.0
	return clampf(live_count * 25.0 + relic_bonus, 0.0, 100.0)

func chanter_count() -> int:
	var n := 0
	for c in chanters:
		if is_instance_valid(c) and not c.is_dead() and c.is_chanting():
			n += 1
	return n

func update_state() -> void:
	# Data mirrors reality — the readout is never fake.
	data.properties["belief"]["value"] = int(belief_now())
	data.properties["held_by"]["value"] = maxi(chanter_count() * 4, 0)
	if broken:
		return
	var relic := GameState.has_flag(GameState.F_RELIQ_CARRIED)
	var joined := GameState.has_flag(GameState.F_JOINED_RITUAL)
	if relic or joined:
		passable = true
	if belief_now() <= 0.0:
		_collapse()
	_body_shape.set_deferred("disabled", passable or broken)

func _collapse() -> void:
	if broken:
		return
	broken = true
	passable = true
	GameState.set_flag(GameState.F_WARD_BROKEN)
	data.set_state("BROKEN")
	AudioManager.play_sfx("sfx_barrier_break", -2.0)
	FX.shake(7.0, 0.5)
	FX.tear_pulse(0.7)

func interact(game) -> void:
	if broken:
		game.system_message("THE WARD IS SPENT. THE AIR STILL REMEMBERS BEING HELD.")
		return
	if passable:
		game.system_message("THE WARD READS YOU AND WITHDRAWS — A SUPPLICANT IS NOT AN INTRUDER.")
		return
	game.system_message("WARD INTEGRITY %d%% — HELD BY %d CHANTERS. IT ADMITS THE BEARER OF THE RELIC." % [int(belief_now()), chanter_count()])

func _process(delta: float) -> void:
	anim_t += delta
	update_state()
	queue_redraw()

func _draw() -> void:
	if broken:
		# residue: faint vertical scratches where belief used to stand
		for i in 5:
			draw_line(Vector2(-8.0 + i * 4.0, -float(extra["height"])), Vector2(-8.0 + i * 4.0 + 3.0, -6.0),
				Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.06), 1.0)
		return
	var b := belief_now() / 100.0
	var h := float(extra["height"])
	# shimmering curtain of belief
	for i in 14:
		var t := float(i) / 13.0
		var y := -h * t - 3.0
		var sway := sin(anim_t * 2.2 + t * 9.0) * 3.0
		var alpha := (0.10 + 0.16 * b) * (0.7 + 0.3 * sin(anim_t * 3.0 + t * 7.0))
		draw_line(Vector2(-9.0 + sway, y), Vector2(9.0 + sway, y),
			Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, alpha), 2.0)
	# rune column
	for i in int(maxi(3, int(h / 40.0))):
		var ry := -20.0 - i * 40.0
		var pulse := 0.35 + 0.3 * sin(anim_t * 2.0 + i)
		draw_rect(Rect2(-3.0 + sin(anim_t + i) * 2.0, ry, 6.0, 6.0),
			Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, pulse * b))
	if passable:
		# it parts for you: an opening outline
		var gap_h := 70.0
		draw_rect(Rect2(-11.0, -gap_h - 10.0, 4.0, gap_h), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.4))
		draw_rect(Rect2(7.0, -gap_h - 10.0, 4.0, gap_h), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.4))
