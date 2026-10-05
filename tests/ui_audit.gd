## UI audit — renders the interface elements in their live states for VLM review.
extends Node

var game: Game
var main: Node

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://screenshots/ui_audit")
	_run.call_deferred()

func _snap(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://screenshots/ui_audit/" + name + ".png")
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

func _run() -> void:
	main = (load("res://main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	game = main.game
	main.title.hide_screen()
	game.set_active(true)
	game.new_game()
	await _wait(1.0)
	_skip_dialogue()
	# 01 — HUD in the world, healthy
	await _room("act1", Vector2(640, 600))
	await _snap("01_hud_clean")
	# 02 — HUD damaged + low consistency
	game.player.hp = 28
	GameState.consistency = 62
	GameState.spend(38, "audit")
	await _wait(0.4)
	game.system_log.push("TEST CITATION — REALITY OBJECTS.", "warn")
	await _wait(0.6)
	await _snap("02_hud_stressed")
	game.player.hp = 100
	GameState.consistency = 100
	GameState.restore(38, "audit")
	# 03 — dialogue box open mid-typewriter
	game.dialogue_box.open("oren_intro")
	await _wait(0.5)
	await _snap("03_dialogue")
	_skip_dialogue()
	# 04 — observe panel on the door
	await _room("act2", Vector2(1440, 600))
	game.observe_enter()
	await _wait(0.4)
	await _snap("04_observe")
	game.observe_exit()
	# 05 — interact prompt
	game.player.global_position = Vector2(1480, 600)
	await _wait(0.4)
	await _snap("05_prompt")
	get_tree().quit()
