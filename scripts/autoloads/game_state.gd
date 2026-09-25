## GameState — run state: consistency (HUNTED model), stages, flags, fragments,
## statistics, save/load, and the programmatic input map.
extends Node

const SAVE_PATH := "user://save.json"

# --- Run state ---------------------------------------------------------------
var consistency: int = E0.CONSISTENCY_START
var stage: int = 1
var observe_installed: bool = false
var boss_defeated: bool = false
var game_finished: bool = false
var current_room: String = ""
var run_started_at: int = 0
## debug: F9 — swap painted character art for the procedural rigs
var debug_no_sprites: bool = false

# Flags worth naming (anything else is free-form):
const F_RELIQ_CARRIED := "relic_carried"
const F_JOINED_RITUAL := "joined_ritual"
const F_WARD_BROKEN := "ward_broken"
const F_PENITENT_SEEN := "penitent_seen"
const F_HEART_ALIGNED := "heart_aligned"
const F_TOLL_BROKEN := "toll_broken"
const F_ARCHIVE_FIXED := "archive_fixed"
const F_INTRO_DONE := "intro_done"
const F_SEEN_CONSISTENCY_MSG := {}  # unused guard dict for one-shot system msgs

var flags: Dictionary = {}
var fragments: Array[String] = []      # ordered ids of found fragments
var one_shots: Dictionary = {}         # trigger keys already fired
var property_overrides: Dictionary = {}

# --- Stats (all real — shown on the end screen) ------------------------------
var stats := {
        "edits": 0,              # property modifications
        "spent": 0,              # total consistency spent
        "deaths": 0,
        "dissipated": 0,         # enemies destroyed
        "anchors": 0,            # anchor communions
        "fragments": 0,
}

# --- HUNTED spawn pacing ------------------------------------------------------
var correction_timer := 0.0
var censor_timer := 0.0
var censor_active: Node = null

signal consistency_low_warning

# ------------------------------------------------------------------ lifecycle
func _ready() -> void:
        _setup_input_map()
        _reset_run()
        EventBus.fragment_found.connect(_on_fragment_found)

func _reset_run() -> void:
        consistency = E0.CONSISTENCY_START
        stage = 1
        observe_installed = false
        boss_defeated = false
        game_finished = false
        current_room = ""
        flags = {}
        fragments = []
        one_shots = {}
        property_overrides = {}
        stats = {"edits": 0, "spent": 0, "deaths": 0, "dissipated": 0, "anchors": 0, "fragments": 0}
        run_started_at = Time.get_ticks_msec()
        correction_timer = 0.0
        censor_timer = 0.0
        censor_active = null

func new_game() -> void:
        _reset_run()

# ------------------------------------------------------------------ input map
func _setup_input_map() -> void:
        _add_key("move_left", [KEY_A, KEY_LEFT])
        _add_key("move_right", [KEY_D, KEY_RIGHT])
        _add_key("move_up", [KEY_W, KEY_UP])
        _add_key("move_down", [KEY_S, KEY_DOWN])
        _add_key("jump", [KEY_SPACE])
        _add_key("roll", [KEY_SHIFT])
        _add_key("attack", [KEY_J])
        _add_key("observe", [KEY_TAB])
        _add_key("modify", [KEY_E])
        _add_key("interact", [KEY_F, KEY_ENTER])
        _add_key("pause", [KEY_ESCAPE])
        _add_mouse("attack", MOUSE_BUTTON_LEFT)
        # Gamepad: A/confirm = jump/interact, X = attack, B = roll, Y = observe.
        _pad("jump", JOY_BUTTON_A)
        _pad("interact", JOY_BUTTON_A)
        _pad("attack", JOY_BUTTON_X)
        _pad("roll", JOY_BUTTON_B)
        _pad("observe", JOY_BUTTON_Y)
        _pad("pause", JOY_BUTTON_START)
        _pad_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
        _pad_axis("move_right", JOY_AXIS_LEFT_X, 1.0)

func _add_key(action: String, keys: Array) -> void:
        if not InputMap.has_action(action):
                InputMap.add_action(action, 0.28)
        for k in keys:
                var ev := InputEventKey.new()
                ev.physical_keycode = k
                InputMap.action_add_event(action, ev)

func _add_mouse(action: String, btn: MouseButton) -> void:
        if not InputMap.has_action(action):
                InputMap.add_action(action, 0.28)
        var ev := InputEventMouseButton.new()
        ev.button_index = btn
        InputMap.action_add_event(action, ev)

func _pad(action: String, btn: JoyButton) -> void:
        if not InputMap.has_action(action):
                return
        var ev := InputEventJoypadButton.new()
        ev.button_index = btn
        InputMap.action_add_event(action, ev)

func _pad_axis(action: String, axis: JoyAxis, value: float) -> void:
        if not InputMap.has_action(action):
                return
        var ev := InputEventJoypadMotion.new()
        ev.axis = axis
        ev.axis_value = value
        InputMap.action_add_event(action, ev)

# ------------------------------------------------------------------ consistency
func spend(amount: int, reason: String) -> void:
        ## Reality manipulation is the ONLY thing that drains consistency.
        var old := consistency
        consistency = maxi(0, consistency - amount)
        stats["spent"] += amount
        EventBus.consistency_spent.emit(amount, reason)
        EventBus.consistency_changed.emit(consistency)
        _check_stage(old)
        FX.tear_pulse(0.8 + 0.15 * amount)
        AudioManager.play_sfx("sfx_modify")

func restore(amount: int, source: String) -> void:
        var old := consistency
        consistency = mini(100, consistency + amount)
        EventBus.consistency_changed.emit(consistency)
        _check_stage(old)

func _check_stage(old_consistency: int) -> void:
        var new_stage := E0.stage_for(consistency)
        if new_stage != stage:
                stage = new_stage
                EventBus.consistency_stage_changed.emit(stage)
                AudioManager.update_degradation(stage)

func stage_name() -> String:
        return E0.STAGE_NAMES[stage - 1]

# ------------------------------------------------------------------ flags / fragments
func set_flag(flag: String, value: bool = true) -> void:
        flags[flag] = value
        EventBus.flag_set.emit(flag, value)

func has_flag(flag: String) -> bool:
        return flags.get(flag, false)

func fire_once(key: String) -> bool:
        ## Returns true the first time a given trigger key fires, then false forever.
        if one_shots.has(key):
                return false
        one_shots[key] = true
        return true

const FRAGMENT_DEFS := {
        "FRAGMENT_01": {
                "code": "FRAGMENT 01", "title": "THE LITURGY OF THE MARTYR",
                "integrity": "INTEGRITY 100%", "note": "\u201cHe gave himself gladly.\u201d",
        },
        "FRAGMENT_02": {
                "code": "FRAGMENT 02", "title": "ARCHIVE LOG 7-11",
                "integrity": "CORRUPTED", "note": "entity_000_001 did not\u2026 [UNREADABLE]",
        },
        "FRAGMENT_03": {
                "code": "FRAGMENT 03", "title": "MEASURER FIELD NOTE",
                "integrity": "INTEGRITY 88%", "note": "\u201cDo not tell them what the engine eats.\u201d",
        },
        "FRAGMENT_04": {
                "code": "FRAGMENT 04", "title": "YOUR OWN DESIGNATION",
                "integrity": "CONTRADICTED", "note": "ENTITY_000_818. You are not the first.",
        },
}

func _on_fragment_found(fragment_id: String) -> void:
        if not fragments.has(fragment_id):
                fragments.append(fragment_id)
                stats["fragments"] = fragments.size()

func has_fragment(fragment_id: String) -> bool:
        return fragments.has(fragment_id)

# ------------------------------------------------------------------ save / load
func has_save() -> bool:
        return FileAccess.file_exists(SAVE_PATH)

func save_game(room_id: String, player_pos: Vector2, hp: int, anchor_id: String) -> bool:
        var data := {
                "version": 1,
                "room": room_id,
                "pos": {"x": player_pos.x, "y": player_pos.y},
                "hp": hp,
                "consistency": consistency,
                "observe_installed": observe_installed,
                "boss_defeated": boss_defeated,
                "flags": flags,
                "fragments": fragments,
                "one_shots": one_shots,
                "stats": stats,
                "anchor": anchor_id,
                "communed": _communed,
                "overrides": EntityDB.export_overrides(),
                "saved_at": Time.get_unix_time_from_system(),
        }
        var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
        if f == null:
                return false
        f.store_string(JSON.stringify(data, "\t"))
        f.close()
        return true

var _communed: Array = []   # anchor ids whose first communion already happened

func anchor_communion(anchor_id: String) -> int:
        ## First use of an anchor restores +12 consistency — but THE DESIGN does not
        ## reassure the deeply inconsistent: below 60 it withholds restoration.
        if _communed.has(anchor_id):
                return 0
        _communed.append(anchor_id)
        stats["anchors"] += 1
        if consistency >= 60:
                restore(E0.ANCHOR_RESTORE, anchor_id)
                return E0.ANCHOR_RESTORE
        return 0

func load_game() -> Dictionary:
        ## Returns {} on failure. Does NOT touch the live scene — Game applies this.
        if not has_save():
                return {}
        var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
        if f == null:
                return {}
        var data: Variant = JSON.parse_string(f.get_as_text())
        f.close()
        if typeof(data) != TYPE_DICTIONARY:
                return {}
        return data

func apply_save(data: Dictionary) -> void:
        _reset_run()
        consistency = int(data.get("consistency", E0.CONSISTENCY_START))
        stage = E0.stage_for(consistency)
        observe_installed = bool(data.get("observe_installed", false))
        boss_defeated = bool(data.get("boss_defeated", false))
        flags = data.get("flags", {})
        fragments = []
        for frag in data.get("fragments", []):
                fragments.append(String(frag))
        one_shots = data.get("one_shots", {})
        stats = data.get("stats", stats)
        _communed = data.get("communed", [])
        property_overrides = data.get("overrides", {})
        EntityDB.import_overrides(property_overrides)
        EventBus.consistency_changed.emit(consistency)
        EventBus.consistency_stage_changed.emit(stage)

func clear_save() -> void:
        if has_save():
                DirAccess.remove_absolute(SAVE_PATH)

# ------------------------------------------------------------------ hunted pacing
func hunted_update(delta: float, room_allows_hunt: bool) -> Dictionary:
        ## Decides whether to spawn corrections / the censor this frame.
        ## Returns {"correction": bool, "censor": bool} — the world acts on it.
        var out := {"correction": false, "censor": false}
        if not room_allows_hunt:
                return out
        if stage >= 4 and censor_active == null:
                censor_timer += delta
                if censor_timer > 7.0:
                        censor_timer = 0.0
                        out["censor"] = true
        if stage >= 4:
                var period := 9.0 if stage == 4 else (4.5 if stage == 5 else 3.0)
                correction_timer += delta
                if correction_timer > period:
                        correction_timer = 0.0
                        out["correction"] = true
        return out
