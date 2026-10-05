## WB-9 "The Record Is A Thing" proof — the diegetic interface: the brass
## instrument cluster (dial + tube, clean / wounded / at the edge), the
## parchment census record (seal pressed, filing marks), the stamped
## citations, the ledger with its sealed rows, and the plaque.
extends Node

var game: Game
var main: Node

func _ready() -> void:
        DirAccess.make_dir_recursive_absolute("res://screenshots")
        GameState.clear_save()
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
        await _wait(0.6)
        # camera must SNAP onto its subject (proof law)
        if game.camera:
                game.camera.global_position = game.player.global_position

func _set_hp(hp: int) -> void:
        game.player.hp = hp
        await _wait(0.5)

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

        # 01 — THE INSTRUMENT: clean state, whole cluster
        await _room("act1", Vector2(640, 620))
        await _snap("wb9_01_instrument")

        # 02 — THE INSTRUMENT WOUNDED: cracked glass, crimson ghost drain
        await _set_hp(24)
        GameState.spend(30, "proof")   # 70 -> S2/S3 boundary territory
        await _wait(0.6)
        await _snap("wb9_02_instrument_wounded")

        # 03 — THE NEEDLE AT THE EDGE: S5 crimson dial, trembling hand
        GameState.spend(34, "proof")   # -> 36: S5
        await _set_hp(100)
        await _wait(0.8)
        await _snap("wb9_03_needle_edge")

        # restore for the document shots
        GameState.consistency = 100
        GameState._check_stage(100)
        game.player.hp = 100
        await _wait(0.3)

        # 04 — THE RECORD SPEAKS: parchment sheet, seal struck, ink mid-write
        game.dialogue_box.open("oren_intro")
        await _wait(0.55)
        await _snap("wb9_04_record_speaks")
        _skip_dialogue()
        await _wait(0.5)

        # 05 — THE FILING: the record's last line, continue mark breathing
        game.dialogue_box.open("oren_intro")
        game.dialogue_box.chars_shown = 99999
        await _wait(0.9)
        await _snap("wb9_05_filing")
        _skip_dialogue()
        await _wait(0.4)

        # 06 — THE OBJECTIONS: citations seated on the paper (one warn, one danger)
        game.system_log.entries.clear()
        game.system_log.push("FIELD MEASURED — DRIFT WITHIN TOLERANCE.", "warn")
        await _wait(0.5)
        game.system_log.push("OBJECTION FILED — REALITY CONTESTS THE EDIT.", "danger")
        await _wait(0.55)
        await _snap("wb9_06_objections")

        # 07 — THE LEDGER: the archive wall's own record page
        await _room("act6", Vector2(1250, 700))
        game.observe_enter()
        await _wait(0.6)
        await _snap("wb9_07_ledger")
        game.observe_exit()
        await _wait(0.3)

        # 08 — THE SEALED ROWS: the penitent's hidden properties under wax
        await _room("act9", Vector2(1280, 630))
        game.observe_enter()
        await _wait(0.6)
        await _snap("wb9_08_sealed_rows")
        game.observe_exit()
        await _wait(0.3)

        # 09 — THE RECEIPT: a modification answer stamped as a chit
        await _room("act2", Vector2(1440, 600))
        game.observe_enter()
        await _wait(0.4)
        game.observe_idx = _find("DOOR_029")
        game.observe_prop_idx = 0
        await _wait(0.2)
        game._modify_key()
        await _wait(0.35)
        await _snap("wb9_09_receipt")
        game.observe_exit()
        await _wait(0.2)

        # 10 — THE PLAQUE: the door answers with its verb on brass
        game.player.global_position = Vector2(1480, 600)
        await _wait(0.6)
        await _snap("wb9_10_plaque")
        get_tree().quit()

func _find(id_part: String) -> int:
        for i in game.observe_targets.size():
                var t = game.observe_targets[i]
                if t != null and is_instance_valid(t) and id_part in String(t.name) + String(t.get("instance_key")):
                        return i
        # fallback: match by entity data id_number
        for i in game.observe_targets.size():
                var t = game.observe_targets[i]
                if t != null and is_instance_valid(t) and t.data != null and id_part in t.data.id_number:
                        return i
        return 0
