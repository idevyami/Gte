## Mini proof — clean-default OPTIONS overlay (no leftover smoke settings):
## fresh boot, act3, a save exists (anchor record), options at 100% defaults.
extends Node

func _ready() -> void:
        _run.call_deferred()

func _run() -> void:
        var main = (load("res://main.tscn") as PackedScene).instantiate()
        get_tree().root.add_child(main)
        await get_tree().process_frame
        await get_tree().process_frame
        var game: Game = main.game
        main.title.hide_screen()
        game.set_active(true)
        game.new_game()
        await get_tree().create_timer(0.8).timeout
        while game.dialogue_box.active:
                game.dialogue_box.chars_shown = 99999
                game.dialogue_box.advance()
                await get_tree().process_frame
        game.transition_to("act3")
        for i in 900:
                if game.room_id == "act3" and game.state == "playing":
                        break
                if game.dialogue_box.active:
                        game.dialogue_box.chars_shown = 99999
                        game.dialogue_box.advance()
                await get_tree().process_frame
        game.player.global_position = Vector2(980, 840)
        game.player.velocity = Vector2.ZERO
        await get_tree().create_timer(4.2).timeout
        while game.dialogue_box.active:
                game.dialogue_box.chars_shown = 99999
                game.dialogue_box.advance()
                await get_tree().process_frame
        # one anchor record exists, like a real mid-run pause
        GameState.save_game("act3", game.player.global_position, game.player.hp, "act3_anchor")
        game.player.input_locked = true
        var opts: OptionsScreen = main.options
        opts.open("pause")
        await get_tree().create_timer(0.6).timeout
        var img := get_viewport().get_texture().get_image()
        img.save_png("res://screenshots/22_options.png")
        print("SNAP 22_options")
        get_tree().quit()
