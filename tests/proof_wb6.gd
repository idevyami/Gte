## WB-6 "The Ground You Walk On" proof — the rendered climb ledges (the
## invisible-platform fix, before/after), the crafted floor surfaces per
## district, the contact shadows (grounded / airborne), the arch interior
## fills, the midground inner structure, and the dried-blood heart.
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

func _settle(pos: Vector2, t := 0.6) -> void:
        ## teleport + let the world settle: triggers fire their dialogues,
        ## the camera catches up, then the frame is clean for capture
        game.player.global_position = pos
        game.player.velocity = Vector2.ZERO
        await _wait(0.3)
        await _skip_dialogue()
        for i in 300:
                if game.state == "playing":
                        break
                if game.dialogue_box.active:
                        game.dialogue_box.chars_shown = 99999
                        game.dialogue_box.advance()
                await get_tree().process_frame
        await _wait(t)

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

func _run() -> void:
        main = (load("res://main.tscn") as PackedScene).instantiate()
        get_tree().root.add_child(main)
        await get_tree().process_frame
        await get_tree().process_frame
        game = main.game
        main.title.hide_screen()
        game.set_active(true)
        game.new_game()
        for i in 900:
                if game.room_id == "act1" and game.state == "playing":
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

        # --- THE MONEY SHOT: the act1 ascent, before and after -----------
        # "before": the world as it was — collision-only climb (ledges off)
        game.player.global_position = Vector2(700, 960)
        game.player.velocity = Vector2.ZERO
        await _wait(0.7)
        _skip_dialogue()
        game.floorcraft.visible = false
        await _wait(0.2)
        _snap("wb6_00_climb_before")
        # "after": the ground you walk on
        game.floorcraft.visible = true
        await _wait(0.2)
        _snap("wb6_01_climb_ledges")
        # closer: standing ON a ledge, mid-ascent
        await _settle(Vector2(1180, 770))
        await _snap("wb6_01b_on_the_ledge")

        # --- city: the pilgrimage wear path + plaques + shadow grounded ---
        await _room("act3", Vector2(900, 920))
        await _wait(0.4)
        _snap("wb6_02_city_wear_path")
        # airborne: the shadow stays on the ground, reads smaller
        game.player.velocity.y = E0.P_JUMP
        game.player._coyote = 0.0
        await _wait(0.22)
        _snap("wb6_03_shadow_airborne")
        await _wait(0.8)
        _snap("wb6_03b_shadow_grounded")

        # --- chapel: runner carpet, mosaic border, arch interiors --------
        # (stand between the two candle lights — the gold work needs light)
        await _room("act5", Vector2(1250, 814))
        await _wait(0.4)
        await _snap("wb6_04_chapel_carpet")

        # --- undercity: damp stains + drainage grates --------------------
        # (under the cyan lamp — wet steel reads only in light)
        await _room("act2", Vector2(1000, 634))
        await _wait(0.4)
        await _snap("wb6_05_undercity_damp")

        # --- archive: fallen records on stone ----------------------------
        # (under the registry lamp — the pages catch the cyan light)
        await _room("act6", Vector2(700, 814))
        await _wait(0.4)
        await _snap("wb6_06_archive_pages")

        # --- engine: steel plates + rivets + hazard + dried heart --------
        await _room("act7", Vector2(1560, 810))
        await _wait(0.4)
        await _snap("wb6_07_engine_plates")
        await _settle(Vector2(1900, 810))
        await _snap("wb6_08_heart_dried")

        # --- reliquary: gold seam inlays + polish ------------------------
        await _room("act8", Vector2(640, 814))
        await _wait(0.4)
        await _snap("wb6_09_reliquary_inlay")

        # --- aftermath: the broken ground --------------------------------
        await _room("act9", Vector2(700, 620))
        await _wait(0.4)
        await _snap("wb6_10_aftermath_broken")

        print("WB6 PROOFS DONE")
        get_tree().quit(0)
