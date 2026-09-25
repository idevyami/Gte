## Lights — additive glow pools: candle warmth, cyan veins, machine heat.
## Drawn once per build; flicker handled by low-frequency redraw.
class_name Lights
extends Node2D

var lights: Array = []

func setup(p_lights: Array) -> void:
        lights = p_lights
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
        for l in lights:
                var pos: Vector2 = l["pos"]
                var r: float = l["r"]
                var col: Color = l["color"]
                var flicker: float = l.get("flicker", 0.0)
                var k := 1.0
                if flicker > 0.0:
                        k = 1.0 - flicker * (0.4 + 0.6 * absf(sin(_t * 7.0 + pos.x * 0.13)))
                # soft radial falloff via concentric circles
                for i in 10:
                        var t := 1.0 - float(i) / 10.0
                        draw_circle(pos, r * t, Color(col.r, col.g, col.b, 0.028 * k * (1.0 - t) * 3.0))
