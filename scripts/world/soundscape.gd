## SoundScape — THE PLACEMENT LAW OF SOUND. Every noise-making element the
## world-craft passes placed (braziers, machines, bells, chains, vents, damp
## spots, shedding records) now SPEAKS FROM ITS PLACE: an AudioStreamPlayer2D
## emitter hung at the element's position with distance falloff, so the ear
## walks the room the same way the eye does. Emitters ride the Ambient bus —
## when consistency falls and the world's air muffles, they muffle with it.
##
## The vermin of the back edge get a voice too: a scuttler breaking into
## flight may squeak — from where it stands.
##
## debug_draw renders THE SOUND MAP: every emitter as a halo inside its
## hearing radius, labeled — the aural landscape made visible for proofs.
class_name SoundScape
extends Node2D

const LOOP_PATHS := {
        "fire": "res://audio/ambient/amb_fire_loop.wav",
        "machine": "res://audio/ambient/amb_machine_loop.wav",
        "hiss": "res://audio/ambient/amb_hiss_loop.wav",
}

const ONE_SHOT_PATHS := {
        "drip": "res://audio/sfx/sfx_drip.wav",
        "squeak": "res://audio/sfx/sfx_squeak.wav",
        "page": "res://audio/sfx/sfx_page_rustle.wav",
        "chain": "res://audio/sfx/sfx_chain_creak.wav",
        "bell": "res://audio/sfx/sfx_bell_far.wav",
}

## decor kinds -> emitter recipe. loop beds hang where the element stands;
## ticks are one-shots on their own slow timers.
const KIND_RECIPES := {
        "brazier": {"loop": "fire", "vol": -13.0},
        "candles": {"loop": "fire", "vol": -19.0},
        "candelabra": {"loop": "fire", "vol": -17.0},
        "chandelier": {"loop": "fire", "vol": -17.0},
        "censer_swing": {"loop": "fire", "vol": -19.0},
        "censer": {"loop": "fire", "vol": -19.0},
        "bowl": {"loop": "fire", "vol": -21.0},
        "machine": {"loop": "machine", "vol": -15.0},
        "rotor": {"loop": "machine", "vol": -16.0},
        "heart": {"loop": "machine", "vol": -11.0},
        "terminal": {"loop": "machine", "vol": -20.0},
        "record_station": {"loop": "machine", "vol": -19.0},
        "vent": {"loop": "hiss", "vol": -17.0},
        "bell": {"tick": "bell", "vol": -12.0, "every": [22.0, 60.0]},
        "toll": {"tick": "bell", "vol": -12.0, "every": [26.0, 70.0]},
        "chain_hang": {"tick": "chain", "vol": -16.0, "every": [14.0, 38.0]},
        "chain_cluster": {"tick": "chain", "vol": -15.0, "every": [12.0, 32.0]},
        "cage_hang": {"tick": "chain", "vol": -17.0, "every": [16.0, 44.0]},
        "cage": {"tick": "chain", "vol": -17.0, "every": [18.0, 48.0]},
        "records": {"tick": "page", "vol": -16.0, "every": [9.0, 26.0]},
        "archive_wall": {"tick": "page", "vol": -16.0, "every": [11.0, 30.0]},
        "shelf": {"tick": "page", "vol": -18.0, "every": [13.0, 34.0]},
        "logbook": {"tick": "page", "vol": -18.0, "every": [15.0, 40.0]},
        "ledger": {"tick": "page", "vol": -18.0, "every": [15.0, 40.0]},
        "organ": {"tick": "bell", "vol": -15.0, "every": [40.0, 120.0]},
}

## warm lights (fire-colored room lights) become crackle emitters when no
## brazier-family decor already speaks within this radius (dedupe law)
const WARM_LIGHT_DEDUPE_R := 110.0
## hearing radius: past this the emitter is silent (px, ~half a screen+)
const HEARING_R := 640.0

var room_id := ""
var emitters: Array = []        # [{node, kind, pos, radius, kind_id}]
var _ticks: Array = []          # [{node, pos, sfx, vol, t, next}]
var _world_life: Node = null
var _squeak_cd := 0.0
var _was_fleeing := false
var _t := 0.0
var debug_draw := false

func setup(p_room_id: String, room_data: Dictionary, damp_spots: Array, p_world_life: Node = null) -> void:
        room_id = p_room_id
        _world_life = p_world_life
        var rng := RandomNumberGenerator.new()
        rng.seed = hash("soundscape:" + p_room_id)
        emitters.clear()
        _ticks.clear()

        # --- decor-driven emitters ---
        for item in room_data.get("decor", []):
                var kind := String(item.get("kind", ""))
                var recipe: Dictionary = KIND_RECIPES.get(kind, {})
                if recipe.is_empty():
                        continue
                var pos: Vector2 = item.get("pos", Vector2.ZERO)
                if recipe.has("loop"):
                        _spawn_loop(pos, kind, String(recipe["loop"]), float(recipe["vol"]), rng)
                elif recipe.has("tick"):
                        _spawn_tick(pos, kind, String(recipe["tick"]), float(recipe["vol"]),
                                        float(recipe["every"][0]), float(recipe["every"][1]), rng)

        # --- warm-light crackle (fires the lights painted, where no brazier speaks) ---
        for l in room_data.get("lights", []):
                var c: Color = l.get("color", Color.WHITE)
                if c.r > 0.6 and c.r > c.b + 0.15:
                        var pos: Vector2 = l.get("pos", Vector2.ZERO)
                        if not _near_kind(pos, ["brazier", "candles", "candelabra", "chandelier", "censer", "censer_swing", "bowl"], WARM_LIGHT_DEDUPE_R):
                                _spawn_loop(pos, "warm_light", "fire", -17.0, rng)

        # --- the undercity weeps from its damp spots ---
        for spot in damp_spots:
                var pos: Vector2 = spot if spot is Vector2 else Vector2(spot.get("x", 0.0), spot.get("y", 0.0))
                _spawn_tick(pos, "damp", "drip", -13.0, 4.0, 13.0, rng)

        z_index = 95
        set_process(true)

func _near_kind(pos: Vector2, kinds: Array, r: float) -> bool:
        for e in emitters:
                if kinds.has(e["kind"]):
                        if (e["pos"] as Vector2).distance_to(pos) <= r:
                                return true
        return false

func _spawn_loop(pos: Vector2, kind: String, loop_id: String, vol_db: float, rng: RandomNumberGenerator) -> void:
        var stream: AudioStreamWAV = load(LOOP_PATHS[loop_id])
        if stream == null:
                return
        stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
        stream.loop_begin = 0
        stream.loop_end = stream.data.size() / (4 if stream.stereo else 2)
        var p := AudioStreamPlayer2D.new()
        p.bus = "Ambient"
        p.stream = stream
        p.position = pos
        p.volume_db = vol_db + rng.randf_range(-1.5, 1.5)
        p.max_distance = HEARING_R
        p.area_mask = 1
        add_child(p)
        p.play()
        emitters.append({"node": p, "kind": kind, "pos": pos, "radius": HEARING_R, "kind_id": loop_id})

func _spawn_tick(pos: Vector2, kind: String, sfx: String, vol_db: float, lo: float, hi: float, rng: RandomNumberGenerator) -> void:
        var p := AudioStreamPlayer2D.new()
        p.bus = "Ambient"
        p.stream = load(ONE_SHOT_PATHS[sfx])
        p.position = pos
        p.volume_db = vol_db
        p.max_distance = HEARING_R
        add_child(p)
        _ticks.append({"node": p, "kind": kind, "pos": pos, "sfx": sfx, "vol": vol_db,
                        "t": rng.randf_range(lo, hi * 0.6), "next": [lo, hi]})

func _process(delta: float) -> void:
        _t += delta
        if _squeak_cd > 0.0:
                _squeak_cd -= delta
        # --- the world's elements keep their own time ---
        for tk in _ticks:
                tk["t"] -= delta
                if float(tk["t"]) <= 0.0:
                        var n: AudioStreamPlayer2D = tk["node"]
                        n.play()
                        var lo: float = tk["next"][0]
                        var hi: float = tk["next"][1]
                        tk["t"] = randf_range(lo, hi)
        # --- the vermin speak when they bolt ---
        if _world_life != null and _squeak_cd <= 0.0:
                var fleeing: bool = _world_life.any_scuttler_fleeing()
                if fleeing and not _was_fleeing:
                        _squeak_cd = randf_range(1.2, 3.0)
                        var bolted: Vector2 = _world_life.bolted_scuttler()
                        if bolted != Vector2.ZERO and randf() < 0.5:
                                _play_at(bolted, "squeak", -14.0)
                _was_fleeing = fleeing
        if debug_draw:
                queue_redraw()

func _play_at(pos: Vector2, sfx: String, vol_db: float) -> void:
        var p := AudioStreamPlayer2D.new()
        p.bus = "Ambient"
        p.stream = load(ONE_SHOT_PATHS[sfx])
        p.position = pos
        p.volume_db = vol_db
        p.max_distance = HEARING_R * 0.7
        add_child(p)
        p.play()
        p.finished.connect(p.queue_free)

func _count_kind(kinds: Array) -> int:
        var n := 0
        for e in emitters:
                if kinds.has(e["kind"]):
                        n += 1
        return n

func loop_count() -> int:
        return emitters.size()

func tick_count() -> int:
        return _ticks.size()

func _draw() -> void:
        ## THE SOUND MAP — the aural landscape, drawn for proofs. The rings are
        ## deliberately faint (the hearing field, not a fence); the emitter cores
        ## carry the read; the tick arcs are bright and thin.
        if not debug_draw:
                return
        for e in emitters:
                var pos: Vector2 = e["pos"]
                # the hearing field: a whisper of gold, never a wall
                draw_circle(pos, float(e["radius"]), Color(0.95, 0.85, 0.55, 0.05))
                draw_arc(pos, float(e["radius"]), 0.0, TAU, 64, Color(0.95, 0.85, 0.55, 0.20), 1.2)
                draw_arc(pos, float(e["radius"]) * 0.985, 0.0, TAU, 64, Color(0.95, 0.85, 0.55, 0.10), 1.0)
                var breathe := 0.5 + 0.5 * sin(_t * 1.6 + pos.x * 0.01)
                draw_circle(pos, 11.0 + 3.0 * breathe, Color(0.98, 0.92, 0.6, 0.40))
                draw_circle(pos, 4.5, Color(1.0, 0.98, 0.85, 0.95))
                draw_arc(pos, 17.0, 0.0, TAU, 20, Color(0.98, 0.92, 0.6, 0.5), 1.0)
        for tk in _ticks:
                var pos: Vector2 = tk["pos"]
                var cold := Color(0.55, 0.9, 0.95, 0.85)
                var frac := clampf(1.0 - float(tk["t"]) / maxf(1.0, float(tk["next"][1])), 0.0, 1.0)
                draw_arc(pos, 24.0, -PI * 0.5, -PI * 0.5 + TAU * frac, 16, cold, 2.5)
                draw_circle(pos, 3.0, cold)
                draw_arc(pos, 30.0, 0.0, TAU, 20, Color(0.55, 0.9, 0.95, 0.18), 1.0)
