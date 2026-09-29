## Parallax — the AI-painted backdrop (mirrored tiling), fog gradients, and
## the eternal ashfall. Falls back to procedural silhouette skylines when the
## backdrop texture is absent (headless / pre-art builds).
class_name Parallax
extends Node2D

var backdrop_key := ""
var _tex: Texture2D
var _fog_color := E0.VOID
var _fog_alpha := 0.35
var _room_height := 720.0
var _room_width := 1280.0
var _ash: Array = []
var _camera: Camera2D
var _last_cam := Vector2.ZERO

const BACKDROP_FILES := {
        "vessels": "res://art/backdrops/backdrop_vessels.png",
        "city": "res://art/backdrops/backdrop_city.png",
        "undercity": "res://art/backdrops/backdrop_undercity.png",
        "chapel": "res://art/backdrops/backdrop_chapel.png",
        "archive": "res://art/backdrops/backdrop_archive.png",
        "engine": "res://art/backdrops/backdrop_engine.png",
        "reliquary": "res://art/backdrops/backdrop_reliquary.png",
        "aftermath": "res://art/backdrops/backdrop_aftermath.png",
}

func setup(key: String, fog: Color, fog_alpha: float, room_size: Vector2, camera: Camera2D) -> void:
        backdrop_key = key
        _fog_color = fog
        _fog_alpha = fog_alpha
        _room_width = room_size.x
        _room_height = room_size.y
        _camera = camera
        if BACKDROP_FILES.has(key):
                _tex = load(BACKDROP_FILES[key])
        _ash.clear()
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(key)
        for i in 70:
                _ash.append({
                        "pos": Vector2(rng.randf() * _room_width, rng.randf() * _room_height),
                        "v": Vector2(rng.randf_range(-8.0, -22.0), rng.randf_range(14.0, 42.0)),
                        "r": rng.randf_range(0.7, 2.0),
                        "a": rng.randf_range(0.08, 0.28),
                        "ph": rng.randf() * TAU,
                })
        z_index = -10
        queue_redraw()

func _process(delta: float) -> void:
        if _camera:
                _last_cam = _camera.global_position
        for m in _ash:
                m["pos"] += (m["v"] as Vector2) * delta
                if (m["pos"] as Vector2).y > _room_height + 20.0:
                        m["pos"] = Vector2(randf() * _room_width, -20.0)
                if (m["pos"] as Vector2).x < -20.0:
                        m["pos"] = Vector2(_room_width + 20.0, (m["pos"] as Vector2).y)
        queue_redraw()

func _draw() -> void:
        # backdrop scrolls at a fraction of camera movement
        var scroll := _last_cam * 0.25
        # --- painted sky: a vertical grade behind everything — void above,
        #     fog-tempered air at the horizon, faint ash-warmth at the floor.
        #     Kills the flat grey void where the backdrop art ends.
        var horizon := _room_height * 0.62
        for i in 14:
                var t := float(i) / 13.0
                var y := -240.0 + t * (horizon + 240.0)
                var mix_col := E0.VOID.lerp(Color(_fog_color.r * 1.5, _fog_color.g * 1.5, _fog_color.b * 1.6), pow(t, 1.6))
                draw_rect(Rect2(-500.0 - scroll.x * 0.2, y, _room_width + 1000.0, (horizon + 240.0) / 13.0 + 2.0), mix_col)
        # horizon glow: the city's light pooled against the air — one soft
        # layered band (no concentric shapes; they quantize into rings)
        for i in 7:
                var gt := float(i) / 7.0
                var gy := horizon - scroll.y * 0.3 - 26.0 + gt * 30.0
                draw_rect(Rect2(-500.0 - scroll.x * 0.22, gy, _room_width + 1000.0, 32.0),
                        Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.020 * (1.0 - gt)))
        if _tex != null:
                var ts := _tex.get_size()
                var scale_k := maxf(_room_height / ts.y, 640.0 / ts.x) * 1.05
                # varied-crop tiling: every tile samples a DIFFERENT window of
                # the painting (own crop, scale, vertical offset). Identical
                # mirrored repeats read as wallpaper; varied crops read as a
                # long hall of similar architecture. Local mirror pairs read
                # as symmetric gothic structure — seams veiled in fog below.
                var tile_i := 0
                var origin_x := -scroll.x - ts.x * scale_k
                while origin_x < scroll.x + _room_width:
                        var rng := RandomNumberGenerator.new()
                        rng.seed = hash(backdrop_key + ":" + str(tile_i))
                        var crop_frac := rng.randf_range(0.62, 0.88)
                        var crop_w := ts.x * crop_frac
                        var crop_x := rng.randf() * (ts.x - crop_w)
                        var this_k := scale_k / crop_frac * rng.randf_range(0.92, 1.12)
                        var tile_w := crop_w * this_k
                        var tile_h := ts.y * this_k
                        var top_y := -scroll.y * 0.4 - 40.0 + rng.randf_range(-18.0, 6.0)
                        var src := Rect2(Vector2(crop_x, 0.0), Vector2(crop_w, ts.y))
                        # outer tiles sink into the air (depth-of-field feel);
                        # the centre tile carries the full-contrast painting
                        var dist := absf(float(tile_i) - 1.0)
                        var depth_a := 0.85 * clampf(1.0 - dist * 0.22, 0.5, 1.0)
                        draw_texture_rect_region(_tex, Rect2(Vector2(origin_x, top_y), Vector2(tile_w, tile_h)), src, Color(1, 1, 1, depth_a))
                        draw_texture_rect_region(_tex, Rect2(Vector2(origin_x + tile_w, top_y), Vector2(tile_w, tile_h)), src, Color(1, 1, 1, depth_a), true)
                        _seam_veil(origin_x, top_y, tile_h)
                        _seam_veil(origin_x + tile_w, top_y, tile_h)
                        _seam_veil(origin_x + tile_w * 2.0, top_y, tile_h)
                        origin_x += tile_w * 2.0
                        tile_i += 1
        else:
                _draw_silhouette_fallback(scroll)
        # fog gradient: the room breathes haze
        var fog_h := _room_height + 240.0
        for i in 6:
                var t := float(i) / 5.0
                var col := Color(_fog_color.r, _fog_color.g, _fog_color.b, _fog_alpha * (1.0 - t))
                draw_rect(Rect2(-400.0, -240.0 + t * fog_h, _room_width + 800.0, fog_h / 5.0), col)
        # ashfall
        var time_s := Time.get_ticks_msec() * 0.001
        for m in _ash:
                var p: Vector2 = m["pos"] - Vector2(scroll.x * 0.6, scroll.y * 0.3)
                var drift := sin(time_s * 0.8 + float(m["ph"])) * 4.0
                draw_circle(p + Vector2(drift, 0.0), float(m["r"]), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, float(m["a"])))

func _draw_silhouette_fallback(scroll: Vector2) -> void:
        var layers := [
                {"color": Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.5), "h": 0.5, "k": 0.35},
                {"color": Color(E0.CHARCOAL.r, E0.CHARCOAL.g, E0.CHARCOAL.b, 0.7), "h": 0.32, "k": 0.55},
        ]
        for layer in layers:
                var rng := RandomNumberGenerator.new()
                rng.seed = hash(backdrop_key + str(layer["k"]))
                var base_y := -scroll.y * float(layer["k"]) * 0.3 - 40.0
                var pts := PackedVector2Array([Vector2(-600.0, _room_height + 200.0)])
                var x := -600.0
                while x < _room_width + 600.0:
                        var w := rng.randf_range(60.0, 150.0)
                        var h := _room_height * float(layer["h"]) * rng.randf_range(0.4, 1.0)
                        pts.append(Vector2(x, base_y - h))
                        pts.append(Vector2(x + w, base_y - h))
                        x += w
                        if rng.randf() < 0.3:
                                x += rng.randf_range(30.0, 120.0)
                                pts.append(Vector2(x, base_y))
                                pts.append(Vector2(x + 10.0, base_y))
                pts.append(Vector2(x, _room_height + 200.0))
                draw_colored_polygon(pts, layer["color"])
        # a pale light source high and far
        draw_circle(Vector2(-scroll.x * 0.2 + _room_width * 0.6, -scroll.y * 0.2 + 40.0), 90.0,
                Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.06))

func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
        var pts := PackedVector2Array()
        for i in 16:
                var ang := TAU * i / 16.0
                pts.append(c + Vector2(cos(ang) * rx, sin(ang) * ry))
        draw_colored_polygon(pts, col)

func _seam_veil(x: float, top_y: float, h: float) -> void:
        ## The junction between backdrop tiles becomes architecture: interiors
        ## get a soft dark pier (the bay separator a gothic hall actually
        ## has); open-air rooms get a wide haze column. Either way the seam
        ## stops reading as a tile edge.
        var interior := not (backdrop_key == "city" or backdrop_key == "aftermath" or backdrop_key == "undercity")
        if interior:
                var pier := Color(E0.CHARCOAL.r, E0.CHARCOAL.g, E0.CHARCOAL.b, 1.0).lerp(
                        Color(_fog_color.r, _fog_color.g, _fog_color.b), 0.4)
                for i in 8:
                        var k := absf(float(i) - 3.5) / 4.0      # 0 at centre, 1 at edges
                        var strip_w := 17.0
                        var sx := x + (float(i) - 4.0) * strip_w
                        var a := 0.26 * (1.0 - k * k * k)
                        draw_rect(Rect2(sx, top_y, strip_w + 1.0, h),
                                Color(pier.r, pier.g, pier.b, a))
        else:
                for i in 9:
                        var k := absf(float(i) - 4.0) / 5.0
                        var strip_w := 20.0
                        var sx := x + (float(i) - 5.0) * strip_w
                        var a := 0.11 * (1.0 - k * k)
                        draw_rect(Rect2(sx, top_y, strip_w + 1.0, h),
                                Color(_fog_color.r, _fog_color.g, _fog_color.b, a))
