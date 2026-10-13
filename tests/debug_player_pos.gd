## Debug — locate the player on screen in the exact visual_proof 01 flow,
## and probe pixels at his position (aura warmth / rim brightness check).
extends Node

func _ready() -> void:
        _run.call_deferred()

func _skip_dlg(game) -> void:
        while game.dialogue_box.active:
                game.dialogue_box.chars_shown = 99999
                game.dialogue_box.advance()
                await get_tree().process_frame

func _run() -> void:
        var main = (load("res://main.tscn") as PackedScene).instantiate()
        get_tree().root.add_child(main)
        await get_tree().process_frame
        await get_tree().process_frame
        var game = main.game
        main.title.hide_screen()
        game.set_active(true)
        game.new_game()
        await get_tree().create_timer(0.8).timeout
        await _skip_dlg(game)
        game.transition_to("act3")
        for i in 900:
                if game.room_id == "act3" and game.state == "playing":
                        break
                if game.dialogue_box.active:
                        game.dialogue_box.chars_shown = 99999
                        game.dialogue_box.advance()
                await get_tree().process_frame
        for i in 900:
                if not game.cinema.is_showing():
                        break
                await get_tree().process_frame
        await get_tree().create_timer(0.6).timeout
        game.player.global_position = Vector2(1150, 840)
        game.player.velocity = Vector2.ZERO
        await get_tree().create_timer(0.6).timeout
        await _skip_dlg(game)
        await get_tree().create_timer(0.3).timeout
        game.player.facing = 1
        game.player.input_locked = false
        Input.action_press("move_right")
        await get_tree().create_timer(0.7).timeout
        Input.action_release("move_right")
        Input.action_press("move_right")
        await get_tree().create_timer(0.55).timeout
        Input.action_release("move_right")
        game.player.facing = 1
        await get_tree().create_timer(0.12).timeout
        var pp: Vector2 = game.player.global_position
        var cp: Vector2 = game.camera.global_position
        var sx := int(pp.x - cp.x + 640.0)
        var sy := int(pp.y - cp.y + 360.0)
        print("PLAYER_POS ", pp, " CAM ", cp, " SCREEN ", sx, ",", sy)
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        var warm := 0
        var rim := 0
        for dy in range(-70, 71, 2):
                for dx in range(-70, 71, 2):
                        var c := img.get_pixel(clampi(sx + dx, 0, 1279), clampi(sy + dy, 0, 719))
                        if c.r > c.b + 0.08 and c.r > 0.35:
                                warm += 1
                        if c.r > 0.55 and c.g > 0.5 and c.b > 0.4:
                                rim += 1
        print("WARM_PX ", warm, " RIM_PX ", rim)
        for dy in [-60, -40, -20, 0, 20]:
                var p := img.get_pixel(clampi(sx, 0, 1279), clampi(sy + dy, 0, 719))
                print("PROBE dy=", dy, " ", p)
        get_tree().quit()
