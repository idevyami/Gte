## WB-8 "The World Responds" proof — the wall-floor marriage (the skirting),
## the ground answering the fire (dancing pools + fixtures), the focal shafts
## of the dark districts, the moths that scatter from a passing body, the
## vermin that flee the vessel, the ripples where boots meet the weep spots,
## and the posted law that reads as a posted thing (never a debug box).
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

func _marker(at: Vector2) -> Node2D:
        ## A camera anchor the close-ups glue to (the flame, the vermin, the
        ## readable) — the WB-7 staging law: judge things at their own scale.
        var m := Node2D.new()
        m.position = at
        game.world.add_child(m)
        return m

func _zoom_on(m: Node2D, z: float) -> void:
        game.camera.target = m
        game.camera.zoom = Vector2(z, z)
        game.camera.zoom_target = z
        game.camera.zoom_speed = 8.0
        # SNAP the camera onto the subject — a smoothed travel across half
        # the room leaves the subject off-frame for the first half-second
        # (the vermin lesson: the camera must be where it claims to be)
        game.camera.position = m.global_position

func _zoom_off() -> void:
        game.camera.target = game.player
        game.camera.zoom_target = 1.0
        game.camera.zoom_speed = 3.0
        game.camera.zoom = Vector2.ONE

func _run() -> void:
        main = (load("res://main.tscn") as PackedScene).instantiate()
        get_tree().root.add_child(main)
        await get_tree().process_frame
        await get_tree().process_frame
        game = main.game
        GameState.clear_save()   # a stale smoke save must never hijack a respawn
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

        # --- 01 · THE MARRIAGE — skirting, pools, shafts: the seam the wall
        #     and the floor now share (city street, brazier district)
        await _room("act3", Vector2(780, 840))
        game.player.facing = 1
        await _wait(0.6)
        await _snap("wb8_01_the_marriage")

        # --- 02 · THE GROUND ANSWERS THE FIRE — the relic's cone light
        #     dancing on the chapel runner, fixtures grounding every glow
        await _room("act5", Vector2(1430, 840))
        game.player.facing = 1
        await _wait(0.6)
        await _snap("wb8_02_ground_answers_fire")

        # --- 03 · THE FOCAL SHAFT — the undercity's cold grate-light finally
        #     gives the dark corridor a focal point
        await _room("act2", Vector2(860, 620))
        await _wait(0.6)
        await _snap("wb8_03_focal_shaft")

        # --- 04a · MOTHS, SETTLED — pale wings orbiting the candle altar's
        #      flame (close-up staging: the flame's own scale)
        await _room("act5", Vector2(300, 840))
        var flame := _marker(Vector2(1200, 690))
        _zoom_on(flame, 2.2)
        await _wait(0.5)
        await _snap("wb8_04a_moths_settled")

        # --- 04b · MOTHS, SCATTERED — the vessel walks through the light
        #      and the air moves (within the 100px scatter radius of the flame)
        game.player.global_position = Vector2(1200, 775)
        game.player.velocity = Vector2.ZERO
        game.player.facing = 1
        await _wait(0.35)
        await _snap("wb8_04b_moths_scattered")
        _zoom_off()
        flame.queue_free()

        # --- 05a/05b · THE VERMIN — patrol, then flee the passing body
        #      (STAGED CLEAN: the vermin is parked at an open stretch of the
        #      back edge — the cage props would otherwise own the frame)
        await _room("act3", Vector2(300, 840))
        var scut: Dictionary = {}
        if game.world_life and game.world_life.scuttler_total() > 0:
                scut = game.world_life._scuttlers[0]
                scut["x"] = 1750.0
                scut["state"] = "patrol"
                var vermin := _marker(Vector2(1750.0, float(scut["y"]) - 4.0))
                _zoom_on(vermin, 3.0)
                game.player.global_position = Vector2(1490.0, 840)
                game.player.velocity = Vector2.ZERO
                await _wait(0.3)
                vermin.position = Vector2(float(scut["x"]), float(scut["y"]) - 4.0)
                await _snap("wb8_05a_vermin_patrol")
                # step into flight range — the city notices you
                game.player.global_position = Vector2(float(scut["x"]) - 120.0, 840)
                game.player.velocity = Vector2.ZERO
                await _wait(0.18)
                vermin.position = Vector2(float(scut["x"]), float(scut["y"]) - 4.0)
                await _snap("wb8_05b_vermin_flee")
                _zoom_off()
                vermin.queue_free()

        # --- 06 · THE RIPPLE — a boot lands in the undercity's weep spot
        #      (STAGING LAWS: the player stands ON the floor — an airborne
        #      body never footfalls; the weep spot is chosen AWAY from the
        #      terminal/props so the frame is floor + boot + water; the snap
        #      catches the ring MID-EXPANSION, where it reads)
        await _room("act2", Vector2(300, 660))
        var damp: Array = game.floorcraft.get_damp_spots()
        if not damp.is_empty():
                var spot: Dictionary = damp[0]
                for d in damp:
                        if float(d["x"]) > 950.0 and float(d["x"]) < 1450.0:
                                spot = d
                                break
                var rp := _marker(Vector2(float(spot["x"]), float(spot["y"]) - 26.0))
                _zoom_on(rp, 2.6)
                game.player.global_position = Vector2(float(spot["x"]) - 4.0, 660)
                game.player.velocity = Vector2.ZERO
                game.player.facing = 1
                game.player.input_locked = false
                await _wait(0.35)
                await get_tree().process_frame
                Input.action_press("move_right")
                for i in 120:
                        if game.world_life.ripple_count() > 0:
                                break
                        await get_tree().process_frame
                # a staged second footfall right on the weep spot, then catch
                # the ring at its brightest-wide moment (t ≈ 0.25)
                game.world_life._footfall(Vector2(float(spot["x"]), 660))
                await _wait(0.18)
                await _snap("wb8_06_ripple")
                Input.action_release("move_right")
                _zoom_off()
                rp.queue_free()

        # --- 07 · THE POSTED LAW — torn edge, iron nails, wax seal: a thing
        #      posted by an office, never a debug rectangle
        await _room("act2", Vector2(160, 660))
        var rd: Readable = null
        for ch in game.world.get_children():
                if ch is Readable and String(ch.entry.get("id", "")) == "r04_fundamental_one":
                        rd = ch
                        break
        if rd:
                var law := _marker(rd.position + Vector2(0, -32))
                _zoom_on(law, 2.6)
                await _wait(0.5)
                await _snap("wb8_07_posted_law")
                _zoom_off()
                law.queue_free()

        # --- 08 · THE RELIQUARY — gold seam in the footing, swept-polish
        #      floor, the arena's own light
        await _room("act8", Vector2(330, 814))
        game.player.facing = 1
        await _wait(0.6)
        await _snap("wb8_08_reliquary_goldline")

        print("PROOF WB8 DONE")
        get_tree().quit()
