## WB-21 "THE CENSER'S EDGE" proof — the readability pass's instrument.
## Full-resolution stills (1280x720, opengl3 under Xvfb) for the hub cards
## and the re-audit: the converged flock's gold edges, the kneeling rows'
## grounding pools, the lean of the walking body (left and right), and the
## warm robe's folds. RUN: DISPLAY=:99 godot --resolution 1280x720
##   res://tests/proof_wb21.tscn
extends Node

const STILL_Q := 0.92

var game: Game
var main: Node
var _shot := false
var _fname := ""
var _prog: FileAccess

func _trace(s: String) -> void:
        ## progress to a file — piped stdout block-buffers and timeout kills
        ## never flush, so the Xvfb path needs its own channel
        if _prog == null:
                _prog = FileAccess.open("/tmp/wb21_progress.txt", FileAccess.WRITE)
        if _prog:
                _prog.store_line(s)
                _prog.flush()
        print(s)

func _ready() -> void:
        DirAccess.make_dir_recursive_absolute("res://screenshots/wb21")
        process_mode = Node.PROCESS_MODE_ALWAYS
        RenderingServer.frame_post_draw.connect(_on_frame_post_draw)
        _run.call_deferred()

func _on_frame_post_draw() -> void:
        if not _shot:
                return
        _shot = false
        var img := get_viewport().get_texture().get_image()
        img.save_jpg("res://screenshots/wb21/%s" % _fname, STILL_Q)
        print("STILL ", _fname)

func _snap(fname: String) -> void:
        _fname = fname
        _shot = true
        await get_tree().process_frame
        await get_tree().process_frame

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
        await _wait(0.4)
        _skip_dialogue()
        await _wait(0.2)

func _flock() -> Array:
        var out: Array = []
        for node in get_tree().get_nodes_in_group("enemies"):
                if node is Believer and not node.dead:
                        out.append(node)
        return out

func _run() -> void:
        _trace("run begin")
        main = (load("res://main.tscn") as PackedScene).instantiate()
        get_tree().root.add_child(main)
        await get_tree().process_frame
        await get_tree().process_frame
        game = main.game
        main.title.hide_screen()
        game.set_active(true)
        game.new_game()
        _trace("new_game done")
        await _wait(1.0)
        _skip_dialogue()
        await _wait(0.3)
        _trace("intro settled")

        # ============================================ 1. THE KNEELING ROWS
        _trace("segment 1: room act5")
        await _room("act5", Vector2(1200, 780))
        _trace("segment 1: room ready")
        await _wait(1.6)
        await _snap("wb21_03_the_pools.jpg")
        _trace("segment 1: snapped")

        # ============================================ 2. THE CONVERGENCE
        _trace("segment 2: room act5")
        await _room("act5", Vector2(1520, 780))
        _trace("segment 2: room ready")
        var flock := _flock()
        var herd: Believer = null
        for node in flock:
                if absf(node.global_position.x - 1520.0) < 420.0:
                        herd = node
                        break
        if herd:
                herd.take_hit(10, herd.global_position + Vector2(-30, 0), false, 0)
                var walk_t := Time.get_ticks_msec()
                while Time.get_ticks_msec() - walk_t < 4200:
                        var el := float(Time.get_ticks_msec() - walk_t) / 1000.0
                        if fmod(el, 1.6) < 0.6:
                                Input.action_press("move_left")
                        else:
                                Input.action_release("move_left")
                        await get_tree().process_frame
                Input.action_release("move_left")
        await _snap("wb21_01_the_edge.jpg")

        # ============================================ 3. THE LEAN, LEFT AND RIGHT
        # one clean walking body, camera on it: the axis tilts toward the
        # walk — two stills, two directions, the facing read at a glance
        await _room("act5", Vector2(1520, 780))
        flock = _flock()
        herd = null
        for node in flock:
                if absf(node.global_position.x - 1520.0) < 420.0:
                        herd = node
                        break
        if herd:
                game.player.global_position = herd.global_position + Vector2(420, 0)
                herd.state = herd.AGGRO
                herd.state_t = 0.0
                await _wait(0.6)
                var l0 := herd._skin.rotation_degrees if herd._skin != null else 0.0
                print("EVT lean right: %.2f deg (facing %d)" % [l0, herd.facing])
                await _snap("wb21_02a_lean_right.jpg")
                # now the player crosses to the other side — the body turns
                game.player.global_position = herd.global_position + Vector2(-420, 0)
                await _wait(0.9)
                var l1 := herd._skin.rotation_degrees if herd._skin != null else 0.0
                print("EVT lean left: %.2f deg (facing %d)" % [l1, herd.facing])
                await _snap("wb21_02b_lean_left.jpg")

        # ============================================ 4. THE WARM ROBE
        # camera close on a kneeling body: the folds read inside the
        # silhouette — cloth lit by the light it carries, not a black hole
        await _room("act5", Vector2(1520, 780))
        flock = _flock()
        herd = null
        for node in flock:
                if absf(node.global_position.x - 1520.0) < 420.0:
                        herd = node
                        break
        if herd:
                game.player.global_position = herd.global_position + Vector2(120, -40)
                await _wait(0.8)
                await _snap("wb21_04_the_warm_robe.jpg")

        print("WB-21 PROOFS DONE")
        get_tree().quit(0)
