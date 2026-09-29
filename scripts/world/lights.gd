## Lights — additive glow pools: candle warmth, cyan veins, machine heat.
## Every source renders through filtered gradient textures (built once):
##   — a radial falloff quad (soft glow, no concentric-ring quantization)
##   — a hot bright core (the wick / vein itself)
##   — a squashed radial pool where the light lands on the floor plane
##   — an optional downward cone (chapel candles, the martyr's arena)
## Flicker handled by low-frequency redraw.
class_name Lights
extends Node2D

var lights: Array = []
var floor_y := -1.0

static var _glow_tex: ImageTexture

static func get_glow_texture() -> ImageTexture:
        ## White radial gradient: smooth falloff from centre. Bilinear
        ## filtering keeps it band-free at any scale.
        if _glow_tex == null:
                var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
                for y in 128:
                        for x in 128:
                                var d := Vector2(float(x) - 63.5, float(y) - 63.5).length() / 64.0
                                var a := pow(clampf(1.0 - d, 0.0, 1.0), 1.7)
                                img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
                _glow_tex = ImageTexture.create_from_image(img)
        return _glow_tex

func setup(p_lights: Array, p_floor_y := -1.0) -> void:
        lights = p_lights
        floor_y = p_floor_y
        var mat := CanvasItemMaterial.new()
        mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
        material = mat
        z_index = -5
        queue_redraw()

var _t := 0.0
func _process(delta: float) -> void:
        _t += delta
        if fmod(_t, 0.2) < delta:
                queue_redraw()

func _draw() -> void:
        var glow := get_glow_texture()
        var beam := GodRays.get_beam_texture()
        for l in lights:
                var pos: Vector2 = l["pos"]
                var r: float = l["r"]
                var col: Color = l["color"]
                var flicker: float = l.get("flicker", 0.0)
                var k := 1.0
                if flicker > 0.0:
                        k = 1.0 - flicker * (0.4 + 0.6 * absf(sin(_t * 7.0 + pos.x * 0.13)))
                # --- radial falloff: one filtered gradient quad
                draw_texture_rect(glow, Rect2(pos - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), false,
                        Color(col.r, col.g, col.b, 0.34 * k))
                # --- hot core: the source itself reads as a lit wick / vein
                for i in 3:
                        var ct := 1.0 - float(i) / 3.0
                        draw_circle(pos, 1.0 + 2.6 * ct, Color(col.r, col.g, col.b, 0.10 * k * ct + 0.05))
                # --- floor spill: squashed radial gradient where light lands
                if floor_y > 0.0:
                        var drop := clampf((floor_y - pos.y) / 500.0, 0.0, 1.0)
                        var rx := r * (0.85 + drop * 0.35)
                        var ry := rx * 0.17
                        draw_texture_rect(glow, Rect2(Vector2(pos.x - rx, floor_y - 2.0 - ry), Vector2(rx * 2.0, ry * 2.0)), false,
                                Color(col.r, col.g, col.b, 0.07 * k))
                # --- optional cone: a shaft of light falling from the source
                if l.has("cone"):
                        var h: float = float(l["cone"])
                        draw_set_transform(pos, 0.0, Vector2(r * 1.5, h))
                        draw_texture_rect(beam, Rect2(Vector2(-0.5, 0.0), Vector2(1.0, 1.0)), false,
                                Color(col.r, col.g, col.b, 0.16 * k))
                        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
