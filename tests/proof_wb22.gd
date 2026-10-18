## WB-22 "THE PRESS KEEPS ITS COUNT" proof — the cluster pass's instrument.
## Full-resolution stills (1280x720, opengl3 under Xvfb) for the hub cards and
## the honest audit: the static press (how many bodies does the converged
## flock trace?), the press that walks (kite), the depth read (the flock
## against the chapel's busy background), the barge (a strike carried through
## the crowd), and the air the censers fill (the kneeling rows' band).
## Every segment logs the flock's geometry (n / min pairwise dx / xs) so the
## audit's prompts describe only logged truth. RUN:
##   DISPLAY=:99 godot --resolution 1280x720 --rendering-driver opengl3
##   res://tests/proof_wb22.tscn
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
                _prog = FileAccess.open("/tmp/wb22_progress.txt", FileAccess.WRITE)
        if _prog:
                _prog.store_line(s)
                _prog.flush()
        print(s)

func _ready() -> void:
        DirAccess.make_dir_recursive_absolute("res://screenshots/wb22")
        process_mode = Node.PROCESS_MODE_ALWAYS
        RenderingServer.frame_post_draw.connect(_on_frame_post_draw)
        _run.call_deferred()

func _on_frame_post_draw() -> void:
        if not _shot:
                return
        _shot = false
        var img := get_viewport().get_texture().get_image()
        img.save_jpg("res://screenshots/wb22/%s" % _fname, STILL_Q)
        _trace("STILL " + _fname)

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

func _nearest(px: float, r: float) -> Believer:
        var best: Believer = null
        var bd := 1e9
        for node in _flock():
                var d := absf(node.global_position.x - px)
                if d < bd and d < r:
                        bd = d
                        best = node
        return best

func _geom() -> Dictionary:
        ## the flock's logged truth: how many living bodies, the smallest
        ## gap between any two, and their sorted xs — the audit's evidence
        var xs: Array[float] = []
        for node in _flock():
                xs.append(node.global_position.x)
        xs.sort()
        var mind := -1.0
        if xs.size() >= 2:
                mind = 1e9
                for i in range(1, xs.size()):
                        mind = minf(mind, xs[i] - xs[i - 1])
        var s := ""
        for x in xs:
                s += "%.0f " % x
        return {"n": xs.size(), "min": mind, "xs": s}

func _top_player() -> void:
        ## the vessel does not die inside the instrument — the press must
        ## be judged at full length, not cut short by the staging itself
        if game.player.hp < game.player.max_hp:
                game.player.hp = game.player.max_hp
                EventBus.player_health_changed.emit(game.player.hp, game.player.max_hp)

func _hit_and_spread() -> Believer:
        var herd := _nearest(1520.0, 420.0)
        if herd:
                herd.take_hit(10, herd.global_position + Vector2(-30, 0), false, 0)
        return herd

func _snap_settled(fname: String, patience := 4.0) -> void:
        ## the churn of the press (strikes carrying through, bodies
        ## re-winding) means a blind timed snap can catch a transit — the
        ## settled moment is the representative one, so the instrument
        ## WAITS for it (no body mid-strike, the press holding its count)
        var t0 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t0 < int(patience * 1000.0):
                _top_player()
                var ok := true
                var xs: Array[float] = []
                for node in _flock():
                        if node.state == node.STRIKE:
                                ok = false
                                break
                        xs.append(node.global_position.x)
                if ok and xs.size() >= 2:
                        xs.sort()
                        for i in range(1, xs.size()):
                                if xs[i] - xs[i - 1] < 12.0:
                                        ok = false
                                        break
                if ok:
                        break
                await get_tree().process_frame
        _trace("EVT settled-snap for %s" % fname)
        await _snap(fname)

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

        # ============================================ 1. THE PRESS (static)
        # the cluster stress: every believer answered the harm, every body
        # walks to the vessel, the press forms — logged until it settles
        _trace("segment 1: the press")
        await _room("act5", Vector2(1520, 780))
        _hit_and_spread()
        var t1 := Time.get_ticks_msec()
        var last_log := 0
        while Time.get_ticks_msec() - t1 < 9000:
                _top_player()
                var el := Time.get_ticks_msec() - t1
                if el - last_log >= 300:
                        last_log = el
                        var g := _geom()
                        _trace("EVT press t=%.1f n=%d min_dx=%.1f xs=[%s]"
                                % [el / 1000.0, g["n"], g["min"], g["xs"]])
                await get_tree().process_frame
        var g1 := _geom()
        _trace("EVT press FINAL n=%d min_dx=%.1f xs=[%s]" % [g1["n"], g1["min"], g1["xs"]])
        await _snap_settled("wb22_01_the_press.jpg")
        _trace("segment 1: snapped")

        # ============================================ 2. THE PRESS WALKS
        # the kite: the vessel retreats, the flock presses after him — the
        # cluster question in motion
        _trace("segment 2: the press walks")
        await _room("act5", Vector2(1520, 780))
        _hit_and_spread()
        var t2 := Time.get_ticks_msec()
        last_log = 0
        while Time.get_ticks_msec() - t2 < 4200:
                _top_player()
                var el2 := Time.get_ticks_msec() - t2
                var sec := float(el2) / 1000.0
                if fmod(sec, 1.6) < 0.6:
                        Input.action_press("move_left")
                else:
                        Input.action_release("move_left")
                if el2 - last_log >= 300:
                        last_log = el2
                        var g := _geom()
                        _trace("EVT kite t=%.1f n=%d min_dx=%.1f xs=[%s]"
                                % [sec, g["n"], g["min"], g["xs"]])
                await get_tree().process_frame
        Input.action_release("move_left")
        var g2 := _geom()
        _trace("EVT kite FINAL n=%d min_dx=%.1f xs=[%s]" % [g2["n"], g2["min"], g2["xs"]])
        await _snap_settled("wb22_02_the_press_walks.jpg")
        _trace("segment 2: snapped")

        # ============================================ 3. THE DEPTH READ
        # the flock pressed against the chapel's busiest background: the
        # great arch (x1400, w360) and the chandelier (x1530) behind the
        # bodies — the depth-competition audit's subject
        _trace("segment 3: the depth read")
        await _room("act5", Vector2(1460, 780))
        _hit_and_spread()
        var t3 := Time.get_ticks_msec()
        last_log = 0
        while Time.get_ticks_msec() - t3 < 8000:
                _top_player()
                var el3 := Time.get_ticks_msec() - t3
                if el3 - last_log >= 500:
                        last_log = el3
                        var g := _geom()
                        _trace("EVT depth t=%.1f n=%d min_dx=%.1f" % [el3 / 1000.0, g["n"], g["min"]])
                await get_tree().process_frame
        var g3 := _geom()
        _trace("EVT depth FINAL n=%d min_dx=%.1f xs=[%s]" % [g3["n"], g3["min"], g3["xs"]])
        await _snap_settled("wb22_03_the_depth.jpg")
        _trace("segment 3: snapped")

        # ============================================ 4. THE BARGE
        # staged on the formed press: a back-rank body strikes — the lunge
        # carries THROUGH the crowd (the flock parts for the strike)
        _trace("segment 4: the barge")
        var flock4: Array = []
        for node in _flock():
                if absf(node.global_position.x - 1460.0) < 220.0:
                        flock4.append(node)
        var by_dist := func(a: Believer, b: Believer) -> bool:
                return absf(a.global_position.x - 1460.0) > absf(b.global_position.x - 1460.0)
        flock4.sort_custom(by_dist)
        if flock4.size() >= 3:
                var striker: Believer = flock4[0]
                striker.state = striker.STRIKE
                striker.state_t = 0.0
                var tb := Time.get_ticks_msec()
                while Time.get_ticks_msec() - tb < 260:
                        _top_player()
                        await get_tree().process_frame
                var g4 := _geom()
                _trace("EVT barge striker_x=%.0f min_dx=%.1f" % [striker.global_position.x, g4["min"]])
                await _snap("wb22_04_the_barge.jpg")
        _trace("segment 4: snapped")

        # ============================================ 5. THE AIR
        # the kneeling rows at rest, no aggro: the chapel's own air over
        # the congregation — the band the censers fill
        _trace("segment 5: the air")
        await _room("act5", Vector2(1520, 780))
        await _wait(1.6)
        await _snap("wb22_05_the_air.jpg")
        _trace("segment 5: snapped")

        print("WB-22 PROOFS DONE")
        get_tree().quit(0)
