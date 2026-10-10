## WB-11 "The Arrival" proof — the room-entry wake. No space is born
## pre-lit: when the vessel steps through, the lights catch near-first,
## each catch flares then settles, the ground answers in the same breath,
## the air condenses into presence, and the held-dark grade exhales. The
## iron womb (the first room the player ever sees) and the chapel (eleven
## flames) are caught mid-wake at authored wake.t moments.
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

func _wake_at(t: float, settle := 0.05) -> void:
        ## Pin the wake to an authored moment and let one redraw land.
        game.wake.t = t
        await _wait(settle)
        _skip_dialogue()

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

        # --- 1..4. THE IRON WOMB: the first room the player ever sees —
        #        the wake sweeps up the ascent shaft from the cradle floor
        #        (light order: cradle 850y -> mid shaft 620y -> top 130y) --
        await _room("act1", Vector2(300, 950))
        _frame(Vector2(700, 700), 0.72)
        await _wake_at(0.02)
        await _snap("wb11_01_womb_dark")
        await _wake_at(0.30)
        await _snap("wb11_02_womb_catching")
        await _wake_at(1.02)
        await _snap("wb11_03_womb_sweep")
        await _wake_at(3.2)
        await _snap("wb11_04_womb_awake")

        # --- 5..6. THE CHAPEL: eleven flames catch one by one across the
        #        nave; the pools arrive with their flames --------------------
        await _room("act5", Vector2(700, 800))
        _frame(Vector2(760, 560), 0.78)
        await _wake_at(0.42)
        await _snap("wb11_05_chapel_catching")
        await _wake_at(3.2)
        await _snap("wb11_06_chapel_awake")

        print("WB-11 PROOFS DONE")
        get_tree().quit(0)
