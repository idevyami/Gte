## WB-23 "THE FURNITURE YIELDS" proof — the figure-vs-architecture grammar
## pass's instrument. The baseline (wb22_03_the_depth.jpg, logged): at the
## reliquary's busiest wall the audit traced 1 of 5 bodies (clarity 2/10,
## "reads primarily as an empty ornate interior"; the mass parsed as
## "twisted brass ornament", the body-sized candelabra as "a pile of gears
## and pipes"). This pass sits the furniture down (halos 0.68, brass one
## step darker), lifts the wall's washes off the body band (altar glow
## r340->295 cone 260->150, cluster r240->210 cone 190->140) and thickens
## the chapel's own air (0.20 -> 0.26) — the grammar law: at the body band
## the strongest warm presences belong to BODIES.
## Segments: the same depth-read staging as WB-22 (the before/after pair),
## the press at the candelabra (the worst grammar collision), the kneel
## rows under the thicker air, and the walk along the busy wall.
## THIS SANDBOX'S LAW: 2 CPU cores — llvmpipe at 720p costs seconds per
## frame, so the instrument renders at 640x360 (the hub cards upscale) and
## STAGES the press by placement (the flock is teleported to its converged
## formation, the live AI continues from there — the jostle holds, the
## anims run, the logged xs/min_dx keep the still's truth honest) instead
## of paying 480 renders per segment for the walk-in. Segments run in
## PAIRS selected from the command line (`-- --segments=1,2`) so each tool
## call fits the render budget. RUN:
##   DISPLAY=:99 godot --resolution 640x360 --rendering-driver opengl3
##   res://tests/proof_wb23.tscn -- --segments=1,2
extends Node

const STILL_W := 640
const STILL_H := 360
const STILL_Q := 0.92

var game: Game
var main: Node
var _shot := false
var _fname := ""
var _prog: FileAccess
var _segments: Array = []

func _trace(s: String) -> void:
        ## progress to a file — piped stdout block-buffers and timeout kills
        ## never flush, so the Xvfb path needs its own channel
        if _prog == null:
                _prog = FileAccess.open("/tmp/wb23_progress.txt", FileAccess.READ_WRITE if FileAccess.file_exists("/tmp/wb23_progress.txt") else FileAccess.WRITE)
        if _prog:
                _prog.seek_end()
                _prog.store_line(s)
                _prog.flush()
        print(s)

func _ready() -> void:
        DirAccess.make_dir_recursive_absolute("res://screenshots/wb23")
        process_mode = Node.PROCESS_MODE_ALWAYS
        for arg in OS.get_cmdline_user_args():
                if arg.begins_with("--segments="):
                        for part in arg.trim_prefix("--segments=").split(","):
                                _segments.append(int(part))
        if _segments.is_empty():
                _segments = [1, 2, 3, 4]
        RenderingServer.frame_post_draw.connect(_on_frame_post_draw)
        _run.call_deferred()

func _on_frame_post_draw() -> void:
        if not _shot:
                return
        _shot = false
        var img := get_viewport().get_texture().get_image()
        img.save_jpg("res://screenshots/wb23/%s" % _fname, STILL_Q)
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
        game.player.global_position = pos
        game.player.velocity = Vector2.ZERO
        _skip_dialogue_noawait()
        await get_tree().process_frame

func _skip_dialogue_noawait() -> void:
        if game.dialogue_box != null and game.dialogue_box.active:
                game.dialogue_box.chars_shown = 99999
                game.dialogue_box.advance()

func _flock() -> Array:
        var out: Array = []
        for node in get_tree().get_nodes_in_group("enemies"):
                if node is Believer and not node.dead:
                        out.append(node)
        return out

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

func _stage_press(px: float, n_want: int) -> void:
        ## THIS SANDBOX'S LAW: the walk-in costs 480 renders the 2-core
        ## llvmpipe cannot pay — so the flock is PLACED at its converged
        ## formation (jostle-min spacing around the vessel, aggro'd), and
        ## the live AI continues from there: the jostle breathes, the
        ## chant-sway runs, the strikes cycle. The logged xs/min_dx keep
        ## the still's truth honest.
        var flock := _flock()
        # nearest-first so the bodies that would press hardest stand the
        # closest — the formation the walk-in would have found
        flock.sort_custom(func(a, b):
                return absf(a.global_position.x - px) < absf(b.global_position.x - px))
        var placed := 0
        var i := 0
        while placed < n_want and i < flock.size():
                var b: Believer = flock[i]
                i += 1
                if absf(b.global_position.x - px) > 900.0:
                        continue
                var slot := float(placed) - float(n_want - 1) / 2.0
                var x := px + slot * 36.0 + 7.0 * sin(placed * 2.1)
                b.global_position = Vector2(clampf(x, 60.0, 1940.0), 780.0)
                b.velocity = Vector2.ZERO
                b.state = b.AGGRO
                b.state_t = 0.0
                placed += 1
        _trace("EVT staged %d bodies at %.0f" % [placed, px])

func _snap_settled(fname: String, patience := 2.5, near_px := -1.0) -> void:
        ## the churn of the press (strikes carrying through, bodies
        ## re-winding) means a blind timed snap can catch a transit — the
        ## settled moment is the representative one, so the instrument
        ## WAITS for it (no body mid-strike, the press holding its count).
        ## WB-23: when near_px is given, the press must also still be AT
        ## the staged spot — the AGGRO churn walks bodies ~100px off during
        ## a long patience, and the still must show the press at the busy
        ## wall, not mid-drift.
        var t0 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t0 < int(patience * 1000.0):
                _top_player()
                var ok := true
                var xs: Array[float] = []
                var press_n := 0
                for node in _flock():
                        if node.state == node.STRIKE:
                                ok = false
                                break
                        if near_px > 0.0 and absf(node.global_position.x - near_px) <= 420.0:
                                press_n += 1
                                if absf(node.global_position.x - near_px) > 170.0:
                                        ok = false
                                        break
                        xs.append(node.global_position.x)
                if ok and near_px > 0.0 and press_n < 4:
                        ok = false
                if ok and xs.size() >= 2:
                        xs.sort()
                        for i in range(1, xs.size()):
                                if xs[i] - xs[i - 1] < 12.0:
                                        ok = false
                                        break
                if ok:
                        break
                await get_tree().process_frame
        var gs := _geom()
        _trace("EVT snap-state n=%d min_dx=%.1f xs=[%s]" % [gs["n"], gs["min"], gs["xs"]])
        var states := ""
        for node in _flock():
                states += "%s@%.0f " % [node.state, node.global_position.x]
        _trace("EVT snap-states %s" % states)
        _trace("EVT settled-snap for %s" % fname)
        await _snap(fname)

func _run() -> void:
        _trace("run begin (segments %s)" % str(_segments))
        main = (load("res://main.tscn") as PackedScene).instantiate()
        get_tree().root.add_child(main)
        await get_tree().process_frame
        await get_tree().process_frame
        game = main.game
        main.title.hide_screen()
        game.set_active(true)
        game.new_game()
        _trace("new_game done")
        _skip_dialogue()
        await get_tree().process_frame
        _trace("intro settled")

        # ======================================= 1. THE WALL, AGAIN
        # the SAME staging as WB-22's depth read (player at the busy wall,
        # x1460, the great arch + chandelier + candles behind the press) —
        # the before/after pair for the grammar pass
        if _segments.has(1):
                _trace("segment 1: the wall, again")
                await _room("act5", Vector2(1460, 780))
                _stage_press(1460.0, 5)
                var ft0 := Time.get_ticks_msec()
                for i in 60:
                        _top_player()
                        await get_tree().process_frame
                        if i == 19 or i == 59:
                                _trace("EVT frametime %.0f frames in %.1fs (%.2fs/frame)"
                                        % [i + 1, (Time.get_ticks_msec() - ft0) / 1000.0,
                                                (Time.get_ticks_msec() - ft0) / 1000.0 / float(i + 1)])
                var g1 := _geom()
                _trace("EVT wall n=%d min_dx=%.1f xs=[%s]" % [g1["n"], g1["min"], g1["xs"]])
                await _snap_settled("wb23_01_the_wall.jpg", 3.0, 1460.0)
                _trace("segment 1: snapped")

        # ======================================= 2. THE GRAMMAR AT THE
        # CANDELABRA — the worst collision of the baseline: a body-sized
        # brass stand (x1660, h115) standing among the bodies parsed as "a
        # pile of gears and pipes". The press forms right at it.
        if _segments.has(2):
                _trace("segment 2: the grammar at the candelabra")
                await _room("act5", Vector2(1660, 780))
                _stage_press(1660.0, 5)
                for i in 60:
                        _top_player()
                        await get_tree().process_frame
                var g2 := _geom()
                _trace("EVT grammar n=%d min_dx=%.1f xs=[%s]" % [g2["n"], g2["min"], g2["xs"]])
                await _snap_settled("wb23_02_the_grammar.jpg", 3.0, 1660.0)
                _trace("segment 2: snapped")

        # ======================================= 3. THE KNEEL ROWS UNDER
        # THE THICKER AIR — the congregation at rest, no aggro: the
        # baseline read a far-right kneel row as "a carved bas-relief or
        # ornamental border". The thickened band must read them as people.
        if _segments.has(3):
                _trace("segment 3: the kneel rows")
                await _room("act5", Vector2(1520, 780))
                for i in 30:
                        await get_tree().process_frame
                await _snap("wb23_03_the_air.jpg")
                _trace("segment 3: snapped")

        # ======================================= 4. THE WALK ALONG THE
        # BUSY WALL — the kite along the reliquary: the vessel retreats
        # past the arch and the candelabra, the flock presses after him
        if _segments.has(4):
                _trace("segment 4: the walk along the wall")
                await _room("act5", Vector2(1600, 780))
                _stage_press(1600.0, 5)
                var t4 := Time.get_ticks_msec()
                var last_log := 0
                while Time.get_ticks_msec() - t4 < 2400:
                        _top_player()
                        var el4 := Time.get_ticks_msec() - t4
                        var sec := float(el4) / 1000.0
                        if fmod(sec, 1.6) < 0.6:
                                Input.action_press("move_left")
                        else:
                                Input.action_release("move_left")
                        if el4 - last_log >= 400:
                                last_log = el4
                                var g := _geom()
                                _trace("EVT kite t=%.1f n=%d min_dx=%.1f xs=[%s]"
                                        % [sec, g["n"], g["min"], g["xs"]])
                        await get_tree().process_frame
                Input.action_release("move_left")
                var g4 := _geom()
                _trace("EVT kite FINAL n=%d min_dx=%.1f xs=[%s]" % [g4["n"], g4["min"], g4["xs"]])
                await _snap_settled("wb23_04_the_walk.jpg", 3.0, -1.0)
                _trace("segment 4: snapped")

        print("WB-23 PROOFS DONE")
        get_tree().quit(0)
