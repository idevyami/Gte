## Screenshot — renders key frames of the real game to PNGs under Xvfb.
extends Node
var game: Game
func _ready() -> void:
	_run.call_deferred()
func _snap(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/shots/" + name + ".png")
	print("snap ", name)
func _run() -> void:
	var main := (load("res://main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	game = main.game
	# title screen
	await get_tree().create_timer(1.2, true, false, true).timeout
	_snap("01_title")
	main.title.hide_screen()
	game.set_active(true)
	game.new_game()
	await get_tree().create_timer(1.0, true, false, true).timeout
	while game.dialogue_box.active:
		game.dialogue_box.chars_shown = 99999
		game.dialogue_box.advance()
		await get_tree().process_frame
	_snap("02_act1")
	# act2 with observe panel on the door
	game.transition_to("act2")
	await _room("act2")
	game.player.global_position = Vector2(1440, 600)
	await get_tree().create_timer(0.3, true, false, true).timeout
	game.observe_enter()
	await get_tree().create_timer(0.4, true, false, true).timeout
	game.observe_idx = _find("DOOR_029")
	_snap("03_observe")
	game.observe_exit()
	# act3 street
	game.transition_to("act3")
	await _room("act3")
	game.player.global_position = Vector2(1080, 800)
	await get_tree().create_timer(0.5, true, false, true).timeout
	_snap("04_act3")
	# act5 chapel with believers + ward
	game.transition_to("act5")
	await _room("act5")
	game.player.global_position = Vector2(1500, 800)
	await get_tree().create_timer(0.6, true, false, true).timeout
	_snap("05_chapel")
	# act7 engine
	game.transition_to("act7")
	await _room("act7")
	game.player.global_position = Vector2(1600, 800)
	await get_tree().create_timer(0.6, true, false, true).timeout
	_snap("06_engine")
	# act8 boss
	game.transition_to("act8")
	await _room("act8")
	game.player.global_position = Vector2(450, 800)
	await get_tree().create_timer(1.0, true, false, true).timeout
	while game.dialogue_box.active:
		game.dialogue_box.chars_shown = 99999
		game.dialogue_box.advance()
		await get_tree().process_frame
	game.player.global_position = Vector2(600, 800)
	await get_tree().create_timer(1.2, true, false, true).timeout
	_snap("07_boss")
	# act9 aftermath
	game.transition_to("act9")
	await _room("act9")
	await get_tree().create_timer(1.0, true, false, true).timeout
	_snap("08_aftermath")
	get_tree().quit()
func _room(expected: String) -> void:
	for i in 600:
		if game.room_id == expected and game.state == "playing":
			return
		if game.dialogue_box.active:
			game.dialogue_box.chars_shown = 99999
			game.dialogue_box.advance()
		await get_tree().process_frame
func _find(key: String) -> int:
	for i in game.observe_targets.size():
		if game.observe_targets[i] and game.observe_targets[i].instance_key == key:
			return i
	return 0
