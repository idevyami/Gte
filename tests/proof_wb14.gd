## WB-14 "The Vessel's Trace" proof — the world's memory of the passage:
## the ash quarter's boot census (dark prints trailing the vessel, toe-kick
## piles), the undercity's wet prints that glisten while they dry, the
## landing scuff-star, the roll smear, the chapel's pressed nap, the
## archive's kicked record mid-flutter, and the Engine's maintained floor
## (walked, recorded nothing).
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
        game.camera.target = null
        game.camera.zoom = Vector2(z, z)
        game.camera.zoom_target = z
        game.camera.zoom_speed = 8.0
        game.camera.position = at
        game.camera.global_position = at

func _walk(dir_action: String, seconds: float) -> void:
        Input.action_press(dir_action)
        await _wait(seconds)
        Input.action_release(dir_action)
        await _wait(0.1)

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

        # --- 1. THE ASH PATH: the census of boots trailing the vessel
        #        through the ash quarter (the vessel at the head of his own
        #        record)
        await _room("act3", Vector2(240, 814))
        await _walk("move_right", 2.6)
        var px := game.player.global_position.x
        _frame(Vector2((240.0 + px) * 0.5, 775), 1.02)
        await _wait(0.2)
        await _snap("wb14_01_ash_path")

        # --- 2. THE TOE-KICK: close on fresh prints — dark compressions,
        #        ash piling at the trailing boot's toe
        _frame(Vector2(px - 70.0, 848), 2.4)
        await _wait(0.15)
        await _snap("wb14_02_ash_toe_kick")

        # --- 3. THE LANDING STAR: a hard fall's scuff-star radiating
        #        through the ash (staged on clear floor; the vessel then
        #        steps OUT of the frame so the mark reads unobstructed)
        game.player.global_position = Vector2(px + 240.0, 814)
        game.player.velocity = Vector2.ZERO
        await _wait(0.25)
        game.player.velocity.y = 560.0
        game.player.global_position.y -= 95.0
        await _wait(0.55)
        var land_x := game.player.global_position.x
        await _walk("move_right", 0.55)
        _frame(Vector2(land_x - 40.0, 852), 1.9)
        await _wait(0.1)
        await _snap("wb14_03_landing_star")

        # --- 4. THE ROLL SMEAR: the body grounds across the ash (framed
        #        after the vessel has rolled clear of his own mark)
        var roll_x := game.player.global_position.x
        game.player._roll_press = 0.14
        await _wait(0.5)
        await _walk("move_right", 0.5)
        _frame(Vector2(roll_x, 850), 2.0)
        await _wait(0.1)
        await _snap("wb14_04_roll_smear")
        await _wait(0.3)

        # --- 5. THE WET PRINTS: the undercity's weeping stone keeps the
        #        boot's dark print, glistening at the leading edge while
        #        it is still wet (framed well behind the vessel so the
        #        freshest prints read unobstructed)
        await _room("act2", Vector2(240, 634))
        await _walk("move_right", 1.8)
        _frame(Vector2(game.player.global_position.x - 130.0, 666), 2.1)
        await _wait(0.1)
        await _snap("wb14_05_wet_glisten")

        # --- 6. THE PRESSED NAP: the chapel's runner reads LIGHTER where
        #        the boots pressed it
        await _room("act5", Vector2(240, 814))
        await _walk("move_right", 1.6)
        _frame(Vector2(game.player.global_position.x - 120.0, 846), 2.1)
        await _wait(0.1)
        await _snap("wb14_06_chapel_nap")

        # --- 7. THE KICKED RECORD: a boot through the archive's litter
        #        sends a page tumbling (caught mid-flight)
        await _room("act6", Vector2(160, 814))
        var ps: Dictionary = game.floorcraft.get_page_spots()[0]
        game.player.global_position = Vector2(float(ps["x"]) - 42.0, 814)
        game.player.velocity = Vector2.ZERO
        await _wait(0.2)
        _skip_dialogue()
        var kicked := game.world_life.flutter_count()
        Input.action_press("move_right")
        var guard := 0
        while game.world_life.flutter_count() == kicked and guard < 240:
                await get_tree().process_frame
                guard += 1
        await _wait(0.22)      # the page rising through its arc
        Input.action_release("move_right")
        _frame(Vector2(float(ps["x"]) + 10.0, 826), 1.9)
        await get_tree().process_frame
        await _snap("wb14_07_page_flutter")
        await _wait(0.4)

        # --- 8. THE ENGINE RECORDS NOTHING: the same boots, the same walk,
        #        a floor that does not need to count
        await _room("act7", Vector2(240, 814))
        await _walk("move_right", 2.2)
        _frame(Vector2((240.0 + game.player.global_position.x) * 0.5, 780), 1.05)
        await _wait(0.15)
        await _snap("wb14_08_engine_clean")

        print("WB-14 PROOFS DONE")
        get_tree().quit(0)
