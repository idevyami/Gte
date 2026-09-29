## DebugRoom — boots every room directly and reports runtime errors.
extends Node

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	print("=== ROOM BOOT TEST ===")
	var packed := load("res://main.tscn") as PackedScene
	var main := packed.instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var game: Game = main.game
	game.set_active(true)
	game.new_game()
	await get_tree().process_frame
	await get_tree().process_frame
	for room_id in ["act1", "act2", "act3", "act4", "act5", "act6", "act7", "act8", "act9"]:
		print("[room] ", room_id)
		game.load_room(room_id)
		await get_tree().process_frame
		await get_tree().process_frame
		var ok_room: bool = game.room_id == room_id
		var ok_player: bool = game.player != null and is_instance_valid(game.player)
		var enemies := get_tree().get_nodes_in_group("enemies").size()
		var interactables := get_tree().get_nodes_in_group("interactable").size()
		print("   room_ok=%s player=%s enemies=%d interactables=%d" % [ok_room, ok_player, enemies, interactables])
		await get_tree().process_frame
	# now test the transition machinery itself
	game.state = "playing"
	game.load_room("act1")
	await get_tree().process_frame
	game.player.global_position = Vector2(1585, 200)
	print("[transition] arming, state=", game.state)
	await get_tree().process_frame
	print("[transition] after 1 frame, state=", game.state, " room=", game.room_id)
	for i in 60:
		await get_tree().process_frame
		if game.room_id == "act2":
			print("[transition] OK at frame ", i)
			break
	print("[transition] final room=", game.room_id, " state=", game.state)
	get_tree().quit(0)
