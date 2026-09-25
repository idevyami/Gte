## AmbientFX — the air of the world. Three sandwich layers around the
## gameplay plane: drifting dust motes that catch the light (mid), slow
## floor mist that breathes along the ground (low), and foreground ashfall
## that falls IN FRONT of the actors (high, low alpha — depth without
## occlusion). Everything is deterministic per room and palette-locked.
class_name AmbientFX
extends Node2D

var room_size := Vector2(1280, 720)
var _camera: Camera2D
var _room_key := ""

var _motes: Array = []        # slow bright specks in the light
var _fg_ash: Array = []       # foreground flakes
var _mist_bands: Array = []   # floor haze bands
var _t := 0.0

func setup(key: String, p_room_size: Vector2, p_camera: Camera2D) -> void:
	_room_key = key
	room_size = p_room_size
	_camera = p_camera
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("ambient:" + key)
	_motes.clear()
	for i in 26:
		_motes.append({
			"pos": Vector2(rng.randf() * room_size.x, rng.randf() * room_size.y * 0.8),
			"ph": rng.randf() * TAU,
			"r": rng.randf_range(0.8, 1.8),
			"a": rng.randf_range(0.05, 0.16),
			"vy": rng.randf_range(-3.0, -7.0),
		})
	_fg_ash.clear()
	for i in 34:
		_fg_ash.append({
			"pos": Vector2(rng.randf() * room_size.x, rng.randf() * room_size.y),
			"v": Vector2(rng.randf_range(-10.0, -30.0), rng.randf_range(26.0, 60.0)),
			"r": rng.randf_range(1.2, 3.0),
			"a": rng.randf_range(0.05, 0.13),
			"ph": rng.randf() * TAU,
		})
	_mist_bands.clear()
	var floor_y := room_size.y - 78.0
	for i in 3:
		_mist_bands.append({
			"y": floor_y + float(i) * 16.0,
			"speed": rng.randf_range(6.0, 16.0) * (1.0 if rng.randf() < 0.5 else -1.0),
			"a": rng.randf_range(0.035, 0.06),
			"ph": rng.randf() * TAU,
		})
	z_index = 40
	set_process(true)

func _process(delta: float) -> void:
	_t += delta
	for m in _motes:
		var p: Vector2 = m["pos"]
		p.y += float(m["vy"]) * delta
		p.x += sin(_t * 0.35 + float(m["ph"])) * 2.0 * delta
		if p.y < -20.0:
			p.y = room_size.y * 0.8 + 20.0
			p.x = randf() * room_size.x
		m["pos"] = p
	for m in _fg_ash:
		var p: Vector2 = m["pos"]
		p += (m["v"] as Vector2) * delta
		if p.y > room_size.y + 24.0:
			p.y = -24.0
			p.x = randf() * room_size.x
		if p.x < -24.0:
			p.x = room_size.x + 24.0
		m["pos"] = p
	queue_redraw()

func _draw() -> void:
	# --- dust motes: bright specks hanging in the air (behind actors feel,
	#     drawn softly so they read as atmosphere, not noise)
	var cam := _camera.global_position if _camera else Vector2.ZERO
	var vp_l := cam.x - 640.0
	var vp_r := cam.x + 640.0
	for m in _motes:
		var p: Vector2 = m["pos"]
		var twinkle := 0.6 + 0.4 * sin(_t * 1.3 + float(m["ph"]))
		var col := Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, float(m["a"]) * twinkle)
		draw_circle(p, float(m["r"]), col)
		draw_circle(p, float(m["r"]) * 2.2, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, float(m["a"]) * twinkle * 0.25))
	# --- floor mist: layered soft bands drifting along the ground
	for b in _mist_bands:
		var y: float = b["y"]
		var sp: float = b["speed"]
		var drift := sin(_t * 0.22 + float(b["ph"])) * 60.0
		var band_h := 46.0
		for k in 5:
			var t := float(k) / 4.0
			var col := Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, float(b["a"]) * (1.0 - t * 0.8))
			var off := (t - 0.5) * 30.0
			var x0 := vp_l - 80.0 + drift * (1.0 - t * 0.5) + off + sp * _t * 0.4
			x0 = fmod(x0, 320.0) - 320.0
			while x0 < vp_r + 80.0:
				var w := 240.0
				draw_rect(Rect2(Vector2(x0, y - band_h * t * 0.5), Vector2(w, band_h * 0.35 + 10.0)), col)
				x0 += w + 90.0
	# --- foreground ash: falls in front of everything, deliberately faint
	for m in _fg_ash:
		var p: Vector2 = m["pos"]
		var drift := sin(_t * 0.9 + float(m["ph"])) * 5.0
		draw_circle(p + Vector2(drift, 0.0), float(m["r"]), Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, float(m["a"])))
