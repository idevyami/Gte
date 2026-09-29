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
        if _tex != null:
                var ts := _tex.get_size()
                var scale_k := maxf(_room_height / ts.y, 640.0 / ts.x) * 1.05
                var tile_w := ts.x * scale_k
                var origin_x := -scroll.x - tile_w
                while origin_x < scroll.x + _room_width:
                        var src := Rect2(Vector2.ZERO, ts)
                        var dst := Rect2(Vector2(origin_x, -scroll.y * 0.4 - 40.0), Vector2(tile_w, ts.y * scale_k))
                        draw_texture_rect_region(_tex, dst, src, Color(1, 1, 1, 0.85))
                        # mirrored tile for seamless width — same alpha, slightly
                        # cooler tint (no hard brightness step at the seam)
                        var dst_m := Rect2(Vector2(origin_x + tile_w, -scroll.y * 0.4 - 40.0), Vector2(tile_w, ts.y * scale_k))
                        draw_texture_rect_region(_tex, dst_m, src, Color(0.8, 0.8, 0.83, 0.85), true)
                        origin_x += tile_w * 2.0
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
        # procedural distant skyline — deep, layered, ash-colored
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
