## Visual proof — renders the REAL game (running scenes, live viewport) to
## PNGs for the 12 required gameplay proofs of the visual reconstruction pass.
## Runs under Xvfb with the actual rendering pipeline; no editor previews.
extends Node

var game: Game
var main: Node

func _ready() -> void:
        DirAccess.make_dir_recursive_absolute("res://screenshots")
        _run.call_deferred()

func _snap(name: String) -> void:
        # gameplay shot: no accumulated system chatter — the world stays quiet
        if game and game.system_log:
                game.system_log.entries.clear()
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        img.save_png("res://screenshots/" + name + ".png")
        print("SNAP ", name)

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true, false, true).timeout

func _reset_player(x: float, y: float) -> void:
        game.player.global_position = Vector2(x, y)
        game.player.velocity = Vector2.ZERO
        game.player.hp = game.player.max_hp

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
        game.player.global_position = pos
        game.player.velocity = Vector2.ZERO
        await _wait(0.6)
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
        await _wait(0.8)
        _skip_dialogue()

        # --- 09 · THE CITY OF ASH (player walking the procession street)
        await _room("act3", Vector2(1150, 840))
        game.player.facing = 1
        game.player.input_locked = false
        Input.action_press("move_right")
        await _wait(0.7)
        await _snap("09_city_of_ash")
        Input.action_release("move_right")

        # --- 01 · PLAYER (real walking gameplay toward the queue)
        Input.action_press("move_right")
        await _wait(0.55)
        Input.action_release("move_right")
        game.player.facing = 1
        await _wait(0.12)
        await _snap("01_player_gameplay")

        # --- 02 · THE HOLLOW (stalking, mid-distance)
        await _room("act3", Vector2(1420, 840))
        game.player.facing = 1
        await _wait(2.2)   # let it notice and stalk
        await _snap("02_hollow")

        # --- 03 · THE BELIEVERS (chapel, chanting at the ward)
        await _room("act5", Vector2(1240, 840))
        game.player.facing = 1
        await _wait(1.2)
        await _snap("03_believers")

        # --- 04 · THE CENSOR (reality correcting a deviation)
        await _room("act3", Vector2(1600, 840))
        GameState.consistency = 44
        GameState.stage = 4
        var censor := Censor.new()
        game.world.add_child(censor)
        censor.global_position = game.player.global_position + Vector2(430.0, -8.0)
        await _wait(0.9)
        _reset_player(1600, 840)
        game.player.facing = 1
        await _snap("04_censor")
        censor.queue_free()
        GameState.consistency = 100
        GameState.stage = 1

        # --- 05-07 · THE BOUND MARTYR — three phases
        await _room("act8", Vector2(620, 800))
        if game.boss:
                game.boss.begin_fight()
                game.player.facing = 1
                await _wait(1.4)
                _skip_dialogue()
                await _wait(1.0)
                _reset_player(620, 800)
                await _snap("05_martyr_p1")
                # force phase 2 (fervor)
                game.boss.hp = 560
                await _wait(1.2)
                _skip_dialogue()
                await _wait(1.4)
                _reset_player(620, 800)
                await _snap("06_martyr_p2")
                # force phase 3 (unchained)
                game.boss.hp = 260
                await _wait(1.2)
                _skip_dialogue()
                await _wait(1.4)
                _reset_player(620, 800)
                await _snap("07_martyr_p3")

        # --- 08 · THE PENITENT (the archive, watching)
        await _room("act6", Vector2(1900, 840))
        if game.penitent:
                game.penitent.visible_prop(true)
        game.player.facing = 1
        await _wait(0.8)
        await _snap("08_penitent")

        # --- 11 · THE ARCHIVE (the watching stacks)
        await _room("act6", Vector2(700, 840))
        game.player.facing = 1
        await _wait(0.6)
        await _snap("11_archive")

        # --- 12 · THE ENGINE SANCTUM
        await _room("act7", Vector2(1180, 840))
        game.player.facing = 1
        await _wait(0.8)
        await _snap("12_engine_sanctum")

        # --- 10 · THE CHAPEL OF THE PALE SAINT (wide)
        await _room("act5", Vector2(900, 840))
        game.player.facing = 1
        await _wait(0.6)
        await _snap("10_chapel")

        # --- 13 · PAINTED COLUMNS (act4 colonnade, 520-tall pairs)
        await _room("act4", Vector2(560, 940))
        game.player.facing = -1
        await _wait(0.6)
        await _snap("13_colonnade")

        # --- 14 · CHAPEL SANCTUARY (censer + mural + statue, painted)
        await _room("act5", Vector2(1250, 840))
        game.player.facing = -1
        await _wait(0.9)
        await _snap("14_sanctuary")

        # --- 15 · ENGINE MACHINES (painted reliquary engines, live gauges)
        await _room("act6", Vector2(560, 840))
        game.player.facing = -1
        await _wait(0.7)
        await _snap("15_machines")

        # --- 16 · MEASURER OREN (act3, the queue) + 17 · NULL CHILDREN (act4)
        await _room("act3", Vector2(760, 840))
        game.player.facing = 1
        await _wait(0.9)
        await _snap("16_measurer_oren")
        await _room("act4", Vector2(600, 940))
        game.player.facing = 1
        await _wait(0.9)
        await _snap("17_null_children")

        get_tree().quit()
