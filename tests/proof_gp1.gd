## GP-1 THE FINAL FRAME — the ending surface audit. The title, the death card,
## the monument dialogue and the settlement screen have never been read by the
## VLM eye (the 207-bank holds gameplay, world and combat proofs; the frame a
## player leaves on — and the frame he arrives at — were never stills). Seven
## event-locked shots: the boot title, its glitch beat, a true staged death
## card, the SYSTEM's list-goes-down line at the monument, and the settlement
## screen in all three judgment variants (touched-nothing / spent-deeply /
## all-four-fragments). Real paths only: the death is a real take_damage, the
## monument is the real monument_read, the first end screen is the real
## _finish_game fired by the real dialogue finishing.
extends Node

var game: Game
var main: Node
var _shot := 0

func _ready() -> void:
        DirAccess.make_dir_recursive_absolute("res://screenshots/gp1")
        _run.call_deferred()

func _snap(name: String) -> void:
        ## frame_post_draw: the saved image is the frame JUST drawn — the
        ## state set before this call is guaranteed visible (awaiting
        ## process_frame captured the PREVIOUS frame's pixels)
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png("res://screenshots/gp1/%s.png" % name)
        _shot += 1
        print("GP1 STILL ", name, " saved")

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

func _run() -> void:
        # ================================================= THE ARRIVAL (2 shots)
        main = (load("res://main.tscn") as PackedScene).instantiate()
        get_tree().root.add_child(main)
        await get_tree().process_frame
        await get_tree().process_frame
        game = main.game
        await _wait(2.6)                     # ash drifts, the city settles
        await _snap("gp1_01_title")
        main.title._flicker = 1.0            # hold the glitch beat
        await _snap("gp1_02_title_glitch")

        # ================================================= A TRUE DEATH (1 shot)
        main.title.hide_screen()
        game.set_active(true)
        game.new_game()
        await _wait(1.0)
        _skip_dialogue()
        await _wait(0.3)
        await _wait_room("act9", Vector2(620, 700))
        # a real kill: the full death flow runs (card, zoom, stain, respawn)
        game.player.take_damage(999, game.player.global_position + Vector2(12.0, 0.0))
        await _wait(1.35)                    # the card holds, the lens looms
        await _snap("gp1_03_death_card")
        var t0 := Time.get_ticks_msec()      # wait out the respawn
        while Time.get_ticks_msec() - t0 < 12000:
                if game.state == "playing" and game.player.hp > 0:
                        break
                await get_tree().process_frame
        await _wait(0.5)

        # ================================================= THE MONUMENT (1 shot)
        game.player.global_position = Vector2(700, 700)
        game.player.velocity = Vector2.ZERO
        await _wait(0.5)
        game.monument_read()                 # the real ending dialogue
        await _wait(0.4)
        # reveal the second SYSTEM line fully — THE LIST GOES DOWN
        game.dialogue_box.chars_shown = 99999
        game.dialogue_box.advance()
        game.dialogue_box.chars_shown = 99999
        await _wait(0.35)
        await _snap("gp1_04_monument")
        _skip_dialogue()                     # finishing fires the real ending

        # ============================================ THE SETTLEMENT (3 shots)
        # variant one arrives by the true path — the stats this run earned
        await _wait(4.2)                     # question, ledger and footer all in
        await _snap("gp1_05_end_touched_nothing")
        # variant two — the deep spender (spent > 0, consistency <= 40)
        GameState.consistency = 38
        GameState.stage = E0.stage_for(38)
        var deep := {
                "edits": 9, "spent": 47, "deaths": 2, "dissipated": 1,
                "observed": 11, "texts": 21, "districts": 9, "elapsed": 2730,
        }
        game.end_screen.open(deep)
        await _wait(4.2)
        await _snap("gp1_06_end_spent_deeply")
        # variant three — the listener (4 fragments, consistency held above 40)
        GameState.consistency = 72
        GameState.stage = E0.stage_for(72)
        GameState.fragments = ["FRAGMENT_01", "FRAGMENT_02", "FRAGMENT_03", "FRAGMENT_04"]
        var listener := {
                "edits": 3, "spent": 12, "deaths": 0, "dissipated": 0,
                "observed": 14, "texts": 26, "districts": 9, "elapsed": 3186,
        }
        game.end_screen.open(listener)
        await _wait(4.2)
        await _snap("gp1_07_end_listened")

        print("GP-1 STILLS DONE (", _shot, ")")
        get_tree().quit(0)
