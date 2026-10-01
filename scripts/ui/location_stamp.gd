## LocationStamp — when the vessel crosses into a named part of a district,
## the city names it: a small engraved stamp in the corner of the frame,
## serif caps with a gold hairline, fading. Districts within districts —
## the city is administratively thorough.
class_name LocationStamp
extends Control

var game
var _t := 0.0                 # total life timer
var _label := ""
var _sub := ""
const LIFE := 3.4

func _ready() -> void:
        set_anchors_preset(Control.PRESET_FULL_RECT)
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        process_mode = Node.PROCESS_MODE_ALWAYS
        z_index = 58
        visible = false

func show_stamp(label: String, sub: String) -> void:
        _label = label
        _sub = sub
        _t = 0.0
        visible = true
        queue_redraw()

func _process(delta: float) -> void:
        if not visible:
                return
        _t += delta
        if _t > LIFE:
                visible = false
        else:
                queue_redraw()

func _draw() -> void:
        if not visible or _label.is_empty():
                return
        var vp := get_viewport_rect().size
        # fade in fast, hold, fade out slow
        var a := 1.0
        if _t < 0.35:
                a = _t / 0.35
        elif _t > LIFE - 0.9:
                a = (LIFE - _t) / 0.9
        a = clampf(a, 0.0, 1.0)
        var slide := (1.0 - a) * -14.0

        var x := 34.0
        var y := 96.0

        # measure the name width first for the backing plate
        var w := 0.0
        for ch in _label:
                w += E0.serif.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 2.4
        # backing shadow for readability (behind everything)
        draw_rect(Rect2(x + 12.0 + slide, y - 20.0, w + 14.0, 26.0 + (16.0 if not _sub.is_empty() else 0.0)),
                Color(0.02, 0.02, 0.03, 0.4 * a))

        # small act-mark diamond
        var dm := Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.8 * a)
        _diamond(Vector2(x + 5, y - 12), 3.4, dm)

        # the name — carved serif caps, letter-spaced
        var px := x + 18.0
        for ch in _label:
                draw_string(E0.serif, Vector2(px + 1.0, y + 1.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
                        Color(0, 0, 0, 0.4 * a))
                draw_string(E0.serif, Vector2(px, y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
                        Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.95 * a))
                px += E0.serif.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 2.4
        # gold hairline
        draw_line(Vector2(x + 18.0, y + 10.0), Vector2(x + 18.0 + w, y + 10.0),
                Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.78 * a), 1.0)
        # sub-district line, mono, quiet
        if not _sub.is_empty():
                draw_string(E0.mono, Vector2(x + 18.0, y + 28.0), _sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
                        Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.9 * a))
        # backing shadow for readability
        draw_rect(Rect2(x + 12.0 + slide, y - 20.0, w + 14.0, 26.0 + (16.0 if not _sub.is_empty() else 0.0)),
                Color(0.02, 0.02, 0.03, 0.4 * a))

func _diamond(c: Vector2, r: float, col: Color) -> void:
        draw_colored_polygon(PackedVector2Array([
                c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0),
        ]), col)
