## WB-19 "THE THREE BEATS" proof — the motion re-audit of the four reads the
## WB-18 audit left open: the chain's cadence identity (each beat its own
## clock), the jump's gather (the crouch before the leave), the flock's edges
## (converging robes keep their catch-light), the dash's smear (the lunge
## spends its image). Same instrument as WB-18: authored beats played in real
## time under Xvfb, framebuffer captured by WALL CLOCK (~30fps JPEG) with
## per-frame ffconcat durations so the MP4s play at true speed.
## Segments: chain / jump / flock / dash. Frames land in
## screenshots/wb19/<seg>/f*.jpg plus list.txt for ffmpeg encoding.
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
var _log_t0 := 0.0
var _mon_last := ""

## EVENT LOG + MONITOR: the render narrates what actually happened (enemy
## state/hp transitions, chain indices) — stills and statistics can both
## lie; the log cannot (learned the hard way this pass)
func _elog(msg: String) -> void:
        print("EVT %8.2f [%s] %s" % [Time.get_ticks_msec() / 1000.0 - _log_t0, _seg, msg])

func _monitor(enemy: Node) -> void:
        var last := ""
        while is_instance_valid(enemy):
                var st := "?"
                if enemy is Hollow:
                        st = "hp=%d state=%d" % [enemy.hp, enemy.state]
                elif enemy is Believer:
                        st = "hp=%d state=%d sep=%.2f" % [enemy.hp, enemy.state, enemy.sep_k]
                elif enemy is BoundMartyr:
                        st = "hp=%d state=%d ph=%d ghosts=%d" % [enemy.hp, enemy.state, enemy.phase, enemy.dash_hist.size()]
                st += " atk=%d px=%.0f" % [game.player._attack_idx, game.player.global_position.x]
                if st != last:
                        _elog(st)
                        last = st
                await get_tree().process_frame
        _elog("enemy gone")

func _ready() -> void:
        DirAccess.make_dir_recursive_absolute("res://screenshots/wb19")
        RenderingServer.frame_post_draw.connect(_on_frame_post_draw)
        # segment filter: `godot ... -- --only=dash` renders just that beat
        # (the full suite outgrew the sandbox render window)
        for arg in OS.get_cmdline_user_args():
                if arg.begins_with("--only="):
                        _only = arg.substr(7)
        _run.call_deferred()

var _only := ""

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
                # guard: a stall must not freeze the film — cap at 250ms
                _cap_durs.append(clampf(dt, 0.01, 0.25))
        var img := get_viewport().get_texture().get_image()
        var fname := "f%06d.jpg" % _cap_idx
        img.save_jpg("res://screenshots/wb19/%s/%s" % [_seg, fname], JPG_Q)
        _cap_names.append(fname)
        _cap_idx += 1

func _seg_arm(name: String) -> void:
        DirAccess.make_dir_recursive_absolute("res://screenshots/wb19/" + name)
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
        var f := FileAccess.open("res://screenshots/wb19/%s/list.txt" % _seg, FileAccess.WRITE)
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
        ## Every wait is dialogue-immune: a room trigger that opens a census
        ## record mid-beat is read and filed, never frozen on (the chain
        ## segment's first render spent 29s locked in Oren's greeting —
        ## the fix is systemic, not local)
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
        _log_t0 = Time.get_ticks_msec() / 1000.0
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

        # --- the four beats, renderable singly via --only=<name>
        if _only == "" or _only == "chain":
                await _chain_duel()
        if _only == "" or _only == "jump":
                await _jump_gather()
        if _only == "" or _only == "flock":
                await _flock_press()
        if _only == "" or _only == "dash":
                await _dash_smear()

        print("WB-19 PROOFS DONE")
        get_tree().quit(0)

func _chain_duel() -> void:
            # starts BEYOND the measurer's greeting trigger (x 980-1060) —
            # the street's own record must not interrupt the duel
            await _room("act3", Vector2(1200, 700))
            var hollow: Hollow = null
            for node in get_tree().get_nodes_in_group("enemies"):
                    if node is Hollow:
                            hollow = node
                            break
            _monitor.call(hollow)
            _seg_arm("chain")
            if hollow:
                    # close the distance until the duel begins
                    var th := Time.get_ticks_msec()
                    Input.action_press("move_right")
                    while Time.get_ticks_msec() - th < 7000 and is_instance_valid(hollow):
                            if absf(hollow.global_position.x - _player().global_position.x) < 150.0:
                                    break
                            await get_tree().process_frame
                    Input.action_release("move_right")
                    # let it stalk in and telegraph; slip the lunge
                    th = Time.get_ticks_msec()
                    while Time.get_ticks_msec() - th < 6000 and is_instance_valid(hollow):
                            if hollow.state == hollow.TELEGRAPH:
                                    break
                            await get_tree().process_frame
                    await _wait(0.42)
                    th = Time.get_ticks_msec()
                    while Time.get_ticks_msec() - th < 2000 and is_instance_valid(hollow):
                            if hollow.state == hollow.LUNGE:
                                    break
                            await get_tree().process_frame
                    Input.action_press("move_left")
                    await _tap("roll")
                    Input.action_release("move_left")
                    await _wait(0.85)
                    # close and deliver the sentence — natural rhythm, all three
                    # beats (the press cadence lets each cd expire: the chain
                    # breathes between its beats)
                    th = Time.get_ticks_msec()
                    Input.action_press("move_right")
                    while Time.get_ticks_msec() - th < 5000 and is_instance_valid(hollow):
                            if absf(hollow.global_position.x - _player().global_position.x) < 84.0:
                                    break
                            await get_tree().process_frame
                    Input.action_release("move_right")
                    for chain_round in 2:
                            if not is_instance_valid(hollow):
                                    break
                            for i in 3:
                                    if not is_instance_valid(hollow):
                                            break
                                    _elog("tap attack r%d.%d" % [chain_round, i])
                                    await _tap("attack")
                                    await _wait(0.5)
                            await _wait(0.7)          # the breath between sentences
                    await _wait(1.0)                  # the dispersal
            else:
                    await _wait(3.0)
            _seg_end()

func _jump_gather() -> void:
            await _room("act1", Vector2(520, 620))
            _seg_arm("jump")
            await _wait(1.4)                          # breathe: the wake settles
            await _hold("move_right", 1.35)           # the walk, footfalls answering
            await _wait(0.3)
            await _run_jump("move_right", 0.72)       # gather, leave, land on the shelf
            await _wait(0.4)
            await _run_jump("move_right", 0.68)       # and the second
            await _wait(0.45)
            await _tap("jump")                        # the idle hop — the gather reads alone
            await _wait(0.35)
            await _tap("jump")                        # once more, unhurried
            await _wait(0.4)
            # step off the ledge, land heavy — the fall's answer
            Input.action_press("move_right")
            await _wait(0.16)
            Input.action_release("move_right")
            await _wait(1.1)
            _seg_end()

func _flock_press() -> void:
            await _room("act5", Vector2(520, 780))
            var believer: Believer = null
            for node in get_tree().get_nodes_in_group("enemies"):
                    if node is Believer:
                            believer = node
                            break
            _monitor.call(believer)
            _seg_arm("flock")
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
                    # stand ground: the flock closes in around the vessel
                    await _wait(2.2)
                    # a measured retreat — the convergence follows, edges lit
                    await _hold("move_left", 0.85)
                    await _wait(1.6)
                    await _hold("move_left", 0.5)
                    await _wait(1.8)                  # the press at its tightest
            else:
                    await _wait(3.0)
            _seg_end()

func _dash_smear() -> void:
            await _room("act8", Vector2(450, 800))
            var boss: BoundMartyr = game.boss
            _monitor.call(boss)
            _seg_arm("dash")
            if boss:
                    await _wait(1.0)                  # it shambles toward you
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
                    # force the phase break — the chains believe harder
                    boss.hp = 590
                    await _wait(2.4)
                    _skip_dialogue()
                    await _wait(0.6)
                    # the dash: read the crouch, then slip the line — twice,
                    # so the smear reads in both directions
                    for dash_round in 2:
                            th = Time.get_ticks_msec()
                            while Time.get_ticks_msec() - th < 14000:
                                    if boss.state == boss.DASH_WINDUP:
                                            break
                                    await get_tree().process_frame
                            await _wait(0.4)          # the crouch tells you
                            th = Time.get_ticks_msec()
                            while Time.get_ticks_msec() - th < 2500:
                                    if boss.state == boss.DASHING:
                                            break
                                    await get_tree().process_frame
                            await _tap("roll")        # roll with the dash, out of its line
                            await _wait(1.6)          # the smear settles into recovery
            else:
                    await _wait(3.0)
            _seg_end()
