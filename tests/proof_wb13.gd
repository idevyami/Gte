## WB-13 "The Threshold" proof — the crossing between acts. The space
## between two worlds is not nothing: the leaving (the world folds to
## black while the vessel keeps walking), the between (the census rubric
## inscribes glyph by glyph on the dark; the arriving space's herald is
## heard through it), the coming (the fade opens into the new room's
## wake). Caught at authored threshold.t moments, plus the handoff into
## the chapel's arrival.
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

func _fade_alpha(a: float) -> void:
        ## Pin the screen fold open/closed to an authored amount (synthetic
        ## mid-beat states for the proof frames).
        FX._fade_rect.color.a = a

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

        # --- 1. THE LEAVING: the womb folds to black around the vessel at
        #        the ascent's gate (mid-fold, the last lit frame)
        await _room("act1", Vector2(1480, 210))
        _frame(Vector2(1200, 320), 0.85)
        await _wait(0.3)
        _fade_alpha(0.55)
        await get_tree().process_frame
        await _snap("wb13_01_leaving_mid_fold")

        # --- 2..3. THE BETWEEN: the census rubric inscribes itself on the
        #        black — letters arriving left to right with gold echoes,
        #        then the full line risen with its rule and brackets
        _fade_alpha(1.0)
        game.threshold = Threshold.make("act1", "act2", true)
        game.threshold.t = game.threshold.LEAVE + 0.18 + game.threshold.RISE * 0.45
        await get_tree().process_frame
        await get_tree().process_frame
        await _snap("wb13_02_between_inscribing")
        game.threshold.t = game.threshold.black_end() - 0.34
        await get_tree().process_frame
        await get_tree().process_frame
        await _snap("wb13_03_between_risen")
        game.threshold = null
        _fade_alpha(0.0)

        # --- 4..5. THE COMING: the fade opens into the chapel's own wake —
        #        the crossing hands the lens to the arrival (WB-11)
        await _room("act5", Vector2(700, 800))
        _frame(Vector2(760, 560), 0.78)
        game.wake.t = 0.42
        await _wait(0.05)
        _skip_dialogue()
        _fade_alpha(0.45)
        await get_tree().process_frame
        await _snap("wb13_04_coming_into_the_wake")
        _fade_alpha(0.0)
        game.wake.t = 3.2
        await _wait(0.05)
        _skip_dialogue()
        await _snap("wb13_05_settled")

        print("WB-13 PROOFS DONE")
        get_tree().quit(0)
