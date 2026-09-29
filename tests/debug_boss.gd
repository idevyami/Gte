extends Node

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	print("=== BOSS FOCUS DEBUG ===")
	var main := (load("res://main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var game: Game = main.game
	game.set_active(true)
	game.new_game()
	await get_tree().process_frame
	game.transition_to("act8")
	for i in 300:
		if game.room_id == "act8" and game.state == "playing":
			break
		await get_tree().process_frame
	print("room=", game.room_id, " player_hp=", game.player.hp)
	var boss: BoundMartyr = game.boss
	print("boss=", boss, " bearers=", boss._bearers.size())
	game.player.global_position = Vector2(450, 800)
	for i in 30:
		await get_tree().process_frame
	while game.dialogue_box.active:
		game.dialogue_box.chars_shown = 99999
		game.dialogue_box.advance()
		await get_tree().process_frame
	print("intro_done=", boss.intro_done, " phase=", boss.phase, " player_hp=", game.player.hp)
	game.player.global_position = Vector2(340, 800)
	# censer modify
	var censer = null
	for node in get_tree().get_nodes_in_group("interactable"):
		if node.instance_key == "CENSER_RELIQUARY":
			censer = node
	print("censer=", censer)
	if censer:
		var okm: bool = EntityDB.modify(censer, "purpose")
		print("modify ok=", okm, " censer purpose now=", censer.data.properties["purpose"]["value"])
		await get_tree().process_frame
		await get_tree().process_frame
		var alive_chanters := 0
		for b in boss._bearers:
			if is_instance_valid(b):
				print("  bearer state=", b.state, " dead=", b.dead, " chanting=", b.is_chanting())
		print("shielded=", boss.shielded(), " player_hp=", game.player.hp)
	# damage to phase 2
	boss.hp = 650
	boss.take_hit(60, boss.global_position + Vector2(100, 0), true)
	print("after hit hp=", boss.hp, " phase=", boss.phase)
	for i in 60:
		game.player._iframes = 10.0
		await get_tree().process_frame
	print("phase now=", boss.phase, " state=", boss.state, " player_hp=", game.player.hp)
	while game.dialogue_box.active:
		game.dialogue_box.chars_shown = 99999
		game.dialogue_box.advance()
		await get_tree().process_frame
	# to phase 3
	boss.hp = 350
	boss.take_hit(60, boss.global_position + Vector2(100, 0), true)
	for i in 60:
		game.player._iframes = 10.0
		await get_tree().process_frame
	print("phase3=", boss.phase, " purpose=", boss.data.purpose, " player_hp=", game.player.hp)
	while game.dialogue_box.active:
		game.dialogue_box.chars_shown = 99999
		game.dialogue_box.advance()
		await get_tree().process_frame
	# kill
	boss.hp = 10
	boss.take_hit(50, boss.global_position + Vector2(100, 0), true)
	print("dying: state=", boss.state)
	for i in 800:
		game.player._iframes = 10.0
		if game.dialogue_box.active:
			game.dialogue_box.chars_shown = 99999
			game.dialogue_box.advance()
		if i % 100 == 0:
			print("frame ", i, " state_t=", snappedf(boss.state_t, 0.1), " state=", boss.state, " ts=", Engine.time_scale, " phys=", Engine.get_physics_frames())
		if boss.state == boss.DEAD:
			print("DEAD at frame ", i)
			break
		await get_tree().process_frame
	print("final: state=", boss.state, " defeated=", GameState.boss_defeated, " monument=", game.monument != null, " player_hp=", game.player.hp)
	get_tree().quit(0)
