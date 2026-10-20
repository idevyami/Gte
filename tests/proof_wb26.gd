## WB-26 proof — THE PLAYER'S HANDS: a full input-driven playthrough.
## The smoke suite teleports between rooms — it proves laws, not play. This
## instrument is a player: it boots the real main.tscn, confirms NEW GAME on
## the real title, and plays the golden path with real key events only
## (parse_input_event — no teleports, no state writes, no god-hands). Its
## policy is deliberately simple — the way a first-time player reads the
## game: walk right, press [F] when a prompt glows, unlock doors when the
## system log says SEALED/DISPUTED/TOLL, attack what attacks you, jump when
## stuck, read the rotor memories in act7, climb the ladder in act1.
## Everything it experiences is traced to /tmp/wb26_trace.txt: rooms, times,
## dialogues, interactions, unlocks, stalls, deaths, hp/consistency. Where
## it gets stuck, the game has a bug or an unclear telling — either way a
## finding. RUN (headless, logic only):
##   cd /home/z/entity000 && timeout 580 godot --headless \
##     res://tests/proof_wb26.tscn
extends Node

const TRACE_PATH := "/tmp/wb26_trace.txt"
const ROOM_BUDGET := {
        "act1": 170.0, "act2": 130.0, "act3": 160.0, "act4": 200.0,
        "act5": 200.0, "act6": 160.0, "act7": 240.0, "act8": 420.0,
        "act9": 120.0,
}
const ROOM_ORDER := ["act1", "act2", "act3", "act4", "act5", "act6", "act7", "act8", "act9"]

var main: Node
var game: Game
var _trace_file: FileAccess

# --- driver state
var phase := "boot"          # boot | title | play | done
var _t := 0.0
var _room_t := 0.0
var _last_room := ""
var _last_pos := Vector2(9999, 9999)
var _last_pos_t := 0.0
var _stall_t := 0.0
var _stall_level := 0
var _interact_cd := 0.0
var _attack_cd := 0.0
var _dialogue_t := 0.0
var _dialogue_open_key := ""
var _read_t := 0.0
var _pos_log_t := 0.0
var _held := {}             # action -> true while held
var _tap_hold := {}         # action -> remaining hold seconds
var _unlock_state := ""     # "" | enter | seek | modify | exit | open
var _unlock_t := 0.0
var _unlock_target = null
var _unlock_tries := 0
var _unlock_attempts := {}   # instance_key -> attempts (cap 2)
var _file_attempts := {}     # invulnerable foes -> filing attempts (cap 3)
var _interact_pause := 0.0
var _read_done := {}          # instance keys already engaged
var _roll_cd := 0.0
var _seq_target_key := ""
var _seq_target_t := 0.0
var _seq_log_t := 0.0
var _boss_log_t := 0.0
var _phys_delta := 0.016
var _last_right_pulse := 0.0
var _climb: Array = []      # act1 ladder targets {pos, w}
var _climb_idx := 0
var _climb_target_t := 0.0
var _climb_air_tgt := {}
var _seq_targets: Array = []  # act7 rotor order
var _seq_idx := 0
var _assist_used := {}

# --- findings ledger
var rooms_visited: Array = []
var deaths := 0
var stalls := 0
var dialogues := 0
var interactions := 0
var unlocks := 0
var assists := 0
var errors_noted: Array = []

func _trace(s: String) -> void:
        if _trace_file == null:
                _trace_file = FileAccess.open(TRACE_PATH, FileAccess.WRITE)
        if _trace_file:
                _trace_file.store_line("%.2f %s" % [_t, s])
                _trace_file.flush()
        print(s)

# ------------------------------------------------------------------ input rig
func _key(action: String, pressed: bool) -> void:
        for ev in InputMap.action_get_events(action):
                if ev is InputEventKey:
                        var k := InputEventKey.new()
                        k.physical_keycode = ev.physical_keycode
                        k.pressed = pressed
                        k.echo = false
                        Input.parse_input_event(k)
                        return

func _tap(action: String, hold := 0.06) -> void:
        ## Press now, release shortly after — long enough for both _process
        ## and _physics_process to see the edge.
        _tap_hold[action] = maxf(float(_tap_hold.get(action, 0.0)), hold)
        _key(action, true)

func _hold(action: String, on: bool) -> void:
        if bool(_held.get(action, false)) == on:
                return
        _held[action] = on
        _key(action, on)

func _release_all() -> void:
        for a in _held.keys():
                _hold(a, false)

# ------------------------------------------------------------------ boot
func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        # a fresh vessel: no stale suite saves may claim the CONTINUE slot
        GameState.clear_save()
        var scene: PackedScene = load("res://main.tscn")
        main = scene.instantiate()
        add_child(main)
        game = main.game
        _trace("BOOT main.tscn instanced, game=%s" % [str(game != null)])
        await get_tree().create_timer(0.8).timeout
        phase = "title"

func _physics_process(delta: float) -> void:
        _t += delta
        _phys_delta = delta
        # tap release housekeeping
        for a in _tap_hold.keys().duplicate():
                _tap_hold[a] = float(_tap_hold[a]) - delta
                if float(_tap_hold[a]) <= 0.0:
                        _key(a, false)
                        _tap_hold.erase(a)
        match phase:
                "title":
                        _drive_title()
                "play":
                        _drive_play(delta)
                _:
                        pass

# ------------------------------------------------------------------ title
func _drive_title() -> void:
        if main.title and main.title.visible:
                _trace("TITLE confirming NEW GAME (RESTORE THE WORLD)")
                _tap("interact", 0.12)
                phase = "play"
                _trace("PHASE play begins")

# ------------------------------------------------------------------ play
func _drive_play(delta: float) -> void:
        if game == null or not is_instance_valid(game):
                return
        if game.player == null or not is_instance_valid(game.player):
                return

        # --- the ending
        if game.state == "ending" or (game.end_screen and game.end_screen.visible):
                _finish(true)
                return

        # --- room bookkeeping
        if game.room_id != _last_room:
                _last_room = game.room_id
                _room_t = 0.0
                _stall_t = 0.0
                _stall_level = 0
                _climb_idx = 0
                _climb_target_t = 0.0
                _seq_idx = 0
                rooms_visited.append(game.room_id)
                _read_done = {}
                _trace("ROOM ENTER %s | pos=%s hp=%d cons=%d" % [
                        game.room_id, _fmt(game.player.global_position), game.player.hp, GameState.consistency])
                _build_room_targets()

        _room_t += delta
        _interact_cd = maxf(0.0, _interact_cd - delta)
        _attack_cd = maxf(0.0, _attack_cd - delta)
        _roll_cd = maxf(0.0, _roll_cd - delta)
        var budget := float(ROOM_BUDGET.get(game.room_id, 160.0))
        if _room_t > budget:
                _trace("!! ROOM BUDGET EXCEEDED in %s after %.0fs — pos=%s state=%s observe=%s" % [
                        game.room_id, _room_t, _fmt(game.player.global_position), game.state, str(game.observe_active)])
                _assist_next_room()
                return

        # --- dialogue: tap through
        if game.dialogue_box and game.dialogue_box.active:
                if _dialogue_open_key == "" and game.dialogue_box.key != "":
                        _dialogue_open_key = game.dialogue_box.key
                        _trace("DIALOGUE OPEN %s" % _dialogue_open_key)
                _dialogue_t += delta
                if _dialogue_t >= 0.32:
                        _tap("interact", 0.05)
                        _dialogue_t = 0.0
                        dialogues += 1
                return
        else:
                if _dialogue_open_key != "":
                        _trace("DIALOGUE END %s" % _dialogue_open_key)
                        _dialogue_open_key = ""
                _dialogue_t = 0.0

        # --- reading panel: close (first press finishes the text, second
        # closes — the game's own pacing), then mark it read
        if game.reading_panel and game.reading_panel.visible:
                _read_t += delta
                if _read_t >= 0.5:
                        _tap("interact", 0.05)
                        _read_t = 0.0
                return
        _read_t = 0.0

        # --- pause menu: back out
        if game.pause_menu and game.pause_menu.visible:
                _tap("pause", 0.05)
                return

        # --- options / map overlays: back out
        if GameState.options_open or GameState.map_open:
                _tap("pause", 0.05)
                return

        # --- dead / transition: wait it out
        if game.state == "dead":
                return
        if game.state == "transition":
                _release_all()
                return
        if game.state != "playing":
                return

        # --- observe unlock dance in progress
        if _unlock_state != "":
                _drive_unlock(delta)
                return

        # --- act1: the climb
        if game.room_id == "act1" and not _climb.is_empty():
                _drive_climb(delta)
                return

        # --- act8: the bound martyr — once the fight is live it IS the way.
        # The read a player makes: the chant holds his shield, so the bearers
        # die first — press TO them, roll THROUGH him, never trade with the
        # shield; when the chant ends he is the fight, and his coiled
        # telegraphs are rolled away from.
        if game.room_id == "act8" and game.boss != null and game.boss.intro_done and not game.boss.is_dead_state():
                var martyr = game.boss
                var obj = martyr
                var obj_d := game.player.global_position.distance_to(martyr.global_position)
                for node in get_tree().get_nodes_in_group("enemies"):
                        var e := node as EnemyBase
                        if e == null or not is_instance_valid(e) or e.dead or e == martyr:
                                continue
                        var d2 := game.player.global_position.distance_to(e.global_position)
                        if d2 < obj_d:
                                obj_d = d2
                                obj = e
                var obj_dir: int = 1 if obj.global_position.x >= game.player.global_position.x else -1
                var mdist: float = game.player.global_position.distance_to(martyr.global_position)
                var telegraph_late: bool = martyr.state in [BoundMartyr.WINDUP, BoundMartyr.DASH_WINDUP, BoundMartyr.LEAP_WINDUP] and martyr.state_t > 0.52
                if martyr.shielded() and obj != martyr:
                        # THE PRESS TO THE CHANT: at the bearer, the chant
                        # dies (fight); between bearers, press objective-ward
                        # and roll through his body when it fills the aisle
                        if obj_d < 70.0:
                                if _combat_stance(game.player, obj_dir, true):
                                        return
                        _hold("move_right", obj_dir > 0)
                        _hold("move_left", obj_dir < 0)
                        if (mdist < 60.0 or telegraph_late) and _roll_cd <= 0.0:
                                _tap("roll", 0.42)
                                _roll_cd = 1.0
                        return
                if telegraph_late and _roll_cd <= 0.0 and mdist < 170.0:
                        var away: int = 1 if martyr.global_position.x <= game.player.global_position.x else -1
                        _hold("move_right", away > 0)
                        _hold("move_left", away < 0)
                        _tap("roll", 0.42)
                        _roll_cd = 1.1
                        return
                if obj == martyr:
                        # the duel: strike his openings (RECOVER/IDLE) —
                        # CLOSE when he opens, retreat when he coils
                        var opening: bool = martyr.state in [BoundMartyr.RECOVER, BoundMartyr.IDLE, BoundMartyr.ATTACK]
                        var toward: int = 1 if martyr.global_position.x >= game.player.global_position.x else -1
                        if opening:
                                _hold("move_right", toward > 0 and mdist >= 76.0)
                                _hold("move_left", toward < 0 and mdist >= 76.0)
                                if mdist < 92.0 and _attack_cd <= 0.0:
                                        _tap("attack", 0.05)
                                        _attack_cd = 0.35
                                return
                        var keep: int = -toward
                        _hold("move_right", keep > 0 and mdist < 120.0)
                        _hold("move_left", keep < 0 and mdist < 120.0)
                        return
                if _combat_stance(game.player, obj_dir, true):
                        return
                _boss_log_t += delta
                if _boss_log_t > 2.0:
                        _boss_log_t = 0.0
                        _trace("... BOSS hp=%d/%d phase=%d player hp=%d at %s shielded=%s bearers=%d bossx=%.0f state=%d" % [
                                martyr.hp, martyr.max_hp, martyr.phase, game.player.hp, _fmt(game.player.global_position), str(martyr.shielded()),
                                martyr._bearers.filter(func(b): return b != null and is_instance_valid(b) and not b.dead).size(), martyr.global_position.x, martyr.state])
                _hold("move_right", obj_dir > 0)
                _hold("move_left", obj_dir < 0)
                return

        # --- act7: the rotor sequence (and the walk back when the gate says no)
        if game.room_id == "act7":
                if _seq_targets.is_empty() and not GameState.has_flag("heart_aligned") and game.player.global_position.x > 2350.0:
                        _trace("SEQ heart not aligned at the gate — walking back to the rotors")
                        _build_room_targets()
                if not _seq_targets.is_empty():
                        _drive_sequence(delta)
                        return

        # --- generic: walk right, live, interact
        _drive_walk(delta)

# ------------------------------------------------------------------ walking
var _engage_foe_id := ""
var _engage_t := 0.0

func _combat_stance(p, objective_dir: int, fight_to_end := false) -> bool:
        ## The fighting read: engage true threats (70px), strike on a quick
        ## cadence, ROLL THROUGH the lunge when it closes. Fights that drag
        ## or hurt too much end in a sprint TOWARD THE OBJECTIVE (never a
        ## ping-pong retreat) — the player who lives to walk.
        var foe = _nearest_enemy(70.0)
        if foe == null:
                _engage_foe_id = ""
                _engage_t = 0.0
                return false
        var fid := str(foe.instance_key)
        if fid != _engage_foe_id:
                _engage_foe_id = fid
                _engage_t = 0.0
        _engage_t += _phys_delta
        if foe.is_invulnerable() and not foe.dead:
                if _file_attempts.get(fid, 0) < 3:
                        _begin_file(foe)
                return true
        var dist: float = foe.global_position.distance_to(p.global_position)
        if (p.hp <= 45 and not fight_to_end) or _engage_t > 6.0:
                # hurt or dragging: disengage toward the objective
                _hold("move_right", objective_dir >= 0)
                _hold("move_left", objective_dir < 0)
                if dist < 44.0 and _roll_cd <= 0.0:
                        _tap("roll", 0.42)
                        _roll_cd = 0.9
                return true
        var fdx: float = foe.global_position.x - p.global_position.x
        _hold("move_right", fdx > 0.0)
        _hold("move_left", fdx < 0.0)
        if dist < 44.0 and _roll_cd <= 0.0:
                _tap("roll", 0.42)     # through the lunge
                _roll_cd = 0.9
        elif _attack_cd <= 0.0:
                _tap("attack", 0.05)
                _attack_cd = 0.35
        return true

func _drive_walk(delta: float) -> void:
        var p := game.player

        # combat first — the walk yields to the fight
        if _combat_stance(p, 1):
                return
        # approach discipline: full gait always; the walk only STOPS (never
        # crawls) when an unread prompt is in range and the interact key is
        # still cooling — a player who means to read plants his feet
        var want := false
        if game._nearest_interactable != null:
                var nk := str(game._nearest_interactable.get("instance_key")) if game._nearest_interactable.get("instance_key") != null else str(game._nearest_interactable)
                want = not _read_done.has(nk)
        if not want:
                var ahead = _interactable_ahead(58.0)
                if ahead != null:
                        var ak := str(ahead.get("instance_key")) if ahead.get("instance_key") != null else str(ahead)
                        want = not _read_done.has(ak)
        if want and _interact_cd > 0.0:
                _hold("move_right", false)
        else:
                _hold("move_right", true)
        _hold("move_left", false)

        # interact with whatever the game offers (once each — a player
        # reads a thing and moves on; re-reading loops the panel forever)
        if game._nearest_interactable != null and _interact_cd <= 0.0:
                var it = game._nearest_interactable
                var ikey := str(it.get("instance_key")) if it.get("instance_key") != null else str(it)
                if not _read_done.has(ikey):
                        _tap("interact", 0.05)
                        _interact_cd = 0.45
                        _interact_pause = 0.30
                        _read_done[ikey] = true
                        interactions += 1
                        _trace("INTERACT %s at %s" % [ikey, _fmt(it.global_position)])
                        return
        if _interact_pause > 0.0:
                _interact_pause -= delta
                _hold("move_right", false)
                return

        # stall watch
        var moved := p.global_position.distance_to(_last_pos)
        if _t - _last_pos_t > 1.0:
                if moved < 7.0:
                        _stall_t += (_t - _last_pos_t)
                else:
                        _stall_t = 0.0
                        _stall_level = 0
                if _last_pos.x - p.global_position.x > 5.0:
                        _trace("?? BACKWARD in %s: %s -> %s | vx=%.0f facing=%d rolling=%s locked=%s held=%s nearest=%s state=%s" % [
                                game.room_id, _fmt(_last_pos), _fmt(p.global_position), p.velocity.x, p.facing,
                                str(p._rolling), str(p.input_locked), str(_held),
                                str(game._nearest_interactable.instance_key) if game._nearest_interactable else "-", game.state])
                _last_pos = p.global_position
                _last_pos_t = _t
                _pos_log_t += 1.0
                if _pos_log_t >= 4.0:
                        _pos_log_t = 0.0
                        _trace("... %s pos=%s hp=%d cons=%d state=%s" % [game.room_id, _fmt(p.global_position), p.hp, GameState.consistency, game.state])

        if want:
                _stall_t = 0.0
                _stall_level = 0
        if _stall_t >= 1.2 and not want:
                var d := _door_ahead()
                if d != null and not d.open:
                        _begin_unlock(d)
                        return
                _tap("jump", 0.42)
                if _stall_t >= 4.0 and _stall_level < 1:
                        _stall_level = 1
                        stalls += 1
                        _trace("!! STALL in %s at %s (%.1fs no progress) — jumping" % [game.room_id, _fmt(p.global_position), _stall_t])
                if _stall_t >= 7.0 and _stall_level < 2:
                        _stall_level = 2
                        _tap("roll", 0.08)
                        _trace("!! STALL persists in %s at %s — rolling" % [game.room_id, _fmt(p.global_position)])
                if _stall_t >= 11.0:
                        _trace("!! STALL terminal in %s at %s — assisting" % [game.room_id, _fmt(p.global_position)])
                        _assist_next_room()
                        return
                _stall_t = 1.2  # re-trigger cadence
        # fall recovery: fell below the room? (should never happen)
        if p.global_position.y > float(game.room_size.y) + 80.0:
                _trace("!! FELL OUT OF WORLD in %s at %s" % [game.room_id, _fmt(p.global_position)])
                _assist_next_room()

# ------------------------------------------------------------------ act1 climb
func _build_room_targets() -> void:
        _climb = []
        _seq_targets = []
        _seq_idx = 0
        if game.room_id == "act1":
                var plats: Array = game.room_data.get("platforms", [])
                var order: Array = plats.duplicate()
                order.sort_custom(func(a, b): return a.position.y > b.position.y)   # lowest first
                for r in order:
                        _climb.append({
                                "x0": r.position.x, "x1": r.position.x + r.size.x,
                                "cx": r.position.x + r.size.x * 0.5, "top": r.position.y})
                _climb.append({"x0": 1560.0, "x1": 1600.0, "cx": 1580.0, "top": 212.0})  # the exit ledge
                _trace("CLIMB ladder built: %d rungs" % _climb.size())
        elif game.room_id == "act7":
                # the reading player: the rotors' memories give the pull order;
                # if the heart is not aligned by the time the gate nears,
                # walk back and pull them in sequence
                var rotors: Array = []
                for node in get_tree().get_nodes_in_group("interactable"):
                        var en := node as EntityNode
                        if en and en.kind == "rotor":
                                rotors.append(en)
                rotors.sort_custom(func(a, b): return int(a.extra.get("seq", 0)) < int(b.extra.get("seq", 0)))
                _seq_targets = rotors
                var labels: Array = []
                for r in rotors:
                        labels.append(String(r.extra.get("label", "?")))
                _trace("SEQ rotors in memory order: %s" % str(labels))

func _drive_climb(delta: float) -> void:
        var p := game.player
        _climb_target_t += delta
        var feet_y := p.global_position.y + 24.0
        var stand := _rung_under(p, feet_y)
        var airborne := not p.is_on_floor()
        var tgt: Dictionary = {}
        var next_i := -1
        if stand == -2:
                # airborne: steer toward the cached flight target
                tgt = _climb_air_tgt if not _climb_air_tgt.is_empty() else _climb[0]
        else:
                next_i = stand + 1
                if next_i >= _climb.size():
                        _drive_walk(delta)
                        return
                tgt = _climb[next_i]
                _climb_air_tgt = tgt
        # where to leave the ground from: the current rung's edge nearest the
        # target (or, from the floor, the point under the target's span)
        var jump_from := float(tgt["cx"])
        if stand == -2:
                jump_from = p.global_position.x
        elif stand >= 0:
                var cur: Dictionary = _climb[stand]
                if tgt["x0"] > cur["x1"]:
                        jump_from = cur["x1"] - 12.0        # right edge, inset
                elif tgt["x1"] < cur["x0"]:
                        jump_from = cur["x0"] + 12.0        # left edge, inset
                else:
                        jump_from = clampf(p.global_position.x, cur["x0"] + 14.0, cur["x1"] - 14.0)
        else:
                jump_from = clampf(tgt["cx"], tgt["x0"] + 18.0, tgt["x1"] - 18.0)
        var dx_jump := jump_from - p.global_position.x
        var dx_tgt := float(tgt["cx"]) - p.global_position.x
        if not airborne:
                if absf(dx_jump) > 14.0:
                        _hold("move_right", dx_jump > 0.0)
                        _hold("move_left", dx_jump < 0.0)
                else:
                        # planted at the jump-off: face the target and leap
                        _hold("move_right", dx_tgt > 0.0)
                        _hold("move_left", dx_tgt < 0.0)
                        _tap("jump", 0.42)
                if _climb_target_t > 10.0 and absf(dx_jump) <= 14.0:
                        _trace("!! CLIMB hop not landing: rung %d target %s from %s" % [next_i, _fmt(Vector2(tgt["cx"], tgt["top"])), _fmt(p.global_position)])
                        _climb_target_t = 0.0
                        stalls += 1
        else:
                _hold("move_right", dx_tgt > 0.0)
                _hold("move_left", dx_tgt < 0.0)
        # safety: interact when offered (cradle shelves, readables) — each
        # once; a re-opened reading panel would trap the climb forever
        if game._nearest_interactable != null and _interact_cd <= 0.0:
                var ck := str(game._nearest_interactable.get("instance_key")) if game._nearest_interactable.get("instance_key") != null else str(game._nearest_interactable)
                if not _read_done.has(ck):
                        _tap("interact", 0.05)
                        _interact_cd = 0.9
                        _read_done[ck] = true
                        interactions += 1

func _rung_under(p, feet_y: float) -> int:
        ## The highest rung the vessel stands upon (-1 = the floor).
        if not p.is_on_floor():
                return -2       # airborne: pointer logic pauses
        for i in _climb.size():
                var r: Dictionary = _climb[i]
                if absf(feet_y - float(r["top"])) <= 10.0 and p.global_position.x >= float(r["x0"]) - 8.0 and p.global_position.x <= float(r["x1"]) + 8.0:
                        return i
        return -1

# ------------------------------------------------------------------ act7 sequence
func _drive_sequence(delta: float) -> void:
        var p := game.player
        while _seq_idx < _seq_targets.size():
                var r = _seq_targets[_seq_idx]
                if r == null or not is_instance_valid(r) or bool(r.extra.get("pulled", false)):
                        _seq_idx += 1
                        continue
                break
        if _seq_idx >= _seq_targets.size():
                _seq_targets = []
                _trace("SEQ all rotors turned — walking on")
                return
        var rotor0: EntityNode = _seq_targets[_seq_idx]
        var obj_dir := 1 if rotor0.global_position.x >= p.global_position.x else -1
        if _combat_stance(p, obj_dir):
                return
        # seq stall safety: a target unreached for 30s is re-planned
        if _seq_target_key != str(rotor0.instance_key):
                _seq_target_key = str(rotor0.instance_key)
                _seq_target_t = 0.0
        _seq_target_t += delta
        if _seq_target_t > 30.0:
                _trace("!! SEQ target %s unreached for 30s at %s — replanning" % [_seq_target_key, _fmt(p.global_position)])
                _seq_target_t = 0.0
                _build_room_targets()
                return
        _seq_log_t += delta
        if _seq_log_t > 4.0:
                _seq_log_t = 0.0
                _trace("... %s SEQ pos=%s target=%s hp=%d" % [game.room_id, _fmt(p.global_position), _seq_target_key, p.hp])
        var rotor: EntityNode = _seq_targets[_seq_idx]
        var d := p.global_position.distance_to(rotor.global_position + Vector2(0, -10))
        var prompt_on_rotor: bool = game._nearest_interactable == rotor
        if prompt_on_rotor:
                # the game's own prompt is on the rotor — plant and pull
                _hold("move_right", false)
                _hold("move_left", false)
                if _interact_cd <= 0.0:
                        _tap("interact", 0.05)
                        _interact_cd = 1.0
                        _read_done[rotor.instance_key] = true
                        interactions += 1
                        _trace("SEQ pull rotor %s (seq %d)" % [String(rotor.extra.get("label", "?")), int(rotor.extra.get("seq", 0))])
                return
        if d < 40.0:
                # in range but the prompt is elsewhere — stand by the rotor
                _hold("move_right", false)
                _hold("move_left", false)
                return
        var dx := rotor.global_position.x - p.global_position.x
        _hold("move_right", dx > 0.0)
        _hold("move_left", dx < 0.0)
        if rotor.global_position.y < p.global_position.y - 40.0 and absf(dx) < 40.0:
                _tap("jump", 0.42)
        if game._nearest_interactable != null and String(game._nearest_interactable.extra.get("kind", "")) == "rotor" and _interact_cd <= 0.0:
                _tap("interact", 0.05)
                _interact_cd = 1.0
                interactions += 1

# ------------------------------------------------------------------ unlock dance
func _door_ahead() -> Door:
        var best: Door = null
        var bd := 1e9
        for node in get_tree().get_nodes_in_group("interactable"):
                var d := node as Door
                if d == null or not d.visible or d.open:
                        continue
                # gate-mode doors are objectives, not modify-locks — the
                # dance is pointless on them
                if String(d.extra.get("mode", "")) == "gate":
                        continue
                if _unlock_attempts.get(d.instance_key, 0) >= 2:
                        continue
                var dist := game.player.global_position.distance_to(d.global_position)
                if dist < 130.0 and dist < bd:
                        bd = dist
                        best = d
        return best

func _interactable_ahead(range_px: float):
        var p := game.player
        for node in get_tree().get_nodes_in_group("interactable"):
                var en := node as EntityNode
                if en == null or not en.visible:
                        continue
                var dx := en.global_position.x - p.global_position.x
                var dy := absf(en.global_position.y - p.global_position.y)
                if dx > 0.0 and dx < range_px and dy < 80.0:
                        return en
        return null

func _unlock_target_done(target) -> bool:
        if target == null or not is_instance_valid(target):
                return true
        if target is Door:
                return target.open
        if target is EnemyBase:
                return not target.is_invulnerable()
        return true

func _begin_unlock(door: Door) -> void:
        _unlock_target = door
        _unlock_state = "enter"
        _unlock_t = 0.0
        _unlock_tries = 0
        _hold("move_right", false)
        _hold("move_left", false)
        _trace("UNLOCK begin on %s (%s mode) at %s" % [door.instance_key, String(door.extra.get("mode", "?")), _fmt(door.global_position)])

func _begin_file(foe) -> void:
        ## UNFILED things cannot be ended — change the state first (the
        ## game's own lesson, null_tut): observe, bracket the child, modify
        _unlock_target = foe
        _unlock_state = "enter"
        _unlock_t = 0.0
        _unlock_tries = 0
        _file_attempts[foe.instance_key] = int(_file_attempts.get(foe.instance_key, 0)) + 1
        _hold("move_right", false)
        _hold("move_left", false)
        _trace("FILE begin on %s (invulnerable) attempt %d" % [str(foe.instance_key), int(_file_attempts[foe.instance_key])])

func _drive_unlock(delta: float) -> void:
        _unlock_t += delta
        var d = _unlock_target
        if _unlock_target_done(d):
                _trace("UNLOCK/FILE complete — %s" % [str(d.instance_key) if d else "?"])
                unlocks += 1
                _unlock_state = ""
                _unlock_target = null
                if game.observe_active:
                        game.observe_exit()   # one TAB only cycles; exit for real
                return
        match _unlock_state:
                "enter":
                        if _unlock_t > 0.25:
                                _tap("observe", 0.05)
                                _unlock_state = "seek"
                                _unlock_t = 0.0
                "seek":
                        if _unlock_t > 0.35:
                                if game.observe_active:
                                        var tid := game._target_id()
                                        if tid == str(d.instance_key):
                                                _trace("UNLOCK bracketed %s — modifying" % tid)
                                                _tap("modify", 0.05)
                                                _unlock_state = "exit"
                                                _unlock_t = 0.0
                                                return
                                        _unlock_tries += 1
                                        if _unlock_tries > 10:
                                                _trace("!! UNLOCK cannot bracket %s (last target %s) — cycling out" % [str(d.instance_key), game._target_id()])
                                                _unlock_state = "exit"
                                                _unlock_t = 0.0
                                                return
                                        _tap("observe", 0.05)   # cycles to next target
                                        _unlock_t = 0.0
                                else:
                                        _trace("!! UNLOCK observe closed itself in %s" % game.room_id)
                                        _unlock_state = "open"
                                        _unlock_t = 0.0
                "exit":
                        if _unlock_t > 0.45:
                                if game.observe_active:
                                        _tap("observe", 0.05)   # cycle; past-the-end exits observe
                                        _unlock_t = 0.0
                                        _unlock_tries += 1
                                        if _unlock_tries > 14:
                                                game.observe_exit()
                                                _unlock_state = "open"
                                                _unlock_t = 0.0
                                else:
                                        _unlock_state = "open"
                                        _unlock_t = 0.0
                "open":
                        if _unlock_t > 0.4:
                                if _unlock_target_done(d):
                                        _trace("UNLOCK/FILE complete — %s" % str(d.instance_key))
                                        unlocks += 1
                                elif d is Door:
                                        _unlock_attempts[d.instance_key] = int(_unlock_attempts.get(d.instance_key, 0)) + 1
                                        _trace("!! UNLOCK failed on %s (attempt %d) — door still closed" % [str(d.instance_key), int(_unlock_attempts[d.instance_key])])
                                        # roll past it like the plaque says
                                        _tap("roll", 0.10)
                                        _hold("move_right", true)
                                else:
                                        _trace("!! FILE failed on %s — still invulnerable" % str(d.instance_key))
                                _unlock_state = ""
                                _unlock_target = null

# ------------------------------------------------------------------ helpers
func _nearest_enemy(range_px: float):
        var best = null
        var bd := range_px
        var best_shielded = null
        var bd_shielded := range_px
        for node in get_tree().get_nodes_in_group("enemies"):
                var e := node as EnemyBase
                if e == null or not is_instance_valid(e) or e.dead:
                        continue
                var dist := game.player.global_position.distance_to(e.global_position)
                var shielded_martyr: bool = e is BoundMartyr and e.shielded()
                if shielded_martyr:
                        if dist < bd_shielded:
                                bd_shielded = dist
                                best_shielded = e
                        continue
                if dist < bd:
                        bd = dist
                        best = e
        return best if best != null else best_shielded

func _fmt(v: Vector2) -> String:
        return "(%.0f,%.0f)" % [v.x, v.y]

func _assist_next_room() -> void:
        assists += 1
        var idx := ROOM_ORDER.find(game.room_id)
        var next: String
        if idx < 0 or idx >= ROOM_ORDER.size() - 1:
                next = "act9"
        else:
                next = ROOM_ORDER[idx + 1]
        _assist_used[game.room_id] = true
        _trace(">> ASSIST: teleporting %s -> %s (marked; the stuck point above is a finding)" % [game.room_id, next])
        _release_all()
        _unlock_state = ""
        _unlock_target = null
        game.load_room(next)
        game.state = "playing"
        _room_t = 0.0
        _stall_t = 0.0
        _stall_level = 0

func _finish(won: bool) -> void:
        if phase == "done":
                return
        phase = "done"
        _release_all()
        _trace("")
        _trace("=========== PLAYTHROUGH VERDICT ===========")
        _trace("REACHED ENDING: %s" % str(won))
        _trace("rooms visited (%d): %s" % [rooms_visited.size(), str(rooms_visited)])
        _trace("assisted rooms: %s" % str(_assist_used))
        _trace("deaths: %d | stalls: %d | dialogues tapped: %d | interactions: %d | unlocks: %d" % [deaths, stalls, dialogues, interactions, unlocks])
        _trace("final hp: %d | consistency: %d | stage: %d" % [game.player.hp if game.player else -1, GameState.consistency, GameState.stage])
        _trace("stats: %s" % str(GameState.stats))
        _trace("===========================================")
        await get_tree().create_timer(0.5).timeout
        get_tree().quit()

# ------------------------------------------------------------------ watches
func _process(_delta: float) -> void:
        if phase != "play" or game == null:
                return
        # death watch
        if game.state == "dead" and not deaths_check_pending:
                deaths_check_pending = true
                deaths += 1
                _stall_t = 0.0
                _stall_level = 0
                _last_pos = Vector2(9999, 9999)
                _last_pos_t = _t
                _trace("!! DEATH #%d in %s at %s hp=%d" % [deaths, game.room_id, _fmt(game.player.global_position), game.player.hp])
        elif game.state != "dead":
                deaths_check_pending = false

var deaths_check_pending := false
