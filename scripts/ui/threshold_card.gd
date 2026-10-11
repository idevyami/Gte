## ThresholdCard — THE BETWEEN's page. The census rubric inscribed on the
## black itself: a diamond glyph, one letter-spaced line of the record's
## mono voice arriving glyph by glyph, a hairline gold rule that grows
## outward beneath it, and the record's corner brackets framing the dark.
## Lives on a CanvasLayer ABOVE the fade so it writes on the black, never
## under it. Draws only while a deep crossing's rubric has presence.
class_name ThresholdCard
extends Control

var game: Game

func _ready() -> void:
        set_anchors_preset(Control.PRESET_FULL_RECT)
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        visible = false

func _process(_delta: float) -> void:
        var th: Threshold = game.threshold if game != null else null
        var show_now: bool = th != null and th.deep and th.rubric_alpha() > 0.004
        if show_now != visible:
                visible = show_now
        if visible:
                queue_redraw()

func _roman(n: int) -> String:
        var table := [[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]
        var out := ""
        var v := clampi(n, 1, 10)
        for pair in table:
                while v >= int(pair[0]):
                        out += String(pair[1])
                        v -= int(pair[0])
        return out

func _draw() -> void:
        var th: Threshold = game.threshold if game != null else null
        if th == null or not th.deep:
                return
        var a := th.rubric_alpha()
        if a <= 0.01:
                return
        var vp := get_viewport_rect().size
        var cx := vp.x * 0.5
        var cy := vp.y * 0.42

        # --- the overline: the record's filing mark (CENSUS · III → IV)
        var from_act := int(Rooms.ROOMS.get(th.from_room, {}).get("act", 0))
        var to_act := int(Rooms.ROOMS.get(th.to_room, {}).get("act", 0))
        if E0.mono and from_act > 0 and to_act > 0:
                var over := "CENSUS · " + _roman(from_act) + " \u2192 " + _roman(to_act)
                var ow := _spaced_width(E0.mono, over, 10, 2.5)
                _spaced_text(E0.mono, Vector2(cx - ow * 0.5, cy - 44.0), over, 10, 2.5,
                        Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.85 * a))

        # --- the diamond glyph above the line
        var dia := 3.0
        var dcol := Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.8 * a)
        draw_colored_polygon(PackedVector2Array([
                Vector2(cx, cy - 26.0 - dia), Vector2(cx + dia, cy - 26.0),
                Vector2(cx, cy - 26.0 + dia), Vector2(cx - dia, cy - 26.0),
        ]), dcol)

        # --- the rubric line, glyph by glyph (the record inscribing)
        if E0.mono:
                var size := 20
                var track := th.rubric_track()
                var text := th.rubric
                var tw := _spaced_width(E0.mono, text, size, track)
                while tw > vp.x - 140.0 and size > 14:
                        size -= 2
                        tw = _spaced_width(E0.mono, text, size, track)
                var x := cx - tw * 0.5
                for i in text.length():
                        var la := th.letter_alpha(i, text.length())
                        if la <= 0.01:
                                x += E0.mono.get_string_size(text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + track
                                continue
                        var col := Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, la * a)
                        # a faint gold echo trails each glyph as it lands
                        if la < 0.85:
                                draw_string(E0.mono, Vector2(x, cy + 1.0), text[i],
                                        HORIZONTAL_ALIGNMENT_LEFT, -1, size,
                                        Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.35 * (1.0 - la) * a))
                        draw_string(E0.mono, Vector2(x, cy), text[i],
                                HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
                        x += E0.mono.get_string_size(text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + track

                # --- the rule grows outward beneath the line
                var rk := clampf((th.t - (th.LEAVE + 0.18)) / 0.6, 0.0, 1.0)
                var half := tw * 0.5 * rk + 10.0
                draw_line(Vector2(cx - half, cy + 18.0), Vector2(cx + half, cy + 18.0),
                        Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.45 * a), 1.0)
                draw_circle(Vector2(cx - half, cy + 18.0), 1.5,
                        Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.7 * a))
                draw_circle(Vector2(cx + half, cy + 18.0), 1.5,
                        Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.7 * a))

                # --- the record's corner brackets frame the dark page
                var bw := tw * 0.5 + 46.0
                var bh := 40.0
                var br := 12.0
                var bcol := Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.35 * a)
                draw_line(Vector2(cx - bw, cy - bh - br), Vector2(cx - bw, cy - bh), bcol, 1.5)
                draw_line(Vector2(cx - bw, cy - bh), Vector2(cx - bw + br, cy - bh), bcol, 1.5)
                draw_line(Vector2(cx + bw - br, cy - bh), Vector2(cx + bw, cy - bh), bcol, 1.5)
                draw_line(Vector2(cx + bw, cy - bh), Vector2(cx + bw, cy - bh - br), bcol, 1.5)
                draw_line(Vector2(cx - bw, cy + bh + 14.0 - br), Vector2(cx - bw, cy + bh + 14.0), bcol, 1.5)
                draw_line(Vector2(cx - bw, cy + bh + 14.0), Vector2(cx - bw + br, cy + bh + 14.0), bcol, 1.5)
                draw_line(Vector2(cx + bw - br, cy + bh + 14.0), Vector2(cx + bw, cy + bh + 14.0), bcol, 1.5)
                draw_line(Vector2(cx + bw, cy + bh + 14.0), Vector2(cx + bw, cy + bh + 14.0 - br), bcol, 1.5)

# ------------------------------------------------------------------ helpers
func _spaced_width(font: FontFile, text: String, size: int, space: float) -> float:
        if font == null:
                return 0.0
        var w := 0.0
        for i in text.length():
                w += font.get_string_size(text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + space
        return maxf(0.0, w - space)

func _spaced_text(font: FontFile, pos: Vector2, text: String, size: int, space: float, col: Color) -> void:
        if font == null:
                return
        var x := pos.x
        for i in text.length():
                draw_string(font, Vector2(x, pos.y), text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
                x += font.get_string_size(text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + space
