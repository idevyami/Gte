## WB-25 proof — closing WB-24's honest open tier:
##   (1) THE DEAD-END PILE at its tightest churn — the press at the ward's
##       foot still reads 2-3 of 5 (bodies at 12-18px gaps in front of the
##       light field — partly the truth of a press at a wall, the audit's
##       own caveat). The instrument logs the churn's geometry histogram
##       (xs/min_dx at 0.3s cadence) and snaps the TIGHTEST representative
##       frame — the honest worst, not the settled best — plus the settled
##       frame for the before/after story.
##   (2) THE CHANTRY JAMB's pale-saint read at the worst camera slice (the
##       room is literally named for one). Three slices sweep the reachable
##       framings of the arch's right jamb: from the chantry side, dead-on
##       with the relic's light on it, and from the wheel side.
## The same event-logged staging discipline as WB-22/23/24 (placement-staged
## press, the live AI continues; file-traced progress under Xvfb).
## Segments run in PAIRS from the command line (`-- --segments=1,2`) so each
## tool call fits the render budget. RUN:
##   DISPLAY=:99 godot --resolution 640x360 --rendering-driver opengl3
##   res://tests/proof_wb25.tscn -- --segments=1,2
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
                _prog = FileAccess.open("/tmp/wb25_progress.txt", FileAccess.READ_WRITE if FileAccess.file_exists("/tmp/wb25_progress.txt") else FileAccess.WRITE)
        if _prog:
                _prog.seek_end()
                _prog.store_line(s)
                _prog.flush()
        print(s)

func _ready() -> void:
        DirAccess.make_dir_recursive_absolute("res://screenshots/wb25")
        process_mode = Node.PROCESS_MODE_ALWAYS
        for arg in OS.get_cmdline_user_args():
                if arg.begins_with("--segments="):
                        for part in arg.trim_prefix("--segments=").split(","):
                                _segments.append(int(part))
        if _segments.is_empty():
                _segments = [1, 2]
        RenderingServer.frame_post_draw.connect(_on_frame_post_draw)
        _run.call_deferred()

func _on_frame_post_draw() -> void:
        if not _shot:
                return
        _shot = false
        var img := get_viewport().get_texture().get_image()
        img.save_jpg("res://screenshots/wb25/%s" % _fname, STILL_Q)
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

func _press_geom(px: float) -> Dictionary:
        ## the press's own geometry: only bodies within the corner's reach
        ## of the staged spot — the pile the audit must judge
        var xs: Array[float] = []
        for node in _flock():
                if absf(node.global_position.x - px) <= 420.0:
                        xs.append(node.global_position.x)
        xs.sort()
        var mind := -1.0
        if xs.size() >= 2:
                mind = 1e9
                for i in range(1, xs.size()):
                        mind = minf(mind, xs[i] - xs[i - 1])
        return {"n": xs.size(), "min": mind}

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

func _snap_tight(fname: String, patience := 9.0, near_px := 1760.0, tight_max := 22.0) -> void:
        ## the churn's honest WORST frame: the tightest press gap with the
        ## count still holding AT the spot — the frame the audit must be
        ## able to read. A blind timed snap catches transits; this waits
        ## for the pile itself to close (min_dx inside the tight band).
        var t0 := Time.get_ticks_msec()
        var tightest := 1e9
        var hist: Array[float] = []
        var snapped := false
        var last_log := 0
        while Time.get_ticks_msec() - t0 < int(patience * 1000.0):
                _top_player()
                var pg := _press_geom(near_px)
                if pg["n"] >= 2 and pg["min"] < 1e8:
                        hist.append(pg["min"])
                        tightest = minf(tightest, pg["min"])
                var el := Time.get_ticks_msec() - t0
                if el - last_log >= 300:
                        last_log = el
                        var g := _geom()
                        var sts := ""
                        for node in _flock():
                                if absf(node.global_position.x - near_px) <= 420.0:
                                        sts += "%s@%.0f " % [node.state, node.global_position.x]
                        _trace("EVT churn t=%.1f player@%.0f press n=%d min_dx=%.1f all=[%s] sts=[%s]" % [el / 1000.0, game.player.global_position.x, pg["n"], pg["min"], g["xs"], sts])
                if not snapped and pg["n"] >= 4 and pg["min"] <= tight_max:
                        _trace("EVT tight-snap min_dx=%.1f press=%d" % [pg["min"], pg["n"]])
                        await _snap(fname)
                        snapped = true
                await get_tree().process_frame
        hist.sort()
        if not hist.is_empty():
                _trace("EVT churn-hist n=%d p5=%.1f p25=%.1f p50=%.1f tightest=%.1f" % [
                        hist.size(), hist[int(hist.size() * 0.05)],
                        hist[int(hist.size() * 0.25)], hist[int(hist.size() * 0.5)], tightest])
        if not snapped:
                _trace("EVT tight-snap MISSED (tightest %.1f) — falling back to the last frame" % tightest)
                await _snap(fname)

func _snap_settled(fname: String, patience := 2.5, near_px := -1.0) -> void:
        ## the churn of the press (strikes carrying through, bodies
        ## re-winding) means a blind timed snap can catch a transit — the
        ## settled moment is the representative one (no body mid-strike,
        ## the press holding its count, and still AT the staged spot).
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

        # ======================================= 1. THE PILE, TIGHTEST
        # WB-24's honest open tier: the dead-end press at its tightest
        # churn reads 2-3 of 5 (12-18px gaps in front of the ward's light
        # field). The vessel camps at the ward's foot; the press stages;
        # the churn runs NINE SECONDS with the geometry histogram logged;
        # the snap lands at the tightest representative frame, then the
        # settled frame for contrast.
        if _segments.has(1):
                _trace("segment 1: the pile, tightest")
                await _room("act5", Vector2(1760, 780))
                _stage_press(1760.0, 5)
                var ft0 := Time.get_ticks_msec()
                for i in 60:
                        _top_player()
                        await get_tree().process_frame
                        if i == 59:
                                _trace("EVT frametime %.0f frames in %.1fs (%.2fs/frame)"
                                        % [i + 1, (Time.get_ticks_msec() - ft0) / 1000.0,
                                                (Time.get_ticks_msec() - ft0) / 1000.0 / float(i + 1)])
                var g1 := _geom()
                _trace("EVT pile n=%d min_dx=%.1f xs=[%s]" % [g1["n"], g1["min"], g1["xs"]])
                await _snap_tight("wb25_01_pile_tightest.jpg", 9.0, 1760.0, 22.0)
                _trace("segment 1a: tightest snapped")
                await _snap_settled("wb25_02_pile_settled.jpg", 3.0, 1760.0)
                _trace("segment 1b: settled snapped")

        # ======================================= 2. THE JAMB, SLICED
        # WB-24's other open tier: the chantry arch's right jamb (pale,
        # fluted, standing on the floor) still reads as a saint at the
        # worst camera slice — the room is literally named for one. Three
        # reachable framings: from the chantry side, dead-on with the
        # relic's light on the jamb, and from the wheel side (camera
        # clamps at 1360; the jamb sweeps the frame's right third).
        if _segments.has(2):
                _trace("segment 2: the jamb, sliced")
                await _room("act5", Vector2(1250, 780))
                for i in 30:
                        _skip_dialogue_noawait()
                        await get_tree().process_frame
                await _snap("wb25_03_jamb_chantry_side.jpg")
                _trace("segment 2a: chantry side snapped")
                game.player.global_position = Vector2(1500, 780)
                game.player.velocity = Vector2.ZERO
                for i in 40:
                        _skip_dialogue_noawait()
                        await get_tree().process_frame
                await _snap("wb25_04_jamb_relic_light.jpg")
                _trace("segment 2b: relic light snapped")
                game.player.global_position = Vector2(1620, 780)
                game.player.velocity = Vector2.ZERO
                for i in 40:
                        _skip_dialogue_noawait()
                        await get_tree().process_frame
                await _snap("wb25_05_jamb_wheel_side.jpg")
                _trace("segment 2c: wheel side snapped")

        print("WB-25 PROOFS DONE")
        get_tree().quit(0)
