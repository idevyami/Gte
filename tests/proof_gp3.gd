## GP-3 THE SECOND HAND — the gamepad experience audit. The pad was always
## playable (every action bound) but the world spoke only the keyboard's
## names: a plaque that said F to a hand holding A, a census that marked
## [TAB] for a stick that answers Y. Four event-locked shots on the surfaces
## this pass re-voiced: the interact plaque's keycap under both hands (A/F),
## the dialogue sheet's FILE stamp under the pad, and the reading panel's
## close hint under the pad. Real paths only: the plaque arrives by the true
## _scan_interact at the anchor, the dialogue by the true start_dialogue,
## the reading by the real open_reading.
extends Node

var game: Game
var main: Node
var _shot := 0

func _ready() -> void:
        DirAccess.make_dir_recursive_absolute("res://screenshots/gp3")
        _run.call_deferred()

func _snap(name: String) -> void:
        ## frame_post_draw: the saved image is the frame JUST drawn — the
        ## state set before this call is guaranteed visible
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png("res://screenshots/gp3/%s.png" % name)
        _shot += 1
        print("GP3 STILL ", name, " saved")

func _wait(t: float) -> void:
        var t0 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t0 < int(t * 1000.0):
                await get_tree().process_frame

func _wait_room(id: String, pos := Vector2(700, 700)) -> void:
        game.transition_to(id)
        var t0 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t0 < 12000:
                if game.room_id == id and game.state == "playing":
                        break
                if game.dialogue_box.active:
                        game.dialogue_box.chars_shown = 99999
                        game.dialogue_box.advance()
                await get_tree().process_frame
        for i in 600:
                if not game.cinema.is_showing():
                        break
                await get_tree().process_frame
        await _wait(0.5)
        game.player.global_position = pos
        game.player.velocity = Vector2.ZERO
        game.player.facing = 1
        await _wait(0.6)

func _skip_dialogue() -> void:
        while game.dialogue_box != null and game.dialogue_box.active:
                game.dialogue_box.chars_shown = 99999
                game.dialogue_box.advance()
                await get_tree().process_frame

func _find_readable(id: String) -> Readable:
        for ch in game.world.get_children():
                if ch is Readable and String(ch.entry.get("id", "")) == id:
                        return ch
        return null

func _find_anchor() -> Anchor:
        for ch in game.world.get_children():
                if ch is Anchor:
                        return ch
        return null

func _reseat_plaque() -> void:
        ## the plaque re-stamps on a 0.6s cycle (a fresh verb lands with
        ## weight) — seat a fresh cycle so the still never catches the
        ## between-stamps frame
        game.hud._prompt = ""
        game.hud.show_prompt(String(game._nearest_interactable.prompt))

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
        await _wait(0.3)

        # ======================================= THE PLAQUE UNDER BOTH HANDS
        # the vessel stands at act2's own anchor — the interact plaque
        # hangs over him, and the hand that last spoke names the key.
        await _wait_room("act2", Vector2(1804.0, 620.0))
        var anchor := _find_anchor()
        if anchor == null:
                print("GP3 ERROR: no anchor in act2")
                get_tree().quit(1)
                return
        game.player.global_position = anchor.global_position + Vector2(-46.0, 0.0)
        await _wait(0.8)     # let _scan_interact seat the plaque
        if game._nearest_interactable != anchor:
                print("GP3 ERROR: plaque not seated at the anchor")
                get_tree().quit(1)
                return
        # the pad spoke last — the keycap must carry its own button
        GameState.pad_last = true
        _reseat_plaque()
        await _wait(0.25)
        await _snap("gp3_01_plaque_pad")
        # the keyboard spoke last — the same plaque, its own key
        GameState.pad_last = false
        _reseat_plaque()
        await _wait(0.25)
        await _snap("gp3_02_plaque_kb")

        # ======================================= THE SHEET FILES UNDER THE PAD
        # the dialogue's continue mark: FILE [A] when the pad holds the vessel
        game.start_dialogue("sys_intro")
        await _wait(0.4)
        game.dialogue_box.chars_shown = 99999    # the line complete — the stamp shows
        GameState.pad_last = true
        await _wait(0.2)
        # the FILE stamp blinks on a 0.9s cycle — catch it solidly visible
        for i in 30:
                if fmod(game.dialogue_box._blink, 0.9) < 0.45:
                        break
                await get_tree().process_frame
        await _snap("gp3_03_dialogue_pad")
        game.dialogue_box.advance()
        _skip_dialogue()
        await _wait(0.4)

        # ======================================= THE READING CLOSES UNDER THE PAD
        # the reading panel's footer: A / Y — CLOSE for the pad's hand
        var r05 := _find_readable("r05_procession")
        if r05 == null:
                print("GP3 ERROR: r05 not found in act2")
                get_tree().quit(1)
                return
        game.player.global_position = r05.global_position + Vector2(-40.0, 0.0)
        await _wait(0.4)
        game.open_reading(r05)                    # the real reading flow
        await _wait(0.35)
        game.reading_panel._chars = 1.0e9         # finish the carving
        game.reading_panel._margin_t = 1.0
        GameState.pad_last = true
        await _wait(0.5)
        await _snap("gp3_04_reading_pad")
        game.reading_panel.close()
        await _wait(0.4)

        print("GP-3 STILLS DONE (", _shot, ")")
        get_tree().quit(0)
