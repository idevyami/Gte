## WB-4 "The Living City" proof — the far-life processions, the enriched
## character animation (anticipation squash, follow-through, roll tumble,
## telegraph rings), the anchor ceremony, the observe zoom. Rendered under
## Xvfb like the other proof scenes.
extends Node

var game: Game
var main: Node

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://screenshots")
	_run.call_deferred()

func _snap(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://screenshots/" + name + ".png")
	print("SNAP ", name)

func _wait(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout

func _skip_dialogue() -> void:
	while game.dialogue_box.active:
		game.dialogue_box.chars_shown = 99999
		game.dialogue_box.advance()
		await get_tree().process_frame

func _room(id: String, pos := Vector2(640, 600)) -> void:
	game.transition_to(id)
	for i in 900:
		if game.room_id == id and game.state == "playing":
			break
		if game.dialogue_box.active:
			game.dialogue_box.chars_shown = 99999
			game.dialogue_box.advance()
		await get_tree().process_frame
	for i in 900:
		if not game.cinema.is_showing():
			break
		await get_tree().process_frame
	await _wait(0.5)
	game.player.global_position = pos
	game.player.velocity = Vector2.ZERO
	await _wait(0.5)
	_skip_dialogue()
	await _wait(0.3)

func _press(action: String) -> void:
	Input.action_press(action)
	await get_tree().process_frame
	Input.action_release(action)

func _run() -> void:
	main = (load("res://main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	game = main.game
	main.title.hide_screen()
	game.set_active(true)
	game.new_game()
	await _wait(0.8)
	_skip_dialogue()

	# WB4-01 · act3: the pilgrim procession crosses the far street (bier + lanterns)
	await _room("act3", Vector2(300, 814))
	await _wait(1.6)
	await _snap("wb4_01_city_procession")

	# WB4-02 · act3: later — barge drifting the canal, birds wheeling the spires
	await _wait(2.6)
	await _snap("wb4_02_barge_birds")

	# WB4-03 · act3: the telegraph ring — a hollow winds its lunge
	game.player.global_position = Vector2(1560, 814)
	await _wait(1.4)
	for i in 240:
		var found := false
		for n in get_tree().get_nodes_in_group("enemies"):
			if n is Hollow and n.state == Hollow.TELEGRAPH:
				found = true
		if found:
			break
		await get_tree().process_frame
	await _snap("wb4_03_telegraph_ring")

	# WB4-04 · the attack chain: anticipation coil, strike, follow-through
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Hollow:
			game.player.global_position = n.global_position - Vector2(64, 0)
			game.player.velocity = Vector2.ZERO
	game.player.facing = 1
	await _wait(0.6)
	await _press("attack")
	await _wait(0.03)
	await _snap("wb4_04a_anticipation")
	await _wait(0.07)
	await _snap("wb4_04b_strike")
	await _wait(0.06)
	await _snap("wb4_04c_follow_through")

	# WB4-05 · the roll tumbles (two phases of the rotation)
	await _press("roll")
	await _wait(0.10)
	await _snap("wb4_05a_roll_tumble")
	await _wait(0.13)
	await _snap("wb4_05b_roll_late")

	# WB4-06 · act4: Oren the Measurer, bow cycle
	await _room("act4", Vector2(1010, 840))
	await _snap("wb4_06a_oren_bow")
	await _wait(1.6)
	await _snap("wb4_06b_oren_counter")

	# WB4-07 · act5: the chapel gallery procession behind the nave (censer leading)
	await _room("act5", Vector2(640, 814))
	await _wait(1.8)
	await _snap("wb4_07_chapel_gallery")

	# WB4-08 · act5: kneeling believers, prayer breath
	await _room("act5", Vector2(1470, 814))
	await _snap("wb4_08_kneel_breath")

	# WB4-09 · act7: the engine gang swings in unison (far plane above the works)
	await _room("act7", Vector2(900, 814))
	await _wait(0.8)
	await _snap("wb4_09a_engine_gang")
	await _wait(1.0)
	await _snap("wb4_09b_engine_gang_late")

	# WB4-10 · act9: mourners with the bier, lanterns rising through the ruin
	await _room("act9", Vector2(640, 814))
	await _wait(2.0)
	await _snap("wb4_10_aftermath_mourners")

	# WB4-11 · act1: the anchor ceremony — pulse rings + rising record motes
	await _room("act1", Vector2(1800, 660))
	for n in game.world.get_children():
		if n is Anchor:
			n.interact(game)
			break
	await _wait(0.35)
	await _snap("wb4_11_anchor_ceremony")

	# WB4-12 · observe zoom: the lens leans toward what is read
	await _room("act3", Vector2(1500, 814))
	await _wait(0.6)
	game.observe_enter()
	await _wait(0.9)
	await _snap("wb4_12_observe_zoom")
	game.observe_exit()

	print("WB4 PROOFS DONE")
	get_tree().quit(0)
