extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	print("=== ACT4 TRANSITION DEBUG ===")
	var main := (load("res://main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var game: Game = main.game
	game.set_active(true)
	game.new_game()
	await get_tree().process_frame
	game.load_room("act3")
	await get_tree().process_frame
	await get_tree().process_frame
	print("act3 loaded, state=", game.state, " player=", game.player.hp)
	# kill a hollow like the smoke test does
	var hollow: Hollow = null
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Hollow:
			hollow = node
			break
	if hollow:
		game.player.global_position = hollow.global_position + Vector2(-60, 0)
		await get_tree().process_frame
		game.player.facing = 1
		var guard := 0
		while guard < 12:
			if not is_instance_valid(hollow) or hollow.dead:
				break
			Input.action_press("attack")
			await get_tree().process_frame
			Input.action_release("attack")
			await get_tree().process_frame
			await get_tree().process_frame
			await get_tree().process_frame
			guard += 1
		print("hollow dead, guard=", guard)
	print("state before transition: ", game.state, " transitioning=", game._transitioning, " player hp=", game.player.hp, " pos=", game.player.global_position)
	game.transition_to("act4")
	for i in 600:
		if game.dialogue_box.active:
			game.dialogue_box.chars_shown = 99999
			game.dialogue_box.advance()
		if game.room_id == "act4" and game.state == "playing":
			print("ACT4 OK at iter ", i)
			break
		await get_tree().process_frame
	print("final room=", game.room_id, " state=", game.state, " hp=", game.player.hp)
	get_tree().quit(0)
