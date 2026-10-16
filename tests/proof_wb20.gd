## WB-20 "THE WALKING FLOCK" proof — the weight-shift pass's instrument.
## The WB-19 motion audit's chess-piece finding closed, and the capture
## ceiling's true cause corrected: WB-19 attributed ~7.6fps capture to
## full-res JPEG saves (~130ms) — measured this pass, the whole capture
## pipeline costs ~14ms/frame (read 4.5 + resize 4.5 + save 5). The real
## ceiling was the GAME'S OWN RENDER RATE under Xvfb's llvmpipe software
## rendering (~8fps at 1280x720). The fix is the window: run this proof
## with `--resolution 640x360` and the game renders ~19fps — walk cycles
## resolve at 14 samples, the 8fps painted animation gets 2.4 samples per
## frame (the beat-frequency "slide" cannot manufacture itself), and the
## ride's full amplitude renders between frame boundaries. Stills are
## strobe-locked to the ride phase (paused tree, true frame, no staging).
## Every clip is EVENT-LOGGED — the audit prompt describes only what the
## log proves happened, and carries the anti-confabulation clause.
## Segments: flockwalk (the congregation converges), strobe (dip vs rise).
## Output: screenshots/wb20/. RUN: DISPLAY=:99 godot --resolution 640x360
##   res://tests/proof_wb20.tscn
extends Node

const CAP_MS := 20          # wall-clock capture interval (target ~40fps)
const JPG_Q := 0.62         # motion clips: 640x360, judged in time not texels
const STILL_Q := 0.92       # strobe stills: the pixel-diff's evidence

var game: Game
var main: Node

var _seg := ""
var _cap_active := false
var _cap_idx := 0
var _cap_last_ms := 0
var _cap_half := false      # the window itself is 640x360 — save native
var _cap_names: Array[String] = []
var _cap_durs: Array[float] = []
var _strobe_shot := false   # one-shot: the next frame_post_draw saves full-res

func _ready() -> void:
        DirAccess.make_dir_recursive_absolute("res://screenshots/wb20")
        DirAccess.make_dir_recursive_absolute("res://screenshots/wb20/stills")
        process_mode = Node.PROCESS_MODE_ALWAYS
        RenderingServer.frame_post_draw.connect(_on_frame_post_draw)
        _run.call_deferred()

# ---------------------------------------------------------------- capture
func _on_frame_post_draw() -> void:
        if _strobe_shot:
                _strobe_shot = false
                _save_frame("stills", "s%06d.jpg" % _cap_idx, STILL_Q)
                _cap_idx += 1
                return
        if not _cap_active:
                return
        var now := Time.get_ticks_msec()
        if now - _cap_last_ms < CAP_MS:
                return
        var dt := (now - _cap_last_ms) / 1000.0
        _cap_last_ms = now
        if _cap_idx > 0:
                # guard: a room-load stall must not freeze the film — cap at 250ms
                _cap_durs.append(clampf(dt, 0.01, 0.25))
        _save_frame(_seg, "f%06d.jpg" % _cap_idx)
        _cap_names.append("f%06d.jpg" % _cap_idx)
        _cap_idx += 1

func _save_frame(dir: String, fname: String, q := JPG_Q) -> void:
        var img := get_viewport().get_texture().get_image()
        img.save_jpg("res://screenshots/wb20/%s/%s" % [dir, fname], q)

func _seg_arm(name: String) -> void:
        DirAccess.make_dir_recursive_absolute("res://screenshots/wb20/" + name)
        _seg = name
        _cap_idx = 0
        _cap_names.clear()
        _cap_durs.clear()
        _cap_last_ms = Time.get_ticks_msec()
        _cap_active = true
        print("SEG ", name, " start")

func _seg_end() -> void:
        _cap_active = false
        if _cap_names.is_empty():
                print("SEG ", _seg, " EMPTY")
                return
        var f := FileAccess.open("res://screenshots/wb20/%s/list.txt" % _seg, FileAccess.WRITE)
        f.store_line("ffconcat version 1.0")
        for i in _cap_names.size():
                f.store_line("file '%s'" % _cap_names[i])
                if i < _cap_durs.size():
                        f.store_line("duration %.4f" % _cap_durs[i])
        f.store_line("file '%s'" % _cap_names[_cap_names.size() - 1])
        f.close()
        var total := 0.0
        for d in _cap_durs:
                total += d
        print("SEG ", _seg, " end frames=", _cap_names.size(), " secs=%.2f" % total,
                " fps=%.1f" % (_cap_names.size() / maxf(0.01, total)))

# ---------------------------------------------------------------- helpers
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

# ---------------------------------------------------------------- run
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

        # ==================================================== 1. FLOCKWALK
        # the congregation converges on the vessel: hurt one, all answer,
        # the whole flock walks — the audit's exact chess-piece scene. The
        # vessel stands AMONG the far group (believers only pursue within
        # 560px — the near pair is outside the scene's law) and retreats in
        # short steps: his 260 outruns their 120, so a steady retreat would
        # drop them back to the chant — the kiting rhythm keeps the walk.
        await _room("act5", Vector2(1520, 780))
        var flock := _flock()
        var herd: Believer = null
        for node in flock:
                if absf(node.global_position.x - 1520.0) < 420.0:
                        herd = node
                        break
        _seg_arm("flockwalk")
        if herd:
                await _wait(1.2)                  # the chant bed
                # EVENT LOG: the scene's truth, printed as it happens
                print("EVT walk begins: flock=", flock.size(), " herd_x=", int(herd.global_position.x))
                herd.take_hit(10, herd.global_position + Vector2(-30, 0), false, 0)
                var log_t := Time.get_ticks_msec()
                var log_i := 0
                var walk_t := Time.get_ticks_msec()
                var kiting := true
                while Time.get_ticks_msec() - walk_t < 10000:
                        # retreat in steps: 0.6s walking, 1.0s holding — the
                        # congregation closes, the vessel gives ground slowly
                        var el := float(Time.get_ticks_msec() - walk_t) / 1000.0
                        var want_walk := fmod(el, 1.6) < 0.6
                        if want_walk and kiting:
                                Input.action_press("move_left")
                        else:
                                Input.action_release("move_left")
                        if Time.get_ticks_msec() - log_t > 800:
                                log_t = Time.get_ticks_msec()
                                var line := "EVT %02d px=%d" % [log_i, int(game.player.global_position.x)]
                                for node2 in _flock():
                                        var b := node2 as Believer
                                        line += " | b x=%d fr=%d w=(%.2f,%.2f) sep=%.2f" % [
                                                int(b.global_position.x), int(b._skin.frame),
                                                b._skin.position.x, b._skin.position.y, b.sep_k]
                                print(line)
                                log_i += 1
                        await get_tree().process_frame
                Input.action_release("move_left")
        else:
                await _wait(3.0)
        _seg_end()

        # ==================================================== 2. STROBE
        # full-res stills locked to the ride's two extremes: the dip at a
        # planted footfall and the rise at mid-swing. The tree pauses at
        # the crossing — the still is a true frame, not a staged pose.
        await _room("act5", Vector2(1520, 780))
        flock = _flock()
        herd = null
        for node in flock:
                if absf(node.global_position.x - 1520.0) < 420.0:
                        herd = node
                        break
        if herd:
                # one clean walking body, camera on it
                game.player.global_position = herd.global_position + Vector2(420, 0)
                herd.state = herd.AGGRO
                herd.state_t = 0.0
                await _wait(0.35)
                for target in ["dip", "rise", "dip", "rise"]:
                        var want := 0.0 if target == "dip" else 0.25
                        var tol := 0.05
                        var guard := Time.get_ticks_msec()
                        while Time.get_ticks_msec() - guard < 4000:
                                await get_tree().process_frame
                                if not is_instance_valid(herd) or herd.dead:
                                        break
                                if herd._skin == null or herd._skin.animation != "walk":
                                        continue
                                var d := absf(herd._walk_phase - want)
                                d = minf(d, absf(herd._walk_phase - want - 1.0))
                                if d < tol:
                                        break
                        if not is_instance_valid(herd) or herd.dead:
                                break
                        print("STROBE ", target, " phase=%.3f w=(%.2f,%.2f) fr=%d" % [
                                herd._walk_phase, herd._skin.position.x,
                                herd._skin.position.y, herd._skin.frame])
                        get_tree().paused = true
                        await get_tree().process_frame
                        _strobe_shot = true
                        await get_tree().process_frame
                        await get_tree().create_timer(0.25, true, false, true).timeout
                        get_tree().paused = false
                        await _wait(0.2)
        print("WB-20 PROOFS DONE")
        get_tree().quit(0)
