## WB-18 "THE MOVING PICTURE" proof — the motion experience audit. Every
## prior VLM pass judged stills; experience happens in TIME. This runner
## plays authored gameplay beats in real time under Xvfb and captures the
## framebuffer by WALL CLOCK (~30fps) with exact per-frame durations, so
## the encoded MP4 plays back at true speed regardless of capture hitches.
## Segments: the ascent (movement feel), the threshold (the crossing),
## the hollow (combat readability), the believers (the congregation), the
## martyr (the boss). Frames land in screenshots/wb18/<seg>/f*.jpg plus
## list.txt (ffconcat with per-frame durations) for ffmpeg encoding.
extends Node

const CAP_MS := 33          # wall-clock capture interval (~30 fps)
const JPG_Q := 0.9

var game: Game
var main: Node

var _seg := ""
var _cap_active := false
var _cap_idx := 0
var _cap_last_ms := 0
var _cap_names: Array[String] = []
var _cap_durs: Array[float] = []

func _ready() -> void:
        DirAccess.make_dir_recursive_absolute("res://screenshots/wb18")
        RenderingServer.frame_post_draw.connect(_on_frame_post_draw)
        _run.call_deferred()

# ---------------------------------------------------------------- capture
func _on_frame_post_draw() -> void:
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
        var img := get_viewport().get_texture().get_image()
        var fname := "f%06d.jpg" % _cap_idx
        img.save_jpg("res://screenshots/wb18/%s/%s" % [_seg, fname], JPG_Q)
        _cap_names.append(fname)
        _cap_idx += 1

func _seg_arm(name: String) -> void:
        DirAccess.make_dir_recursive_absolute("res://screenshots/wb18/" + name)
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
        var f := FileAccess.open("res://screenshots/wb18/%s/list.txt" % _seg, FileAccess.WRITE)
        f.store_line("ffconcat version 1.0")
        for i in _cap_names.size():
                f.store_line("file '%s'" % _cap_names[i])
                if i < _cap_durs.size():
                        f.store_line("duration %.4f" % _cap_durs[i])
        # ffconcat convention: repeat the last file without a duration
        f.store_line("file '%s'" % _cap_names[_cap_names.size() - 1])
        f.close()
        var total := 0.0
        for d in _cap_durs:
                total += d
        print("SEG ", _seg, " end frames=", _cap_names.size(), " secs=%.2f" % total)

# ---------------------------------------------------------------- helpers
func _wait(t: float) -> void:
        await get_tree().create_timer(t, true, false, true).timeout

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

func _tap(action: String) -> void:
        Input.action_press(action)
        await _wait(0.07)
        Input.action_release(action)
        await _wait(0.05)

func _hold(action: String, secs: float) -> void:
        Input.action_press(action)
        await _wait(secs)
        Input.action_release(action)

## press jump mid-stride (a running jump, the honest kind)
func _run_jump(dir_action: String, air := 0.62) -> void:
        Input.action_press(dir_action)
        await _wait(0.06)
        Input.action_press("jump")
        await _wait(0.12)
        Input.action_release("jump")
        await _wait(air)
        Input.action_release(dir_action)

func _player() -> Player:
        return game.player

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

        # ============================================================ 1. ASCENT
        # movement feel: the walk, the running jump, the landing that answers,
        # the camera's lookahead — the first thirty seconds of the game.
        _seg_arm("ascent")
        await _wait(1.6)                          # breathe: the wake settles
        await _hold("move_right", 1.45)           # the walk, footfalls answering
        await _wait(0.3)
        await _run_jump("move_right", 0.72)       # hop onto the first shelf
        await _wait(0.35)
        await _run_jump("move_right", 0.68)       # and the second
        await _wait(0.4)
        await _tap("jump")                        # a small idle hop — the body is light
        await _wait(0.2)
        # step off the ledge, land heavy
        Input.action_press("move_right")
        await _wait(0.16)
        Input.action_release("move_right")
        await _wait(1.1)
        _seg_end()

        # ============================================================ 2. THRESHOLD
        # the crossing between acts: the fold, the census rubric, the coming.
        game.player.global_position = Vector2(1470, 200)
        game.player.velocity = Vector2.ZERO
        await _wait(0.4)
        _seg_arm("threshold")
        _hold.call("move_right", 0.9)             # hold through the exit gap
        var t0 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t0 < 14000:
                if game.room_id == "act2" and game.state == "playing":
                        break
                if game.dialogue_box.active:
                        game.dialogue_box.chars_shown = 99999
                        game.dialogue_box.advance()
                await get_tree().process_frame
        await _wait(2.6)                          # the arrival's breath
        _seg_end()

        # ============================================================ 3. HOLLOW
        # combat readability in motion: the stalk, the crimson warning, the
        # lunge, the roll that answers it, the three-hit verdict.
        await _room("act3", Vector2(560, 700))
        var hollow: Hollow = null
        for node in get_tree().get_nodes_in_group("enemies"):
                if node is Hollow:
                        hollow = node
                        break
        _seg_arm("hollow")
        if hollow:
                # approach until it notices and closes
                var th := Time.get_ticks_msec()
                Input.action_press("move_right")
                while Time.get_ticks_msec() - th < 7000 and is_instance_valid(hollow):
                        if absf(hollow.global_position.x - _player().global_position.x) < 150.0:
                                break
                        await get_tree().process_frame
                Input.action_release("move_right")
                # let it stalk in and telegraph
                th = Time.get_ticks_msec()
                while Time.get_ticks_msec() - th < 6000 and is_instance_valid(hollow):
                        if hollow.state == hollow.TELEGRAPH:
                                break
                        await get_tree().process_frame
                await _wait(0.42)                 # read the crimson line
                # the lunge comes — roll back through it
                th = Time.get_ticks_msec()
                while Time.get_ticks_msec() - th < 2000 and is_instance_valid(hollow):
                        if hollow.state == hollow.LUNGE:
                                break
                        await get_tree().process_frame
                Input.action_press("move_left")
                await _tap("roll")
                Input.action_release("move_left")
                await _wait(0.85)                 # it recovers — the window
                # close and give the verdict: three hits
                th = Time.get_ticks_msec()
                Input.action_press("move_right")
                while Time.get_ticks_msec() - th < 5000 and is_instance_valid(hollow):
                        if absf(hollow.global_position.x - _player().global_position.x) < 84.0:
                                break
                        await get_tree().process_frame
                Input.action_release("move_right")
                for i in 3:
                        if not is_instance_valid(hollow):
                                break
                        await _tap("attack")
                        await _wait(0.62)
                await _wait(1.1)                  # the dispersal
        else:
                await _wait(3.0)
        _seg_end()

        # ============================================================ 4. BELIEVERS
        # the congregation: the chant, the strike of one, the answer of all.
        await _room("act5", Vector2(520, 780))
        var believer: Believer = null
        for node in get_tree().get_nodes_in_group("enemies"):
                if node is Believer:
                        believer = node
                        break
        _seg_arm("believers")
        if believer:
                await _wait(1.0)                  # the chant bed, the knee-press
                var th := Time.get_ticks_msec()
                Input.action_press("move_right")
                while Time.get_ticks_msec() - th < 7000 and is_instance_valid(believer):
                        if absf(believer.global_position.x - _player().global_position.x) < 78.0:
                                break
                        await get_tree().process_frame
                Input.action_release("move_right")
                await _tap("attack")              # strike one — all answer
                # the windup ring — then leap back out of the strike
                th = Time.get_ticks_msec()
                while Time.get_ticks_msec() - th < 6000 and is_instance_valid(believer):
                        if believer.state == believer.WINDUP:
                                break
                        await get_tree().process_frame
                await _wait(0.3)                  # read the ring
                Input.action_press("move_left")
                await _tap("jump")
                await _wait(0.32)
                Input.action_release("move_left")
                await _wait(0.5)
                # answer with two more
                for i in 2:
                        if not is_instance_valid(believer):
                                break
                        await _tap("attack")
                        await _wait(0.66)
                await _wait(1.3)                  # the group closes in
        else:
                await _wait(3.0)
        _seg_end()

        # ============================================================ 5. MARTYR
        # the boss: the shamble, the sweep, the roll under it, the verdict —
        # and the phase where the chains believe harder.
        await _room("act8", Vector2(450, 800))
        var boss: BoundMartyr = game.boss
        _seg_arm("martyr")
        if boss:
                await _wait(1.0)                  # it shambles toward you
                # first windup — read it, roll out of the sweep
                var th := Time.get_ticks_msec()
                while Time.get_ticks_msec() - th < 8000:
                        if boss.state == boss.WINDUP or boss.state == boss.ATTACK:
                                break
                        await get_tree().process_frame
                await _wait(0.18)
                Input.action_press("move_left")
                await _tap("roll")
                Input.action_release("move_left")
                await _wait(0.55)
                # punish the recovery
                th = Time.get_ticks_msec()
                Input.action_press("move_right")
                while Time.get_ticks_msec() - th < 4000:
                        if absf(boss.global_position.x - _player().global_position.x) < 108.0:
                                break
                        await get_tree().process_frame
                Input.action_release("move_right")
                for i in 3:
                        await _tap("attack")
                        await _wait(0.6)
                # force the phase break — the chains believe harder
                boss.hp = 590
                await _wait(2.4)                  # roar, shake, the phase card
                _skip_dialogue()
                await _wait(0.6)
                # the dash: phase two's new sentence — read it, slip it
                th = Time.get_ticks_msec()
                while Time.get_ticks_msec() - th < 12000:
                        if boss.state == boss.DASH_WINDUP:
                                break
                        await get_tree().process_frame
                await _wait(0.4)                  # the crouch tells you
                th = Time.get_ticks_msec()
                while Time.get_ticks_msec() - th < 2500:
                        if boss.state == boss.DASHING:
                                break
                        await get_tree().process_frame
                await _tap("roll")                # roll with the dash, out of its line
                await _wait(1.4)
        else:
                await _wait(3.0)
        _seg_end()

        print("WB-18 PROOFS DONE")
        get_tree().quit(0)
