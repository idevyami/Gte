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
var _special: Array = []      # per-act air: updrafts / drips / embers / papers
var _special_kind := ""      # which phenomenon this room breathes
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
        # the open-air rooms breathe more ash; interiors hold their air still
        var ash_n := 34
        if key.begins_with("act3") or key.begins_with("act9") or key.begins_with("act4"):
                ash_n = 56
        elif key.begins_with("act5") or key.begins_with("act8"):
                ash_n = 24
        for i in ash_n:
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
        # --- PER-ACT AIR: every act of the city has its own weather ---
        _special.clear()
        if key.begins_with("act1"):
                # THE ASH FALLS UPWARD HERE (the iron womb exhales)
                _special_kind = "updraft"
                for i in 30:
                        _special.append({"pos": Vector2(rng.randf() * room_size.x, rng.randf() * room_size.y),
                                "v": Vector2(rng.randf_range(-6.0, 6.0), rng.randf_range(-34.0, -64.0)),
                                "r": rng.randf_range(1.0, 2.4), "a": rng.randf_range(0.05, 0.13),
                                "ph": rng.randf() * TAU})
        elif key.begins_with("act2") or key.begins_with("act4"):
                # the undercity weeps: slow ceiling drips with a bright bead
                _special_kind = "drips"
                for i in 7:
                        _special.append({"x": rng.randf() * room_size.x, "y": rng.randf() * room_size.y,
                                "v": rng.randf_range(150.0, 230.0), "ph": rng.randf() * TAU,
                                "floor": floor_y - rng.randf_range(0.0, 30.0)})
        elif key.begins_with("act5"):
                # the chapel breathes incense: warm motes rising slow
                _special_kind = "incense"
                for i in 22:
                        _special.append({"pos": Vector2(rng.randf() * room_size.x, rng.randf() * room_size.y),
                                "v": Vector2(rng.randf_range(-4.0, 4.0), rng.randf_range(-10.0, -20.0)),
                                "r": rng.randf_range(1.2, 2.6), "a": rng.randf_range(0.06, 0.15),
                                "ph": rng.randf() * TAU})
        elif key.begins_with("act6"):
                # the archive sheds: single pages turning down through the air
                _special_kind = "papers"
                for i in 5:
                        _special.append({"pos": Vector2(rng.randf() * room_size.x, rng.randf() * room_size.y),
                                "vy": rng.randf_range(22.0, 38.0), "ph": rng.randf() * TAU,
                                "spin": rng.randf_range(1.2, 2.6) * (1.0 if rng.randf() < 0.5 else -1.0)})
        elif key.begins_with("act7") or key.begins_with("act8"):
                # the engine exhales embers: rising sparks that gutter out
                _special_kind = "embers"
                for i in 26:
                        _special.append({"pos": Vector2(rng.randf() * room_size.x, rng.randf() * room_size.y),
                                "v": Vector2(rng.randf_range(-8.0, 8.0), rng.randf_range(-26.0, -58.0)),
                                "r": rng.randf_range(0.9, 1.9), "a": rng.randf_range(0.2, 0.5),
                                "ph": rng.randf() * TAU})
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
        # the room's own weather
        match _special_kind:
                "updraft", "incense", "embers":
                        for m in _special:
                                var p: Vector2 = m["pos"]
                                p += (m["v"] as Vector2) * delta
                                p.x += sin(_t * 0.8 + float(m["ph"])) * 8.0 * delta
                                if p.y < -18.0:
                                        p.y = room_size.y + 14.0
                                        p.x = randf() * room_size.x
                                if p.x < -14.0:
                                        p.x = room_size.x + 14.0
                                elif p.x > room_size.x + 14.0:
                                        p.x = -14.0
                                m["pos"] = p
                "drips":
                        for m in _special:
                                m["y"] = float(m["y"]) + float(m["v"]) * delta
                                if float(m["y"]) > float(m["floor"]):
                                        m["y"] = -30.0
                "papers":
                        for m in _special:
                                var pp: Vector2 = m["pos"]
                                pp.y += float(m["vy"]) * delta
                                pp.x += sin(_t * float(m["spin"]) + float(m["ph"])) * 20.0 * delta
                                if pp.y > room_size.y + 16.0:
                                        pp.y = -16.0
                                        pp.x = randf() * room_size.x
                                m["pos"] = pp
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
        # --- the room's own weather ---
        match _special_kind:
                "updraft":
                        # ash that falls the wrong way, the womb exhaling
                        for m in _special:
                                var p: Vector2 = m["pos"]
                                var sway := sin(_t * 1.1 + float(m["ph"])) * 3.0
                                var tw := 0.6 + 0.4 * sin(_t * 2.1 + float(m["ph"]))
                                draw_circle(p + Vector2(sway, 0.0), float(m["r"]), Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, float(m["a"]) * tw))
                "incense":
                        for m in _special:
                                var p: Vector2 = m["pos"]
                                var tw := 0.5 + 0.5 * sin(_t * 0.9 + float(m["ph"]))
                                draw_circle(p, float(m["r"]), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, float(m["a"]) * tw * 0.8))
                                draw_circle(p, float(m["r"]) * 2.4, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, float(m["a"]) * tw * 0.2))
                "embers":
                        for m in _special:
                                var p: Vector2 = m["pos"]
                                var gut := maxf(0.0, sin(_t * 3.3 + float(m["ph"])))
                                var sway := sin(_t * 1.4 + float(m["ph"])) * 4.0
                                var col := Color(E0.CRIMSON.r * 1.4 + 0.25, E0.CRIMSON.g * 1.1 + 0.18, E0.CRIMSON.b * 0.7 + 0.05, float(m["a"]) * (0.4 + 0.6 * gut))
                                var at := p + Vector2(sway, 0.0)
                                # motion streak: the ember drags its own light
                                # upward — a fleck in flight, not a static dot
                                var sv: Vector2 = m["v"]
                                var tail := at - sv.normalized() * (3.0 + 4.0 * gut)
                                draw_line(tail, at, Color(col.r, col.g, col.b, col.a * 0.55), 1.4)
                                draw_circle(at, float(m["r"]), col)
                "drips":
                        # bright bead falling, thin trail behind it
                        for m in _special:
                                var x: float = m["x"]
                                var y: float = m["y"]
                                var fl: float = m["floor"]
                                draw_line(Vector2(x, y - 9.0), Vector2(x, y - 2.0), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.10), 1.0)
                                draw_circle(Vector2(x, y), 1.4, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.30))
                                # landing ripple only in the last stretch of the fall
                                var dist := fl - y
                                if dist < 40.0 and dist > 0.0:
                                        var near := 1.0 - clampf(dist / 40.0, 0.0, 1.0)
                                        var rr := 2.0 + near * 9.0
                                        draw_circle(Vector2(x, fl), rr, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.10 * near))
                "papers":
                        for m in _special:
                                var p: Vector2 = m["pos"]
                                var tilt := sin(_t * float(m["spin"]) + float(m["ph"]))
                                draw_set_transform(p, tilt * 0.5, Vector2.ONE)
                                draw_rect(Rect2(-4.5, -6.0, 9.0, 12.0), Color(E0.PARCH.r * 0.85, E0.PARCH.g * 0.85, E0.PARCH.b * 0.82, 0.34))
                                draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
