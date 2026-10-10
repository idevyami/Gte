## WB-12 "The World Thins" proof — the diegetic atmosphere response to the
## HUNTED stages. As consistency drains, the world's renderers lose
## conviction together: the flames gutter, agitate and MISS BEATS (the
## ground dropping in the same breath), the air chills (motes dim, mist
## gathers, ash falls straighter), the moths LEAVE FIRST (a staggered wave,
## then the flames stand alone), the god-rays pale, the grade drains while
## the vessel keeps his presence — and every frame stays READABLE (the
## legibility floor). Chapel (eleven flames + moth orbits) and undercity
## (focal shafts + gathered haze) at authored thinnings.
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

func _thin_at(v: float, settle := 0.35) -> void:
        ## Pin the world to an authored thinning and let the renderers
        ## settle into it (misses are live — they land within the settle).
        GameState.force_thinning(v)
        await _wait(settle)

func _snap_mid_miss(name: String, min_misses := 3, max_t := 4.0) -> void:
        ## Wait until several living flames are INSIDE missed beats at once
        ## (the stagger must READ in a still: some guttering low while their
        ## neighbours hold), then snap.
        var t := 0.0
        while t < max_t:
                var n := 0
                for i in game.lights.lights.size():
                        var l: Dictionary = game.lights.lights[i]
                        if float(l.get("flicker", 0.0)) > 0.15 and game.lights.thinning_factor(i) < 0.5:
                                n += 1
                if n >= min_misses:
                        break
                t += 0.05
                await _wait(0.05)
        await _snap(name)

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

        # --- 1..3. THE CHAPEL: eleven flames, moths on their orbits ------
        #        home → half-thinned (conviction loss, the first moths gone)
        #        → full thin (miss mid-beat, flames standing alone)
        await _room("act5", Vector2(700, 800))
        _frame(Vector2(760, 560), 0.78)
        await _thin_at(0.0, 1.0)
        await _snap("wb12_01_chapel_home")
        await _thin_at(0.55, 1.0)
        await _snap("wb12_02_chapel_thinning")
        await _thin_at(1.0, 1.2)
        await _snap_mid_miss("wb12_03_chapel_thin")

        # --- 4. THE LEAVING: mid-departure — moths in flight, fading out
        #        (th past every nerve, caught ~0.45s into the exodus)
        await _thin_at(0.0, 2.4)      # let them all come home first
        await _thin_at(0.85, 0.45)
        await _snap("wb12_04_moths_leaving")

        # --- 5. THE VESSEL STAYS REAL: full thin, wide — the drained grade
        #        and pale rays against a present, rim-lit protagonist
        await _thin_at(1.0, 1.0)
        _frame(Vector2(760, 640), 0.9)
        await _snap("wb12_05_chapel_vessel_stays_real")

        # --- 6..7. THE UNDERCITY: focal shafts pale, the haze gathers,
        #        the grate-light gutters ----------------------------------
        await _room("act2", Vector2(640, 700))
        _frame(Vector2(640, 560), 0.8)
        await _thin_at(0.0, 1.0)
        await _snap("wb12_06_undercity_home")
        await _thin_at(1.0, 1.2)
        await _snap_mid_miss("wb12_07_undercity_thin")

        GameState.force_thinning(-1.0)
        print("WB-12 PROOFS DONE")
        get_tree().quit(0)
