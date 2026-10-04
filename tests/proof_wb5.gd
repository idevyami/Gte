## WB-5 "The Closest Walls" proof — the near-camera silhouette plane, the
## censor's full performance (unfurl / hover / reach / shed pages), the null
## children's glitch-step, the district climates, the slide comparison.
## Rendered under Xvfb like the other proof scenes.
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

func _walk(dx: float, t: float) -> void:
        ## hold move_right/left for t seconds — the parallax slide proof
        var a := "move_right" if dx > 0.0 else "move_left"
        Input.action_press(a)
        await _wait(t)
        Input.action_release(a)
        game.player.velocity = Vector2.ZERO
        await _wait(0.25)

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

        # WB5-00 · act3 WITHOUT the foreground (the A/B reference frame)
        await _room("act3", Vector2(700, 814))
        OS.set_environment("E0_NO_FOREGROUND", "1")
        await _wait(0.4)
        await _snap("wb5_00_city_no_fg")
        OS.set_environment("E0_NO_FOREGROUND", "")

        # WB5-01 · act3 WITH the closest walls: shingles, rags, the near lamp —
        # the same street now has a front face
        await _wait(0.4)
        await _snap("wb5_01_city_closest_walls")

        # WB5-02 · the slide: walk left through the district — the near plane
        # overtakes the architecture behind it (two phases)
        await _walk(-420.0, 2.2)
        await _snap("wb5_02a_slide_mid")
        await _walk(-420.0, 2.2)
        await _snap("wb5_02b_slide_late")

        # WB5-03 · act1: the womb's sky band — cables, chains, a hanging
        # shroud ABOVE the climb (never across it), amber grade
        await _room("act1", Vector2(700, 974))
        await _wait(1.2)
        await _snap("wb5_03_womb_sky_band")

        # WB5-04 · act2: the undercity's near grates breathing, lamps leaning in
        await _room("act2", Vector2(1000, 634))
        await _wait(1.0)
        await _snap("wb5_04_undercity_grates")

        # WB5-05 · act4: null children glitch-step through the foreground —
        # outside classification, outside the walls
        await _room("act4", Vector2(900, 880))
        await _wait(1.6)
        await _snap("wb5_05_null_walk")

        # WB5-06 · act5: the chapel's near censer + column stump, candle gold
        await _room("act5", Vector2(640, 814))
        await _wait(1.4)
        await _snap("wb5_06_chapel_censer")

        # WB5-07 · act6: the archive's page curtain — records falling in public
        await _room("act6", Vector2(700, 814))
        await _wait(1.2)
        await _snap("wb5_07_archive_pages")

        # WB5-08 · act7: gantry stumps + breathing cables over the works, furnace grade
        await _room("act7", Vector2(900, 814))
        await _wait(1.0)
        await _snap("wb5_08_engine_gantry")

        # WB5-09 · act8: the martyr's arena — center OPEN, only sky hangs
        await _room("act8", Vector2(640, 814))
        await _wait(1.2)
        await _snap("wb5_09_reliquary_arena")

        # WB5-10 · act9: aftermath rubble + torn rags, cooling gold
        await _room("act9", Vector2(640, 634))
        await _wait(1.0)
        await _snap("wb5_10_aftermath_rubble")

        # WB5-11 · THE CENSOR — unfurling into place (mid-arrive), pages already
        # leaving it
        await _room("act2", Vector2(900, 634))
        var c := Censor.new()
        game.world.add_child(c)
        c.global_position = game.player.global_position + Vector2(230, -20)
        await get_tree().process_frame
        await get_tree().process_frame
        await _wait(0.14)
        await _snap("wb5_11_censor_unfurl")

        # WB5-12 · the censor's correction lean — reach frames + shed pages trail.
        # Park it ON the player so contact fires, snap inside the 0.3s window.
        for i in 240:
                if c._pose == "idle":
                        break
                await get_tree().process_frame
        c.contact_cd = 0.0
        c.global_position = game.player.global_position + Vector2(18, 0)
        await _wait(0.12)
        await _snap("wb5_12_censor_reach")
        c.queue_free()

        print("WB5 PROOFS DONE")
        get_tree().quit(0)
