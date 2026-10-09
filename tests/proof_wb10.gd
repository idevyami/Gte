## WB-10 "The Air Itself" proof — THE SOUND MAP: every noise-making element
## the craft passes placed now speaks from its place. The debug overlay draws
## each positional emitter as a breathing halo inside its hearing radius, and
## each timed one-shot voice (drips, chains, bells) as a countdown arc — the
## aural landscape of each district made visible.
extends Node

var game: Game
var main: Node

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://screenshots")
	_run.call_deferred()

func _snap(name: String) -> void:
	if game and game.system_log:
		game.system_log.entries.clear()
		game.system_log.queue_redraw()
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

func _frame(at: Vector2, z := 1.0) -> void:
	## Snap the camera onto the sound cluster (the WB-8 staging law).
	game.camera.target = null
	game.camera.zoom = Vector2(z, z)
	game.camera.zoom_target = z
	game.camera.zoom_speed = 8.0
	game.camera.position = at
	game.camera.global_position = at

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

	# --- 1. THE IRON WOMB: the machines hum from their bolts, the vent hisses,
	#        the warm lights crackle where no brazier stands -----------------
	await _room("act1", Vector2(600, 900))
	game.soundscape.debug_draw = true
	_frame(Vector2(620, 780), 0.85)
	await _wait(0.6)
	await _snap("wb10_01_womb_sound_map")

	# --- 2. THE UNDERCITY: every damp spot keeps its own drip voice (the
	#        countdown arcs), the records shed their pages --------------------
	await _room("act2", Vector2(800, 560))
	game.soundscape.debug_draw = true
	_frame(Vector2(760, 520), 0.9)
	await _wait(0.6)
	await _snap("wb10_02_undercity_drip_arcs")

	# --- 3. THE CITY OF ASH: wind + the far murmur; the warm lights of the
	#        toll gate speak from their sconces ------------------------------
	await _room("act3", Vector2(900, 700))
	game.soundscape.debug_draw = true
	_frame(Vector2(900, 620), 0.8)
	await _wait(0.6)
	await _snap("wb10_03_city_far_field")

	# --- 4. THE CHAPEL: eleven flames speak — candles, candelabra, the
	#        swinging censer; the choir bed carries them ----------------------
	await _room("act5", Vector2(700, 700))
	game.soundscape.debug_draw = true
	_frame(Vector2(700, 640), 0.85)
	await _wait(0.6)
	await _snap("wb10_04_chapel_eleven_flames")

	# --- 5. THE ENGINE: the heart's deep hum, the gantry machines, the
	#        ringing plating under the boots ----------------------------------
	await _room("act7", Vector2(800, 700))
	game.soundscape.debug_draw = true
	_frame(Vector2(820, 640), 0.85)
	await _wait(0.6)
	await _snap("wb10_05_engine_the_heart_hums")

	# --- 6. THE RELIQUARY: the bell keeps its toll, the chains creak on
	#        their own time, the records whisper ------------------------------
	await _room("act8", Vector2(700, 700))
	game.soundscape.debug_draw = true
	_frame(Vector2(720, 640), 0.85)
	await _wait(0.6)
	await _snap("wb10_06_reliquary_bell_and_chains")

	print("WB-10 PROOFS DONE")
	get_tree().quit(0)
