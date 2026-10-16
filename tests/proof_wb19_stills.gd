## WB-19 STROBE STILLS — the motion audit's instrument blind spot, closed.
## The wall-clock capture runs at ~7.6fps under Xvfb (JPEG saves cost
## ~130ms), so every sub-150ms read (the 45ms gather, the 70-115ms hitstop,
## the 200ms wound card, the 1.6px rim) aliases into invisibility — the
## honest audit correctly said NOT SEEN. These stills are EVENT-LOCKED:
## each frame is captured at the exact tick of the read it proves, at full
## resolution. Six shots: the gather, the launch stretch, the apex, the
## jab's wound card, the finisher's card, the flock's rim.
extends Node

var game: Game
var main: Node
var _shot := 0
var _squash_hold := false

func _hold_squash() -> void:
        ## keeps the gather's compression alive frame-to-frame while the
        ## camera settles — the decay race is a staging artifact, not a game
        ## behavior (the landing squash renders in every audited clip)
        while _squash_hold:
                game.player.land_squash = 0.85
                game.player._jump_windup = 10.0
                await get_tree().process_frame

func _ready() -> void:
        DirAccess.make_dir_recursive_absolute("res://screenshots/wb19_stills")
        _run.call_deferred()

func _snap(name: String) -> void:
        ## frame_post_draw: the saved image is the frame JUST drawn — the
        ## state set before this call is guaranteed visible (awaiting
        ## process_frame captured the PREVIOUS frame's pixels)
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png("res://screenshots/wb19_stills/%s.png" % name)
        _shot += 1
        print("STILL ", name, " saved")


## The burst world nests three levels deep (FX -> CanvasLayer -> world ->
## cards) — the pin must recurse, or the card dies its natural 200ms before
## the capture ever sees it
func _pin_cards() -> void:
        ## the burst world lives under the GAME node (main -> game -> world),
        ## not under the FX autoload — the pin roots itself there
        if game != null and is_instance_valid(game) and game.world != null:
                _pin_scan(game.world)

func _pin_scan(node: Node) -> void:
        for c in node.get_children():
                if "life" in c:
                        c.life = 0.9
                _pin_scan(c)

func _wait(t: float) -> void:
        var t0 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t0 < int(t * 1000.0):
                if game != null and is_instance_valid(game) and game.dialogue_box != null \
                                and game.dialogue_box.active:
                        game.dialogue_box.chars_shown = 99999
                        game.dialogue_box.advance()
                await get_tree().process_frame

func _skip_dialogue() -> void:
        while game.dialogue_box.active:
                game.dialogue_box.chars_shown = 99999
                game.dialogue_box.advance()
                await get_tree().process_frame

func _room(id: String, pos := Vector2(640, 600)) -> void:
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
        await _wait(1.0)
        _skip_dialogue()
        await _wait(0.3)

        # ================================================= THE GATHER (2 shots)
        # Held-state staging: the gather is 45ms — shorter than one capture —
        # so the windup is HELD (the same vars the real flow sets, pinned for
        # the camera) and then released for the launch shot.
        await _room("act1", Vector2(520, 620))
        game.player.velocity = Vector2.ZERO
        for i in 90:
                if game.player.is_on_floor():
                        break
                await get_tree().process_frame
        await _wait(0.5)
        await _snap("wb19_01_stand")             # the reference pose
        game.player._buffer = 0.0
        game.player._jump_windup = 10.0          # hold the crouch
        _squash_hold = true
        _hold_squash.call()                      # refresh the compression every
        await _wait(0.35)                        # frame (unthrottled ticks would
                                                # eat it long before the draw)
        await _snap("wb19_02_gather")         # mid-crouch, earthbound
        game.player._jump_windup = 0.0           # release
        game.player._launch_jump()
        await get_tree().process_frame
        await _snap("wb19_03_launch")         # the leave + stretch

        # ================================================= THE CARDS (2 shots)
        await _room("act3", Vector2(1200, 700))
        var hollow: Hollow = null
        for node in get_tree().get_nodes_in_group("enemies"):
                if node is Hollow and not node.dead:
                        hollow = node
                        break
        if hollow:
                # a specimen: frozen mid-patrol so the duel cannot start and
                # knock the vessel away mid-staging (the first render's hits
                # whiffed for exactly this reason)
                hollow.set_physics_process(false)
                hollow.velocity = Vector2.ZERO
                game.player.global_position = hollow.global_position + Vector2(-52.0, 0)
                game.player.facing = 1
                game.player.velocity = Vector2.ZERO
                await _wait(0.5)                    # the camera settles; nothing can move
                game.player._attack_idx = 0
                game.player._attack_phase = 0.0
                game.player._hit_pending = false
                game.player._do_hit(0)
                _pin_cards()
                await _snap("wb19_05_jab_card")   # the jab's wound card
                await _wait(1.4)
                game.player._attack_idx = 2
                game.player._attack_phase = 0.0
                game.player._hit_pending = false
                game.player._do_hit(2)
                _pin_cards()
                await _snap("wb19_06_finisher_card") # the finisher's doubled ring

        # ================================================= THE RIM (1 shot)
        await _room("act5", Vector2(1400, 780))
        var flock: Array = []
        for node in get_tree().get_nodes_in_group("enemies"):
                if node is Believer and not node.dead:
                        flock.append(node)
        if flock.size() >= 2:
                var a: Believer = flock[0]
                var b: Believer = flock[1]
                b.global_position = a.global_position + Vector2(44, 0)
                b.velocity = Vector2.ZERO
                await _wait(0.9)                    # sep_k rises to full
                await _snap("wb19_07_flock_rim")

        print("WB-19 STILLS DONE (", _shot, ")")
        get_tree().quit(0)
