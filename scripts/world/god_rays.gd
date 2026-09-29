## GodRays — volumetric light shafts. Slanted additive beams falling from
## above (chapel windows, engine gratings, the martyr's arena crack), slowly
## breathing. Each beam is a single gradient texture (cosine profile across
## the width, fade down the length) drawn rotated and scaled — bilinear
## filtering gives real soft edges, no strip banding, no rectangle reads.
class_name GodRays
extends Node2D

const PRESETS := {
        "chapel": {"n": 4, "col": Color(0.85, 0.78, 0.60), "a": 0.085},
        "reliquary": {"n": 3, "col": Color(0.72, 0.80, 0.85), "a": 0.075},
        "engine": {"n": 3, "col": Color(0.85, 0.62, 0.50), "a": 0.080},
        "aftermath": {"n": 3, "col": Color(0.80, 0.76, 0.70), "a": 0.050},
        "vessels": {"n": 2, "col": Color(0.55, 0.80, 0.82), "a": 0.065},
}

var key := ""
var _beams: Array = []
var _room_width := 1280.0
var _room_height := 720.0
var _camera: Camera2D
var _t := 0.0

static var _beam_tex: ImageTexture

static func get_beam_texture() -> ImageTexture:
        ## White gradient: cosine falloff across width, gentle ease-in at the
        ## top and fade-out down the length. Built once, filtered by the GPU.
        if _beam_tex == null:
                var img := Image.create(128, 256, false, Image.FORMAT_RGBA8)
                for y in 256:
                        var v := float(y) / 255.0
                        for x in 128:
                                var u := float(x) / 127.0 * 2.0 - 1.0
                                var profile := pow(maxf(0.0, cos(u * PI * 0.5)), 1.5)
                                var fade := (1.0 - pow(v, 1.45)) * smoothstep(0.0, 0.035, v)
                                img.set_pixel(x, y, Color(1.0, 1.0, 1.0, profile * fade))
                _beam_tex = ImageTexture.create_from_image(img)
        return _beam_tex

func setup(p_key: String, room_size: Vector2, camera: Camera2D) -> void:
        key = p_key
        _room_width = room_size.x
        _room_height = room_size.y
        _camera = camera
        if not PRESETS.has(p_key):
                return
        var rng := RandomNumberGenerator.new()
        rng.seed = hash("rays:" + p_key)
        var preset: Dictionary = PRESETS[p_key]
        var n: int = preset["n"]
        for i in n:
                _beams.append({
                        "x": rng.randf_range(0.12, 0.88) * _room_width,
                        "w": rng.randf_range(110.0, 210.0),
                        "slant": rng.randf_range(-0.16, 0.10),
                        "h": _room_height * rng.randf_range(0.86, 1.05),
                        "ph": rng.randf() * TAU,
                        "a": float(preset["a"]) * rng.randf_range(0.7, 1.15),
                })
        var mat := CanvasItemMaterial.new()
        mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
        material = mat
        z_index = -3
        set_process(true)

func _process(delta: float) -> void:
        if _beams.is_empty():
                return
        _t += delta
        queue_redraw()

func _draw() -> void:
        if _beams.is_empty():
                return
        var col_base: Color = PRESETS[key]["col"]
        var scroll := _camera.global_position if _camera else Vector2.ZERO
        var tex := get_beam_texture()
        for b in _beams:
                var x: float = b["x"] - scroll.x * 0.12
                var w: float = b["w"]
                var slant: float = b["slant"]
                var h: float = b["h"]
                var breathe := 0.72 + 0.28 * sin(_t * 0.16 + float(b["ph"]))
                var col := Color(col_base.r, col_base.g, col_base.b, float(b["a"]) * breathe)
                # one filtered gradient quad per beam, sheared by its slant:
                # draw_set_transform rotation approximates the shear
                draw_set_transform(Vector2(x, -80.0), atan(slant), Vector2(w, h))
                draw_texture_rect(tex, Rect2(Vector2(-0.5, 0.0), Vector2(1.0, 1.0)), false, col)
                draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
                # dust caught in the beam — the light becomes a place
                var rng := RandomNumberGenerator.new()
                rng.seed = int(b["ph"] * 1000.0)
                for k in 5:
                        var my := fmod(rng.randf() * h + _t * (6.0 + rng.randf() * 10.0), h)
                        var mx := x + (rng.randf() - 0.5) * w * 0.7 + slant * my
                        draw_circle(Vector2(mx, my - 80.0), rng.randf_range(0.7, 1.6),
                                Color(col.r, col.g, col.b, 0.10 * breathe))
