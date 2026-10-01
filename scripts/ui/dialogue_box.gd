## DialogueBox — typewriter dialogue with per-line conditions. Speakers are
## the world itself: clerks, martyrs, withheld things, and the SYSTEM.
class_name DialogueBox
extends Control

var game
var speaker := ""
var lines: Array = []
var line_idx := 0
var chars_shown := 0
var active := false
var key := ""
var _blink := 0.0
var _last_blip := 0        # chars already ticked on this line

func _ready() -> void:
        set_anchors_preset(Control.PRESET_FULL_RECT)
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        visible = false

func set_game(p_game) -> void:
        game = p_game

func open(dialogue_key: String) -> void:
        var conv: Dictionary = game.dialogues.get(dialogue_key, {})
        if conv.is_empty():
                push_warning("DialogueBox: missing conversation " + dialogue_key)
                return
        key = dialogue_key
        speaker = String(conv.get("speaker", "SYSTEM"))
        lines = []
        for line in conv.get("lines", []):
                var cond := String(line.get("cond", ""))
                if EntityData._condition_holds(cond, GameState.stage, GameState.flags, GameState.consistency):
                        lines.append(String(line["text"]))
        if lines.is_empty():
                return
        line_idx = 0
        chars_shown = 0
        _last_blip = 0
        active = true
        visible = true
        EventBus.dialogue_started.emit(speaker)

func advance() -> bool:
        ## F: complete the line, then move on. Returns true when dialogue closed.
        if not active:
                return false
        var full: String = lines[line_idx]
        if chars_shown < full.length():
                chars_shown = full.length()
                return false
        line_idx += 1
        if line_idx >= lines.size():
                close()
                return true
        chars_shown = 0
        _last_blip = 0
        return false

func close() -> void:
        active = false
        visible = false
        EventBus.dialogue_finished.emit(key)

func _process(delta: float) -> void:
        if active:
                chars_shown = mini(chars_shown + int(ceil(42.0 * delta)), lines[line_idx].length())
                _blink += delta
                _maybe_blip()
                queue_redraw()

func _maybe_blip() -> void:
        ## Typewriter ticks — one soft felt blip per 2 non-space characters.
        if not bool(GameState.settings.get("blips", true)):
                return
        var text: String = lines[line_idx]
        if chars_shown >= text.length():
                return   # line complete — no ticking while it sits
        var ns := 0
        for i in chars_shown:
                var ch := text[i]
                if ch != " " and ch != "." and ch != "," and ch != "\u2014":
                        ns += 1
        if ns / 2 > _last_blip:
                _last_blip = ns / 2
                AudioManager.play_sfx("sfx_blip", -20.0)

func _draw() -> void:
        if not active:
                return
        var vp := get_viewport_rect().size
        var w := minf(860.0, vp.x - 80.0)
        var x := (vp.x - w) * 0.5
        var y := vp.y - 190.0
        var h := 130.0
        # panel — feathered sides so the record sits IN the scene, not on it
        draw_rect(Rect2(x - 14, y - 14, w + 28, h + 28), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.88))
        for i in 3:
                var k := float(i) / 3.0
                draw_rect(Rect2(x - 14 - 16.0 + i * 5.5, y - 14, 18.0 - i * 5.5, h + 28), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.14 * (1.0 - k)))
                draw_rect(Rect2(x + w + 14 - 2.0 - i * 5.5, y - 14, 18.0 - i * 5.5, h + 28), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.14 * (1.0 - k)))
        draw_rect(Rect2(x - 14, y - 14, w + 28, h + 28), E0.ASH, false, 1.0)
        draw_rect(Rect2(x - 14, y - 14, 3.0, h + 28), _speaker_color())
        # corner brackets — the record frames its speakers
        var _brk := 10.0
        draw_line(Vector2(x - 14, y - 2), Vector2(x - 14, y - 14), _speaker_color(), 1.5)
        draw_line(Vector2(x - 14, y - 14), Vector2(x - 14 + _brk, y - 14), _speaker_color(), 1.5)
        draw_line(Vector2(x + w + 14 - _brk, y - 14), Vector2(x + w + 14, y - 14), _speaker_color(), 1.5)
        draw_line(Vector2(x + w + 14, y - 14), Vector2(x + w + 14, y - 2), _speaker_color(), 1.5)
        draw_line(Vector2(x - 14, y + h + 2), Vector2(x - 14, y + h + 14), _speaker_color(), 1.5)
        draw_line(Vector2(x - 14, y + h + 14), Vector2(x - 14 + _brk, y + h + 14), _speaker_color(), 1.5)
        draw_line(Vector2(x + w + 14 - _brk, y + h + 14), Vector2(x + w + 14, y + h + 14), _speaker_color(), 1.5)
        draw_line(Vector2(x + w + 14, y + h + 2), Vector2(x + w + 14, y + h + 14), _speaker_color(), 1.5)
        # speaker — sigil diamond + letter-spaced caps + short hairline tail
        var sc := _speaker_color()
        if E0.mono_bold:
                var sigil := _speaker_sigil()
                var sx := x
                for ch_i in sigil.length():
                        draw_string(E0.mono_bold, Vector2(sx, y + 4), sigil[ch_i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, sc)
                        sx += E0.mono_bold.get_string_size(sigil[ch_i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
                _diamond(Vector2(sx + 8.0, y - 1.0), 2.4, sc)
                var sp_x := sx + 18.0
                for ch_i in speaker.length():
                        draw_string(E0.mono_bold, Vector2(sp_x, y + 4), speaker[ch_i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, sc)
                        sp_x += E0.mono_bold.get_string_size(speaker[ch_i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 1.5
                draw_line(Vector2(sp_x + 8.0, y - 1.0), Vector2(sp_x + 8.0 + 34.0, y - 1.0), Color(sc.r, sc.g, sc.b, 0.45), 1.0)
        # wrapped text
        var text: String = lines[line_idx].substr(0, chars_shown)
        var wrapped := _wrap(text, w - 20.0, 16)
        var yy := y + 32.0
        for ln in wrapped:
                if E0.mono:
                        draw_string(E0.mono, Vector2(x + 6, yy), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, E0.PARCH)
                yy += 23.0
        # line counter + continue hint
        var done_line: bool = chars_shown >= lines[line_idx].length()
        if done_line:
                var bounce := sin(_blink * 4.0) * 2.0
                _diamond(Vector2(x + w - 116.0, y + h - 8.0 + bounce), 2.6, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.9) if fmod(_blink, 0.9) < 0.55 else Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.4))
                if E0.mono and fmod(_blink, 0.9) < 0.7:
                        draw_string(E0.mono, Vector2(x + w - 104.0, y + h - 2.0), "[F] CONTINUE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, E0.PARCH)
        if E0.mono:
                draw_string(E0.mono, Vector2(x, y + h - 2.0), "%d/%d" % [line_idx + 1, lines.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.6))

## A small geometric sigil per voice — the record marks who is speaking.
func _speaker_sigil() -> String:
        if speaker == "SYSTEM" or speaker.begins_with("TERMINAL"):
                return "\\\\"
        if speaker == "THE PENITENT":
                return "|"
        if speaker.contains("MARTYR"):
                return "X"
        if speaker.contains("MEASURER"):
                return "I"
        return "O"

func _speaker_color() -> Color:
        if speaker == "SYSTEM" or speaker.begins_with("TERMINAL"):
                return E0.CYAN
        if speaker == "THE PENITENT":
                return E0.BONE
        if speaker.contains("MARTYR"):
                return E0.CRIMSON
        if speaker.contains("MEASURER"):
                return E0.PARCH
        return E0.GOLD

func _diamond(c: Vector2, r: float, col: Color) -> void:
        var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
        draw_colored_polygon(pts, col)

func _wrap(text: String, width: float, size: int) -> PackedStringArray:
        var out := PackedStringArray()
        var line := ""
        for word in text.split(" "):
                var candidate := (line + " " + word).strip_edges(true, false)
                var w := 0.0
                if E0.mono:
                        w = E0.mono.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
                if w > width and not line.is_empty():
                        out.append(line)
                        line = word
                else:
                        line = candidate
        if not line.is_empty():
                out.append(line)
        return out
