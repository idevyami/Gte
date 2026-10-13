## WB-16 "The Ending's Record" proof — the floor keeps a memory of endings:
## the hollow's fall on the ash quarter (its last strides frozen mid-path,
## the sprawl where the body ended), the anatomy of a fall up close (the
## churn where the feet fought, the torso's settled mass, the head, the
## extremity streaks), the undercity pool that glistens while it is young
## and dries to a mineral ghost, the congregation's ending pressed into
## the chapel runner, the censor's leaving (a blank column through a
## written floor — even endings do not survive the correction), the
## vessel's own stain revisited after the count resumes (born aged), the
## Engine's maintained floor recording nothing — not even its dead, and
## two endings of different ages on one floor (the floor is information).
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

func _first_hollow() -> Hollow:
        for node in get_tree().get_nodes_in_group("enemies"):
                var h := node as Hollow
                if h and not h.dead:
                        return h
        return null

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

        # --- 1. THE HOLLOW'S ENDING: the ash quarter keeps where the walk
        #        stopped — the frozen last strides mid-path, and the sprawl
        #        where the body ended (the corpse caught mid-collapse above
        #        the record it just wrote)
        await _room("act3", Vector2(1150, 814))
        await _wait(3.0)
        var h1 := _first_hollow()
        var h1x := 1500.0
        if h1:
                h1x = h1.global_position.x
                h1.take_hit(9999, h1.global_position + Vector2(60.0, 0.0), true)
        await _wait(0.35)
        _frame(Vector2(h1x + 30.0, 842), 1.45)
        await _wait(0.15)
        await _snap("wb16_01_the_hollows_ending")

        # --- 2. THE SPRAWL: up close on the ending itself — the churn
        #        where the feet fought the floor, the torso's settled mass,
        #        the head past the leading end, the extremity streaks
        #        (the body has dissolved; only the record remains)
        await _wait(1.4)
        _frame(Vector2(h1x + 8.0, 846), 2.35)
        await _wait(0.15)
        await _snap("wb16_02_the_sprawl")

        # --- 3. THE POOL: the undercity's damp keeps the census of every
        #        boot — a body's ending is a POOL that glistens at its
        #        leading edge while it is young, then dries to a ghost
        await _room("act4", Vector2(640, 914))
        var py4 := game.player.global_position.y
        game.traces.stamp_fall(Vector2(700.0, py4 + 40.0), 1.0, 1.0, "vessel")
        game.traces.stamp_foot(Vector2(640.0, py4 + 24.0), 1.0)
        game.traces.stamp_foot(Vector2(668.0, py4 + 24.0), 1.0)
        _frame(Vector2(706.0, py4 + 34.0), 3.3)
        await _wait(0.15)
        await _snap("wb16_03_the_pool")

        # --- 4. THE CONGREGATION'S ENDING: harm one and all answer — in
        #        cloth; and when one ends on the runner, the pressed nap
        #        keeps it (light, matte, slow to rise)
        await _room("act5", Vector2(1150, 814))
        await _wait(1.4)
        game.player.global_position = Vector2(560.0, 814.0)
        game.player.velocity = Vector2.ZERO
        await _wait(0.2)
        _skip_dialogue()
        var b1: Believer = null
        for node in get_tree().get_nodes_in_group("enemies"):
                var b := node as Believer
                if b and not b.dead:
                        b1 = b
                        break
        if b1:
                b1._on_hurt()
        await _wait(1.1)
        var bx := 760.0
        if b1 and not b1.dead:
                bx = b1.global_position.x
                b1.take_hit(9999, b1.global_position + Vector2(40.0, 0.0), true)
        await _wait(0.45)
        _frame(Vector2(bx, 856), 2.15)
        await _wait(0.1)
        await _snap("wb16_04_the_congregations_ending")

        # --- 5. THE CENSOR'S LEAVING: even its ending is a correction —
        #        the column where it stood is blanked as it goes, through
        #        prints AND the ending they surround
        await _room("act3", Vector2(1150, 814))
        await _wait(2.4)
        await _walk("move_left", 1.7)
        var py3 := game.player.global_position.y
        var cx := game.player.global_position.x
        # the censor departs over the MIDDLE of the written trail — the
        # column cuts the record with prints surviving both sides
        var col_x := cx + 90.0
        game.traces.stamp_fall(Vector2(col_x, py3 + 40.0), -1.0, 1.0, "vessel")
        var co := Censor.new()
        co.position = Vector2(col_x, py3 - 280.0)
        game.world.add_child(co)
        co.life_t = 24.55
        await _wait(1.35)
        _frame(Vector2(col_x, py3 + 34.0), 1.62)
        await _wait(0.1)
        await _snap("wb16_05_the_censors_leaving")
        # let the censor finish its fade quietly
        await _wait(1.2)

        # --- 6. WHERE HE FELL: the vessel's own ending — the count ends,
        #        the count resumes, and the rebuilt ash wears the stain
        #        where he fell (born aged: the crossing back took time)
        game.player.global_position = Vector2(1000.0, 814.0)
        game.player.velocity = Vector2.ZERO
        await _wait(0.2)
        # no anchor stands in this run — clear any persisted record so the
        # count resumes in the room where it ended
        GameState.clear_save()
        var death_x := game.player.global_position.x
        var death_y := game.player.global_position.y
        game.player.take_damage(999, game.player.global_position + Vector2(40.0, 0.0))
        await _wait(7.0)
        _skip_dialogue()
        _frame(Vector2(death_x, death_y + 34.0), 1.7)
        await _wait(0.15)
        await _snap("wb16_06_where_he_fell")

        # --- 7. THE ENGINE RECORDS NOTHING — NOT EVEN ITS DEAD: a hollow
        #        ends on the maintained plating and the floor keeps no
        #        mark of it (the census already owns the count)
        await _room("act7", Vector2(600, 814))
        await _wait(2.2)
        var h7 := _first_hollow()
        var h7x := 900.0
        if h7:
                h7x = h7.global_position.x
                h7.take_hit(9999, h7.global_position + Vector2(60.0, 0.0), true)
        await _wait(0.4)
        _frame(Vector2(h7x, 840), 1.6)
        await _wait(0.1)
        await _snap("wb16_07_engine_records_nothing")

        # --- 8. TWO ENDINGS: one freshly written, one long held — the
        #        floor is information, dread from legibility (a fall held
        #        for most of its life reads as a ghost of the event; the
        #        fresh one reads dark and present)
        await _room("act3", Vector2(1000, 814))
        await _wait(2.0)
        game.traces.stamp_fall(Vector2(death_x - 70.0, 854.0), -1.0, 1.0, "vessel", 46.5)
        var h8 := _first_hollow()
        if h8:
                h8.global_position = Vector2(death_x + 130.0, 814.0)
                h8.velocity = Vector2.ZERO
                await _wait(0.25)
                h8.take_hit(9999, h8.global_position + Vector2(60.0, 0.0), true)
        await _wait(0.45)
        _frame(Vector2(death_x + 30.0, 852), 1.55)
        await _wait(0.1)
        await _snap("wb16_08_two_endings")

        print("WB-16 PROOFS DONE")
        get_tree().quit(0)
