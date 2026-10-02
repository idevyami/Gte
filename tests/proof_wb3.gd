## WB-3 living-architecture proof — close-up shots of the eleven new animated
## decor kinds in their placed rooms. Rendered under Xvfb like visual_proof.
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

	# WB3-01 · act1: womb roots over the ascent + fans on the shaft wall
	await _room("act1", Vector2(560, 1000))
	await _snap("wb3_01_roots")

	# WB3-02 · act3: the pilgrims' market stall on procession street
	await _room("act3", Vector2(70, 840))
	await _snap("wb3_02_stall")

	# WB3-03 · act5: chandelier + stained window over the nave
	await _room("act5", Vector2(500, 840))
	await _snap("wb3_03_chapel_lights")

	# WB3-04 · act5: candelabra row near the relic
	await _room("act5", Vector2(1290, 840))
	await _snap("wb3_04_candelabra")

	# WB3-05 · act4: freight hoist on the census floor
	await _room("act4", Vector2(330, 940))
	await _snap("wb3_05_lift")

	# WB3-06 · act7: engine lift + great fan + hoist rail
	await _room("act7", Vector2(2280, 840))
	await _snap("wb3_06_engine_works")

	# WB3-07 · act8: reliquary chandelier between the chains
	await _room("act8", Vector2(500, 840))
	await _snap("wb3_07_reliquary_glory")

	# WB3-08 · act9: aftermath rubble, puddle, roots under open sky
	await _room("act9", Vector2(700, 660))
	await _snap("wb3_08_aftermath")

	# WB3-09 · act6: archive windows + fan + web in the loft
	await _room("act6", Vector2(520, 840))
	await _snap("wb3_09_archive_loft")

	# WB3-10 · act2: decay passage — roots, web, puddle, fan
	await _room("act2", Vector2(900, 660))
	await _snap("wb3_10_decay")

	get_tree().quit()

func _process(_d: float) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
