## AudioManager — buses, music states, LAYERED ambient beds (A primary / B
## secondary / D the whisper), positional world emitters ride the Ambient bus,
## chant channel, sfx pool, far-field ambient events, and consistency-driven
## degradation: the Music muffles, the WORLD'S AIR muffles with it (Ambient
## lowpass closes per stage) — but the whisper bed lives on its own Dread bus
## that never filters: as reality thins, the real world goes dull and the
## whispers stay sharp.
extends Node

const MUSIC_PATHS := {
        "title": "res://audio/music/music_title.wav",
        "amb_a": "res://audio/music/music_ambient_a.wav",
        "amb_b": "res://audio/music/music_ambient_b.wav",
        "amb_c": "res://audio/music/music_ambient_c.wav",
        "combat": "res://audio/music/music_combat.wav",
        "boss_p1": "res://audio/music/music_boss_p1.wav",
        "boss_p2": "res://audio/music/music_boss_p2.wav",
        "boss_p3": "res://audio/music/music_boss_p3.wav",
        "aftermath": "res://audio/music/music_aftermath.wav",
        "death": "res://audio/music/music_death_sting.wav",
}

const AMBIENT_PATHS := {
        "wind": "res://audio/ambient/amb_wind_loop.wav",
        "machine": "res://audio/ambient/amb_machine_loop.wav",
        "choir": "res://audio/ambient/amb_choir_loop.wav",
        "fire": "res://audio/ambient/amb_fire_loop.wav",
        "void": "res://audio/ambient/amb_void_loop.wav",
        "whisper": "res://audio/ambient/amb_whisper_loop.wav",
        "cityfar": "res://audio/ambient/amb_cityfar_loop.wav",
        "hiss": "res://audio/ambient/amb_hiss_loop.wav",
}

## The far-field ambience palette -> stream. Events are one-shots the world
## speaks rarely; they ride the Ambient bus so they muffle with the air.
const EVENT_PATHS := {
        "bell_far": "res://audio/sfx/sfx_bell_far.wav",
        "gust": "res://audio/sfx/sfx_gust.wav",
        "choir_swell": "res://audio/sfx/sfx_choir_swell.wav",
        "clank_far": "res://audio/sfx/sfx_clank_far.wav",
        "organ_chord": "res://audio/sfx/sfx_organ_chord.wav",
}

const SFX_DIR := "res://audio/sfx/"

## The whisper rises with the HUNTED stage (linear target for layer D).
const WHISPER_BY_STAGE := [0.0, 0.0, 0.10, 0.18, 0.28, 0.40]
## The world's own air muffles as consistency falls (Ambient bus LP, Hz) —
## faster than the score: the room dulls before the music does.
const AMBIENT_CUTOFFS := [20000.0, 13000.0, 8000.0, 5000.0, 3200.0, 2000.0]

var _music: AudioStreamPlayer
var _ambient: AudioStreamPlayer          # layer A — the primary bed
var _ambient_b: AudioStreamPlayer        # layer B — the secondary bed
var _ambient_c: AudioStreamPlayer        # layer C — the deep bed
var _ambient_d: AudioStreamPlayer        # layer D — the whisper (Dread bus)
var _chant: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_bus := -1
var _music_lp: AudioEffectLowPassFilter
var _ambient_lp: AudioEffectLowPassFilter
var _current_music := ""
var _current_ambient := ""
var _current_ambient_b := ""
var _current_ambient_c := ""
var _music_target := 0.55
var _ambient_target := 0.0
var _ambient_b_target := 0.0
var _ambient_c_target := 0.0
var _whisper_target := 0.0
var _combat_overlay: AudioStreamPlayer
var _heartbeat: AudioStreamPlayer
var _event: AudioStreamPlayer           # far-field ambient events

# --- ambient event scheduler (the city speaks, rarely) ---
var _event_palette: Array = []
var _event_palette_ids: Array = []
var _event_timer := 0.0
var _event_min_delay := 18.0
var _event_max_delay := 55.0
var _events_enabled := true
var _event_rng := RandomNumberGenerator.new()
var _last_event_id := ""

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        _event_rng.seed = 0x5c17a11
        _setup_buses()
        _setup_players()

func _setup_buses() -> void:
        AudioServer.set_bus_name(0, "Master")
        _make_bus("Music")
        _make_bus("Ambient")
        _make_bus("SFX")
        _make_bus("Chant")
        _make_bus("Dread")
        _music_bus = AudioServer.get_bus_index("Music")
        _music_lp = AudioEffectLowPassFilter.new()
        _music_lp.cutoff_hz = 20000.0
        _music_lp.resonance = 0.2
        AudioServer.add_bus_effect(_music_bus, _music_lp)
        var amb_bus := AudioServer.get_bus_index("Ambient")
        _ambient_lp = AudioEffectLowPassFilter.new()
        _ambient_lp.cutoff_hz = 20000.0
        _ambient_lp.resonance = 0.2
        AudioServer.add_bus_effect(amb_bus, _ambient_lp)

func _make_bus(bus_name: String) -> void:
        if AudioServer.get_bus_index(bus_name) == -1:
                AudioServer.add_bus()
                var idx := AudioServer.bus_count - 1
                AudioServer.set_bus_name(idx, bus_name)
                AudioServer.set_bus_send(idx, "Master")

func _setup_players() -> void:
        _music = AudioStreamPlayer.new()
        _music.bus = "Music"
        add_child(_music)
        _ambient = AudioStreamPlayer.new()
        _ambient.bus = "Ambient"
        add_child(_ambient)
        _ambient_b = AudioStreamPlayer.new()
        _ambient_b.bus = "Ambient"
        add_child(_ambient_b)
        _ambient_c = AudioStreamPlayer.new()
        _ambient_c.bus = "Ambient"
        add_child(_ambient_c)
        _ambient_d = AudioStreamPlayer.new()
        _ambient_d.bus = "Dread"
        add_child(_ambient_d)
        _chant = AudioStreamPlayer.new()
        _chant.bus = "Chant"
        _chant.volume_db = -6.0
        add_child(_chant)
        _combat_overlay = AudioStreamPlayer.new()
        _combat_overlay.bus = "Music"
        _combat_overlay.volume_db = -60.0
        add_child(_combat_overlay)
        _heartbeat = AudioStreamPlayer.new()
        _heartbeat.bus = "SFX"
        _heartbeat.volume_db = -7.0
        add_child(_heartbeat)
        _event = AudioStreamPlayer.new()
        _event.bus = "Ambient"
        add_child(_event)
        for i in 10:
                var p := AudioStreamPlayer.new()
                p.bus = "SFX"
                add_child(p)
                _sfx_pool.append(p)

# ------------------------------------------------------------------ loading
func _load_loop(path: String) -> AudioStreamWAV:
        var s: AudioStreamWAV = load(path)
        if s == null:
                push_error("AudioManager: missing " + path)
                return null
        # Files are self-looping (phase-locked + crossfaded tails) — enable wrap.
        s.loop_mode = AudioStreamWAV.LOOP_FORWARD
        s.loop_begin = 0
        var bytes_per_frame := 2
        if s.stereo:
                bytes_per_frame = 4
        if s.format == AudioStreamWAV.FORMAT_8_BITS:
                bytes_per_frame /= 2
        elif s.format == AudioStreamWAV.FORMAT_16_BITS:
                pass
        s.loop_end = s.data.size() / bytes_per_frame
        return s

# ------------------------------------------------------------------ control
func play_music(id: String, fade := 0.8) -> void:
        if id == _current_music:
                return
        _current_music = id
        if id.is_empty():
                _music_target = 0.0
                return
        var stream := _load_loop(MUSIC_PATHS.get(id, ""))
        if stream == null:
                return
        _music.stream = stream
        _music.play()
        _music_target = 0.55
        _music.volume_db = linear_to_db(maxf(0.02, _music_target * (1.0 - fade)))

## LAYERED BEDS: the room's air is a stack (A primary / B secondary / C deep).
## The whisper layer D is stage-driven, not room-driven — the dread rises
## with the HUNTED model, everywhere.
func play_ambient_layers(layers: Array) -> void:
        var ids := ["", "", ""]
        var vols := [0.0, 0.0, 0.0]
        for i in mini(3, layers.size()):
                if layers[i] is Dictionary:
                        ids[i] = String(layers[i].get("id", ""))
                        vols[i] = float(layers[i].get("vol", 0.3))
        _layer_a(ids[0], vols[0])
        _layer_b(ids[1], vols[1])
        _layer_c(ids[2], vols[2])

func _layer_a(id: String, vol: float) -> void:
        if id == _current_ambient:
                _ambient_target = vol
                return
        _current_ambient = id
        if id.is_empty():
                _ambient_target = 0.0
                _ambient.stop()
                return
        var stream := _load_loop(AMBIENT_PATHS.get(id, ""))
        if stream == null:
                return
        _ambient.stream = stream
        _ambient.play()
        _ambient_target = vol
        _ambient.volume_db = linear_to_db(0.05)

func _layer_b(id: String, vol: float) -> void:
        if id == _current_ambient_b:
                _ambient_b_target = vol
                return
        _current_ambient_b = id
        if id.is_empty():
                _ambient_b_target = 0.0
                _ambient_b.stop()
                return
        var stream := _load_loop(AMBIENT_PATHS.get(id, ""))
        if stream == null:
                return
        _ambient_b.stream = stream
        _ambient_b.play()
        _ambient_b_target = vol
        _ambient_b.volume_db = linear_to_db(0.05)

func _layer_c(id: String, vol: float) -> void:
        if id == _current_ambient_c:
                _ambient_c_target = vol
                return
        _current_ambient_c = id
        if id.is_empty():
                _ambient_c_target = 0.0
                _ambient_c.stop()
                return
        var stream := _load_loop(AMBIENT_PATHS.get(id, ""))
        if stream == null:
                return
        _ambient_c.stream = stream
        _ambient_c.play()
        _ambient_c_target = vol
        _ambient_c.volume_db = linear_to_db(0.05)

## Legacy single-bed API — maps onto layer A and clears B/C.
func play_ambient(id: String, vol := 0.5) -> void:
        _layer_a(id, vol)
        _layer_b("", 0.0)
        _layer_c("", 0.0)

## THE FAR FIELD: the district's rare events (a bell, a gust, a far clank).
## min/max bound the scheduler's silence; the world never hurries.
func configure_events(palette: Array, min_delay := 18.0, max_delay := 55.0) -> void:
        _event_palette.clear()
        _event_palette_ids.clear()
        for e in palette:
                var eid := String(e)
                if EVENT_PATHS.has(eid):
                        _event_palette.append(EVENT_PATHS[eid])
                        _event_palette_ids.append(eid)
        _event_min_delay = maxf(4.0, min_delay)
        _event_max_delay = maxf(_event_min_delay + 1.0, max_delay)
        _reschedule_event(true)

func _reschedule_event(fresh := false) -> void:
        var span := _event_max_delay - _event_min_delay
        _event_timer = _event_min_delay + (_event_rng.randf() * span if not fresh else span * (0.35 + 0.3 * _event_rng.randf()))

func _tick_events(delta: float) -> void:
        if not _events_enabled or _event_palette.is_empty():
                return
        _event_timer -= delta
        if _event_timer > 0.0:
                return
        # pick a stream (avoid the same event twice in a row when there is a choice)
        var pick := _event_rng.randi_range(0, _event_palette.size() - 1)
        if _event_palette.size() > 1 and _event_palette_ids[pick] == _last_event_id:
                pick = (pick + 1) % _event_palette.size()
        _last_event_id = _event_palette_ids[pick]
        if _event.stream != load(_event_palette[pick]):
                _event.stream = load(_event_palette[pick])
        _event.volume_db = linear_to_db(0.34)
        _event.pitch_scale = 1.0
        _event.play()
        _reschedule_event()

func set_chant(active: bool) -> void:
        if active and _chant.stream == null:
                var stream := _load_loop(SFX_DIR + "sfx_chant_loop.wav")
                if stream != null:
                        _chant.stream = stream
                        _chant.play()
        elif not active and _chant.playing:
                _chant.stop()

func set_combat_layer(active: bool) -> void:
        if active and not _combat_overlay.playing:
                var stream := _load_loop(MUSIC_PATHS["combat"])
                if stream != null:
                        _combat_overlay.stream = stream
                        _combat_overlay.play()
        _combat_overlay.volume_db = -2.0 if active else -60.0

func play_sfx(sfx_name: String, vol_db := 0.0, pitch_jitter := true) -> void:
        if not sfx_name.begins_with("sfx_"):
                sfx_name = "sfx_" + sfx_name
        var path := SFX_DIR + sfx_name + ".wav"
        if not FileAccess.file_exists(path):
                push_warning("AudioManager: missing sfx " + sfx_name)
                return
        for p in _sfx_pool:
                if not p.playing:
                        p.stream = load(path)
                        p.volume_db = vol_db
                        p.pitch_scale = randf_range(0.97, 1.03) if pitch_jitter else 1.0
                        p.play()
                        return
        # All busy — steal the first.
        _sfx_pool[0].stream = load(path)
        _sfx_pool[0].volume_db = vol_db
        _sfx_pool[0].play()

func play_death_sting() -> void:
        var path := MUSIC_PATHS["death"]
        var s: AudioStreamWAV = load(path)
        if s != null:
                s.loop_mode = AudioStreamWAV.LOOP_DISABLED
                _music.stream = s
                _music.play()
                _music_target = 0.55

# ------------------------------------------------------------------ settings
func apply_volumes(s: Dictionary) -> void:
        ## Options screen volumes -> AudioServer buses (linear 0..1 -> dB).
        _set_bus_vol("Master", float(s.get("master", 1.0)))
        _set_bus_vol("Music", float(s.get("music", 1.0)))
        _set_bus_vol("Ambient", float(s.get("ambient", 1.0)))
        _set_bus_vol("SFX", float(s.get("sfx", 1.0)))
        _set_bus_vol("Chant", float(s.get("sfx", 1.0)))
        # the whisper is air — it answers the ambience slider
        _set_bus_vol("Dread", float(s.get("ambient", 1.0)))

func _set_bus_vol(bus_name: String, linear: float) -> void:
        var idx := AudioServer.get_bus_index(bus_name)
        if idx < 0:
                return
        AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0001, 1.0)))
        AudioServer.set_bus_mute(idx, linear <= 0.001)

func set_heartbeat(active: bool) -> void:
        ## Low-HP dread: a slow lub-dub under everything.
        if active and not _heartbeat.playing:
                var stream := _load_loop(SFX_DIR + "sfx_heartbeat.wav")
                if stream != null:
                        _heartbeat.stream = stream
                        _heartbeat.play()
        elif not active and _heartbeat.playing:
                _heartbeat.stop()

# ------------------------------------------------------------------ degradation
func update_degradation(stage: int) -> void:
        ## Consistency warps the soundscape itself: the lower it falls, the more
        ## the score AND THE AIR are muffled and slowed (ancient machinery failing)
        ## — while the whisper bed sharpens. The real world recedes; the other
        ## one leans in.
        if _music_lp == null:
                return
        var cutoffs := [20000.0, 14000.0, 9000.0, 6000.0, 3800.0, 2200.0]
        _music_lp.cutoff_hz = cutoffs[clampi(stage - 1, 0, 5)]
        if _ambient_lp != null:
                _ambient_lp.cutoff_hz = AMBIENT_CUTOFFS[clampi(stage - 1, 0, 5)]
        _whisper_target = WHISPER_BY_STAGE[clampi(stage - 1, 0, 5)]
        if _whisper_target > 0.0 and not _ambient_d.playing:
                var stream := _load_loop(AMBIENT_PATHS["whisper"])
                if stream != null:
                        _ambient_d.stream = stream
                        _ambient_d.volume_db = linear_to_db(0.02)
                        _ambient_d.play()
        elif _whisper_target <= 0.0 and _ambient_d.playing:
                _ambient_d.stop()
        var pitches := [1.0, 1.0, 0.985, 0.97, 0.955, 0.94]
        var target: float = pitches[clampi(stage - 1, 0, 5)]
        var tween := create_tween().set_ignore_time_scale()
        tween.tween_method(func(v: float) -> void:
                _music.pitch_scale = v
                _ambient.pitch_scale = v
                _ambient_b.pitch_scale = v
                _ambient_c.pitch_scale = v
        , (_music.pitch_scale + _ambient.pitch_scale) / 2.0, target, 2.0)

func _process(delta: float) -> void:
        # Gentle fades toward targets — no clicks.
        var m := db_to_linear(_music.volume_db)
        m = lerpf(m, _music_target, minf(1.0, delta * 2.2))
        _music.volume_db = linear_to_db(maxf(0.001, m))
        var a := db_to_linear(_ambient.volume_db)
        a = lerpf(a, _ambient_target, minf(1.0, delta * 1.6))
        _ambient.volume_db = linear_to_db(maxf(0.001, a))
        var b := db_to_linear(_ambient_b.volume_db)
        b = lerpf(b, _ambient_b_target, minf(1.0, delta * 1.6))
        _ambient_b.volume_db = linear_to_db(maxf(0.001, b))
        var c := db_to_linear(_ambient_c.volume_db)
        c = lerpf(c, _ambient_c_target, minf(1.0, delta * 1.6))
        _ambient_c.volume_db = linear_to_db(maxf(0.001, c))
        var d := db_to_linear(_ambient_d.volume_db)
        d = lerpf(d, _whisper_target, minf(1.0, delta * 0.5))
        _ambient_d.volume_db = linear_to_db(maxf(0.001, d))
        _tick_events(delta)
