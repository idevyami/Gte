## ReadingPanel — the surface where the city is read. One inscription at a
## time: a dark plate, the carved title in serif caps, the body in the
## voice it was written in (carved stone / stamped system / a later hand),
## and — where the world disagrees with itself — a marginal note in a
## different, smaller, human hand. Reading is remembering: the first read
## is recorded.
class_name ReadingPanel
extends Control

var game                                    # Game ref (untyped to avoid cycle)
var active := false
var entry: Dictionary = {}
var source: Readable = null

var _t := 0.0                # open animation
var _chars := 0.0            # typewriter progress over the composed text
var _total_chars := 1
var _margin_t := 0.0         # the later hand fades in after the carving

func _ready() -> void:
        set_anchors_preset(Control.PRESET_FULL_RECT)
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        process_mode = Node.PROCESS_MODE_ALWAYS
        z_index = 60

func open(p_source: Readable) -> void:
        source = p_source
        entry = p_source.entry
        active = true
        _t = 0.0
        _chars = 0.0
        _margin_t = 0.0
        _total_chars = _composed_text().length()
        visible = true
        FX.push_reading()
        AudioManager.play_sfx("sfx_terminal", -10.0)

func _composed_text() -> String:
        var parts: Array = []
        for l in entry.get("body", []):
                parts.append(String(l))
        if entry.has("stamp"):
                parts.append(String(entry["stamp"]))
        return "\n".join(parts)

func close() -> void:
        active = false
        visible = false
        FX.pop_reading()
        if game:
                game.reading_closed()

func _process(delta: float) -> void:
        if not active:
                return
        _t = minf(_t + delta * 3.2, 1.0)
        var speed := 52.0 + 18.0 * float(_total_chars) / 140.0
        _chars = minf(_chars + delta * speed, float(_total_chars))
        if _chars >= float(_total_chars):
                _margin_t = minf(_margin_t + delta * 1.6, 1.0)
        queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
        if not active:
                return
        if event.is_action_pressed("interact") or event.is_action_pressed("observe") or event.is_action_pressed("pause"):
                accept_event()
                if _chars < float(_total_chars):
                        _chars = float(_total_chars)     # first press finishes the text
                else:
                        close()

# ------------------------------------------------------------------ layout
const PAD := 96.0

func _draw() -> void:
        if not active:
                return
        var vp := get_viewport_rect().size
        var ease_t := 1.0 - pow(1.0 - _t, 3.0)
        # world dims behind the plate
        draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.02, 0.03, 0.72 * ease_t))

        var plate_w := minf(640.0, vp.x - PAD)
        var plate_h := minf(420.0, vp.y - PAD)
        var plate := Rect2((vp.x - plate_w) * 0.5, (vp.y - plate_h) * 0.5, plate_w, plate_h)
        plate.position.y += (1.0 - ease_t) * 26.0

        # ---- the plate: aged stone with a carved border
        _plate(plate)

        var x := plate.position.x + 34.0
        var y := plate.position.y + 44.0
        var max_w := plate_w - 68.0

        # ---- title: carved caps, serif
        var title := String(entry.get("title", ""))
        draw_string(E0.serif, Vector2(x, y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, E0.BONE)
        y += 12.0
        # gold hairline under the title
        var hair := 0.55 * ease_t
        draw_line(Vector2(x, y), Vector2(x + minf(max_w, 60.0 + title.length() * 9.0), y),
                Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, hair), 1.0)
        y += 30.0

        # ---- body: carved lines in the inscription's own voice
        var kind := String(entry.get("kind", "stele"))
        var voice_col := E0.PARCH
        var voice_font: FontFile = E0.serif
        var voice_size := 17
        var tracking := 2.0
        if kind == "stencil" or kind == "record_page":
                voice_font = E0.mono
                voice_size = 13
                tracking = 0.0
        var budget := int(_chars)
        for line in entry.get("body", []):
                var s := String(line)
                var hand := s.length() > 2 and s[0] == s[0].to_lower() and kind != "stencil" and kind != "record_page"
                var col: Color = voice_col if not hand else Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.82)
                var f: FontFile = voice_font if not hand else E0.serif
                var sz: int = voice_size if not hand else 15
                budget = _draw_line_scrolled(s, Vector2(x, y), f, sz, col, budget, tracking, kind)
                y += 26.0
                if y > plate.position.y + plate_h - 150.0:
                        break

        # ---- stamp: the system's opinion, mono, cyan, right-aligned block
        if entry.has("stamp"):
                y += 6.0
                draw_line(Vector2(x, y - 14.0), Vector2(x + 42.0, y - 14.0), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.4), 1.0)
                budget = _draw_line_scrolled(String(entry["stamp"]), Vector2(x, y), E0.mono, 11,
                        Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.85), budget, 0.0, "stamp")
                y += 24.0

        # ---- margin: a later, smaller hand — fades in once the carving is done
        if entry.has("margin") and _margin_t > 0.0:
                y += 10.0
                draw_line(Vector2(x, y - 16.0), Vector2(x + 26.0, y - 16.0), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.3 * _margin_t), 1.0)
                var m := String(entry["margin"])
                var mchars := int(float(m.length()) * _margin_t)
                var shown := m.substr(0, mchars)
                _draw_wrapped(shown, Vector2(x, y), E0.serif, 14, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.66 * _margin_t), max_w - 40.0)
                y += 40.0

        # ---- footer
        var foot_y := plate.position.y + plate_h - 26.0
        var foot := "F / TAB — CLOSE"
        var blink := 0.55 + 0.3 * sin(Time.get_ticks_msec() * 0.004)
        draw_string(E0.mono, Vector2(x, foot_y), foot, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, blink))
        # read state, right side
        var read_state := "UNREAD" if not GameState.texts_read.has(String(entry.get("id", ""))) else "IN THE RECORD"
        var rs_col := Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.5) if read_state == "UNREAD" else Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.55)
        draw_string(E0.mono, Vector2(plate.position.x + plate_w - 34.0 - read_state.length() * 7.0, foot_y), read_state,
                HORIZONTAL_ALIGNMENT_LEFT, -1, 11, rs_col)

func _draw_line_scrolled(s: String, at: Vector2, font: FontFile, size: int, col: Color, budget: int, tracking: float, kind: String) -> int:
        if budget <= 0:
                return budget
        var shown := s.substr(0, mini(s.length(), budget))
        var spent := shown.length()
        if tracking > 0.0:
                # letter-spaced carved caps
                var px := at.x
                for ch in shown:
                        draw_string(font, Vector2(px, at.y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
                        px += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + tracking
        else:
                draw_string(font, at, shown, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
                if kind == "stamp":
                        # stamped text carries a faint duplicate, like a bad strike
                        draw_string(font, at + Vector2(0.7, 0.7), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, size,
                                Color(col.r, col.g, col.b, 0.22))
        return budget - spent

func _draw_wrapped(s: String, at: Vector2, font: FontFile, size: int, col: Color, max_w: float) -> void:
        var words := s.split(" ")
        var line := ""
        var y := at.y
        for w in words:
                var cand := (line + " " if not line.is_empty() else "") + w
                if font.get_string_size(cand, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > max_w and not line.is_empty():
                        draw_string(font, Vector2(at.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
                        y += size + 8.0
                        line = w
                else:
                        line = cand
        if not line.is_empty():
                draw_string(font, Vector2(at.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _plate(plate: Rect2) -> void:
        ## Aged stone plate: layered fill, carved double border, corner ticks.
        draw_rect(plate, Color(0.055, 0.05, 0.045, 0.985))
        draw_rect(Rect2(plate.position - Vector2(6, 6), plate.size + Vector2(12, 12)), Color(0.02, 0.02, 0.025, 0.5))
        # stone mottling
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(String(entry.get("id", "x")))
        for i in 26:
                var mx := plate.position.x + rng.randf() * plate.size.x
                var my := plate.position.y + rng.randf() * plate.size.y
                var r := 8.0 + rng.randf() * 30.0
                draw_circle(Vector2(mx, my), r, Color(1, 1, 1, 0.008 + 0.006 * rng.randf()))
        # carved double border
        draw_rect(plate, E0.DIRTY_STONE, false, 2.0)
        draw_rect(Rect2(plate.position + Vector2(5, 5), plate.size - Vector2(10, 10)), Color(E0.DIRTY_STONE.r, E0.DIRTY_STONE.g, E0.DIRTY_STONE.b, 0.45), false, 1.0)
        # corner brackets
        for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
                var c: Vector2 = corner
                var cx := plate.position.x + c.x * plate.size.x
                var cy := plate.position.y + c.y * plate.size.y
                var dx := -1.0 if c.x == 0 else 1.0
                var dy := -1.0 if c.y == 0 else 1.0
                draw_line(Vector2(cx + dx * 10.0, cy), Vector2(cx + dx * 10.0, cy + dy * 14.0), E0.GOLD.darkened(0.15), 1.5)
                draw_line(Vector2(cx, cy + dy * 10.0), Vector2(cx + dx * 14.0, cy + dy * 10.0), E0.GOLD.darkened(0.15), 1.5)
