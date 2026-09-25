## AudioManager — buses, music states, ambient layers, chant channel, sfx pool,
## and consistency-driven degradation (lowpass + pitch drop on Music).
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
}

const SFX_DIR := "res://audio/sfx/"

var _music: AudioStreamPlayer
var _ambient: AudioStreamPlayer
var _chant: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_bus := -1
var _music_lp: AudioEffectLowPassFilter
var _current_music := ""
var _current_ambient := ""
var _music_target := 0.55
var _ambient_target := 0.0
var _combat_overlay: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	_setup_players()

func _setup_buses() -> void:
	AudioServer.set_bus_name(0, "Master")
	_make_bus("Music")
	_make_bus("Ambient")
	_make_bus("SFX")
	_make_bus("Chant")
	_music_bus = AudioServer.get_bus_index("Music")
	_music_lp = AudioEffectLowPassFilter.new()
	_music_lp.cutoff_hz = 20000.0
	_music_lp.resonance = 0.2
	AudioServer.add_bus_effect(_music_bus, _music_lp)

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
	_chant = AudioStreamPlayer.new()
	_chant.bus = "Chant"
	_chant.volume_db = -6.0
	add_child(_chant)
	_combat_overlay = AudioStreamPlayer.new()
	_combat_overlay.bus = "Music"
	_combat_overlay.volume_db = -60.0
	add_child(_combat_overlay)
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

func play_ambient(id: String, vol := 0.5) -> void:
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

# ------------------------------------------------------------------ degradation
func update_degradation(stage: int) -> void:
	## Consistency warps the music itself: the lower it falls, the more the
	## score is muffled and slowed. Ancient machinery failing.
	if _music_lp == null:
		return
	var cutoffs := [20000.0, 14000.0, 9000.0, 6000.0, 3800.0, 2200.0]
	_music_lp.cutoff_hz = cutoffs[clampi(stage - 1, 0, 5)]
	var pitches := [1.0, 1.0, 0.985, 0.97, 0.955, 0.94]
	var target: float = pitches[clampi(stage - 1, 0, 5)]
	var tween := create_tween().set_ignore_time_scale()
	tween.tween_method(func(v: float) -> void:
		_music.pitch_scale = v
		_ambient.pitch_scale = v
	, (_music.pitch_scale + _ambient.pitch_scale) / 2.0, target, 2.0)

func _process(delta: float) -> void:
	# Gentle fades toward targets — no clicks.
	var m := db_to_linear(_music.volume_db)
	m = lerpf(m, _music_target, minf(1.0, delta * 2.2))
	_music.volume_db = linear_to_db(maxf(0.001, m))
	var a := db_to_linear(_ambient.volume_db)
	a = lerpf(a, _ambient_target, minf(1.0, delta * 1.6))
	_ambient.volume_db = linear_to_db(maxf(0.001, a))
