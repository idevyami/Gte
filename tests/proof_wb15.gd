## WB-15 "The Others' Passage" proof — the floor's memory is not one-sided:
## the ash quarter written by two hands (the vessel's dark conviction beside
## the hollow's lighter metronome echo), the chapel's devotion field of
## pre-aged knee-press stations, the believers' soft shuffle, the bound
## martyr's heavy press and its leap's bruise, the Engine's maintained floor
## (patrolled by hollows, recorded nothing), the censor's blank column
## through a written floor, and the trail that reads its own age.
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

        # --- 1. TWO HANDS ON ONE FLOOR: the ash quarter carrying both the
        #        vessel's dark-conviction boots and the hollow's lighter
        #        echo (let the patrol write first, then walk through it)
        await _room("act3", Vector2(1150, 814))
        await _wait(3.2)
        await _walk("move_right", 2.4)
        var px := game.player.global_position.x
        _frame(Vector2((1150.0 + px) * 0.5, 780), 1.04)
        await _wait(0.2)
        await _snap("wb15_01_two_hands")

        # --- 2. THE ECHO: close on the crossing — the vessel's fresh dark
        #        impression beside the hollow's same-sole lighter press
        _frame(Vector2(px - 90.0, 850), 2.2)
        await _wait(0.15)
        await _snap("wb15_02_the_echo")

        # --- 3. THE DEVOTION FIELD: the chapel runner carrying the
        #        congregation's pre-aged knee-press stations (pressed before
        #        the vessel ever walked in)
        await _room("act5", Vector2(1150, 814))
        await _wait(1.6)
        _frame(Vector2(1450.0, 848), 1.55)
        await _wait(0.15)
        await _snap("wb15_03_devotion_field")

        # --- 4. THE SHUFFLE: harm one and all answer — the believers come
        #        in cloth, soft narrow soles writing the runner as they come
        game.player.global_position = Vector2(560.0, 814)
        game.player.velocity = Vector2.ZERO
        await _wait(0.2)
        _skip_dialogue()
        var walker: Believer = null
        for node in get_tree().get_nodes_in_group("enemies"):
                var b := node as Believer
                if b and not b.dead:
                        walker = b
                        break
        if walker:
                walker._on_hurt()
        await _wait(1.5)
        if walker:
                _frame(Vector2(walker.global_position.x + 60.0, 842), 1.75)
        else:
                _frame(Vector2(700.0, 842), 1.75)
        await _wait(0.1)
        await _snap("wb15_04_the_shuffle")
        await _wait(0.3)

        # --- 5. THE WEIGHT OF THE BOUND: the martyr's arena floor keeps
        #        its battle — deep wide presses where it walked, a bruise
        #        where it landed
        game.player.hp = 400
        await _room("act8", Vector2(450, 800))
        await _wait(0.3)
        _skip_dialogue()
        await _wait(4.2)
        var boss: BoundMartyr = game.boss
        if boss:
                _frame(Vector2(boss.global_position.x - 120.0, 846), 1.6)
        else:
                _frame(Vector2(850.0, 846), 1.6)
        await _wait(0.15)
        await _snap("wb15_05_martyr_weight")
        await _wait(0.3)

        # --- 6. THE ENGINE RECORDS NOTHING: a hollow mid-patrol on the
        #        maintained floor — it has walked for seconds and the floor
        #        keeps no mark of it
        await _room("act7", Vector2(600, 814))
        await _wait(2.6)
        var patroller: Hollow = null
        for node in get_tree().get_nodes_in_group("enemies"):
                var h := node as Hollow
                if h and not h.dead:
                        patroller = h
                        break
        if patroller:
                _frame(Vector2(patroller.global_position.x - 90.0, 838), 1.6)
        else:
                _frame(Vector2(900.0, 838), 1.6)
        await _wait(0.15)
        await _snap("wb15_06_engine_clean")
        await _wait(0.3)

        # --- 7. THE ERASURE: the censor crosses a written floor — where it
        #        passed, the record is blank (spawned over the ash field the
        #        two hands wrote, drifting toward the vessel)
        await _room("act3", Vector2(1150, 814))
        await _wait(2.6)
        await _walk("move_right", 1.6)
        var field_r := game.player.global_position.x
        game.player.global_position = Vector2(field_r + 420.0, 814)
        game.player.velocity = Vector2.ZERO
        await _wait(0.2)
        var censor := Censor.new()
        censor.position = Vector2(field_r - 480.0, 640.0)
        game.world.add_child(censor)
        await _wait(3.4)
        _frame(Vector2(censor.global_position.x + 60.0, 840), 1.7)
        await _wait(0.1)
        await _snap("wb15_07_the_erasure")

        # --- 8. THE TRAIL READS ITS OWN AGE: the same metronome hand,
        #        fresh and dark where it stepped now, pale where it stepped
        #        long ago (the floor is information)
        var hollow2: Hollow = null
        for node in get_tree().get_nodes_in_group("enemies"):
                var h2 := node as Hollow
                if h2 and not h2.dead:
                        hollow2 = h2
                        break
        if hollow2:
                _frame(Vector2(hollow2.patrol_from + 40.0, 848), 1.9)
        else:
                _frame(Vector2(1600.0, 848), 1.9)
        await _wait(0.15)
        await _snap("wb15_08_age_gradient")

        print("WB-15 PROOFS DONE")
        get_tree().quit(0)
