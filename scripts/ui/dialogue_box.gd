## DialogueBox — the CENSUS RECORD: speech arrives on a hung sheet of
## parchment that slides up into the frame, grain and torn edge and filing
## holes and all. The speaker's seal is PRESSED into the wax at open (an
## iron strike: scale settles from 1.35), the line is written in dark ink
## over ledger ruling, and the sheet recedes when filed.
## WB-9 law: dialogue is a physical document of the census world.
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

# the sheet's physical entrance/exit + the seal's press
var sheet_t := 0.0         # 0 = below frame, 1 = seated  (eased)
var closing := false
var seal_press := 0.0      # 0 = iron in the air, 1 = wax cooled
var seal_sigil := 0
# draw-state accessors (smoke pins the laws)
var last_ruling_count := 0
var last_ink_col := Color.BLACK

const SHEET_RISE_TIME := 0.26
const SEAL_STRIKE_TIME := 0.34

func _ready() -> void:
        set_anchors_preset(Control.PRESET_FULL_RECT)
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        visible = false

func set_game(p_game) -> void:
        game = p_game

func seal_state() -> Dictionary:
        ## {sigil, press} — the wax identity and whether the iron has landed.
        return {"sigil": seal_sigil, "press": seal_press}

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
        closing = false
        sheet_t = 0.0
        seal_press = 0.0
        seal_sigil = _speaker_sigil_id()
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
        closing = true
        EventBus.dialogue_finished.emit(key)

func _process(delta: float) -> void:
        if active or closing:
                _blink += delta
                # the sheet slides up (or recedes), eased
                var target := 1.0 if active else 0.0
                var speed := 1.0 / SHEET_RISE_TIME if active else 1.0 / (SHEET_RISE_TIME * 0.8)
                sheet_t = move_toward(sheet_t, target, delta * speed)
                # the seal strikes within the first moments of the sheet seating
                if active and sheet_t > 0.55:
                        seal_press = minf(seal_press + delta / SEAL_STRIKE_TIME, 1.0)
                if closing and sheet_t <= 0.0:
                        closing = false
                        visible = false
        if active:
                chars_shown = mini(chars_shown + int(ceil(42.0 * delta)), lines[line_idx].length())
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
        if not (active or closing):
                return
        var vp := get_viewport_rect().size
        var w := minf(860.0, vp.x - 80.0)
        var x := (vp.x - w) * 0.5
        var h := 130.0
        # the sheet rises from below the frame — physical, eased
        var ease := 1.0 - pow(1.0 - clampf(sheet_t, 0.0, 1.0), 3.0)
        var y := vp.y - 190.0 + (1.0 - ease) * 90.0
        var alpha := clampf(sheet_t * 1.6, 0.0, 1.0)
        # the sheet: parchment, grain, aged edges, torn bottom, filing holes
        var sheet := Rect2(x - 14, y - 14, w + 28, h + 28)
        # the sheet's shadow first — it hangs in front of the world, which darkens
        # behind its bottom-right shoulder
        draw_rect(Rect2(sheet.position + Vector2(4, 7), sheet.size), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.40 * alpha))
        UICraft.parchment(self, sheet, "dialogue_" + key, true, 3)
        var sc := _speaker_color()
        # header rule + the speaker's filing line (stamped ink, darkened for paper)
        if E0.mono_bold:
                var ink_sc := Color(sc.r * 0.62, sc.g * 0.6, sc.b * 0.58)
                UICraft.stamp_text(self, E0.mono_bold, Vector2(x + 30, y + 2), speaker, ink_sc, 14, -0.006, 0)
        # the seal: pressed right of the speaker line, struck in wax
        var seal_pos := Vector2(x + w - 34.0, y - 2.0)
        UICraft.wax_seal(self, seal_pos, 11.0, _seal_wax_color(), seal_sigil, 0.35 + 0.65 * seal_press)
        # strike impact: the wax lands big and settles (physical press)
        if seal_press < 1.0 and seal_press > 0.0:
                var burst := (1.0 - seal_press) * 0.35
                UICraft.wax_seal(self, seal_pos, 11.0 * (1.0 + burst), Color(sc.r, sc.g, sc.b, 0.10), seal_sigil, 1.0)
        # ledger ruling under the speaker line
        UICraft.ruling(self, Vector2(x + 30, y + 8.0), Vector2(x + w - 56.0, y + 8.0), true)
        # wrapped text as INK on parchment — dark, written, ruled.
        # during the recess the writer has already moved past the last line —
        # the sheet shows the final words as it files away
        var li := clampi(line_idx, 0, lines.size() - 1)
        var text: String = lines[li].substr(0, chars_shown)
        var wrapped := _wrap(text, w - 48.0, 16)
        var yy := y + 34.0
        var ink := Color(0.16, 0.13, 0.10, 0.94)
        last_ink_col = ink
        last_ruling_count = 0
        for ln in wrapped:
                if E0.mono:
                        draw_string(E0.mono, Vector2(x + 30, yy), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ink)
                        UICraft.ruling(self, Vector2(x + 30, yy + 5.0), Vector2(x + w - 24.0, yy + 5.0))
                        last_ruling_count += 1
                yy += 23.0
        # the ink pot caret: a small nib diamond where the writing stops
        if E0.mono and chars_shown < lines[li].length():
                var partial: String = wrapped[wrapped.size() - 1] if not wrapped.is_empty() else ""
                var px := x + 30.0
                if E0.mono:
                        px += E0.mono.get_string_size(partial, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 4.0
                var nib := 0.5 + 0.5 * sin(_blink * 7.0)
                var ncol := Color(ink.r, ink.g, ink.b, 0.4 + 0.6 * nib)
                var pts := PackedVector2Array([Vector2(px, yy - 23.0 - 9.0), Vector2(px + 4.5, yy - 23.0 - 4.0), Vector2(px, yy - 23.0 + 1.0), Vector2(px - 4.5, yy - 23.0 - 4.0)])
                draw_colored_polygon(pts, ncol)
        # line counter + continue mark — stamped, not floating
        var done_line: bool = chars_shown >= lines[li].length()
        if done_line:
                var bounce := sin(_blink * 4.0) * 2.0
                var dcol := Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.9) if fmod(_blink, 0.9) < 0.55 else Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.4)
                _diamond(Vector2(x + w - 116.0, y + h - 8.0 + bounce), 2.6, dcol)
                if E0.mono and fmod(_blink, 0.9) < 0.7:
                        UICraft.stamp_text(self, E0.mono, Vector2(x + w - 104.0, y + h - 2.0), "FILE  [F]", Color(0.30, 0.22, 0.14, 0.85), 12, 0.035, 5)
        if E0.mono:
                UICraft.stamp_text(self, E0.mono, Vector2(x + 30, y + h - 2.0), "%d / %d" % [line_idx + 1, lines.size()], Color(0.35, 0.28, 0.20, 0.6), 12, -0.01, 9)

## The seal's wax carries the speaker's voice color, deepened to wax density.
func _seal_wax_color() -> Color:
        var sc := _speaker_color()
        return Color(sc.r * 0.55 + 0.12, sc.g * 0.55 + 0.06, sc.b * 0.55 + 0.05)

func _speaker_sigil_id() -> int:
        if speaker == "SYSTEM" or speaker.begins_with("TERMINAL"):
                return 0
        if speaker == "THE PENITENT":
                return 2
        if speaker.contains("MARTYR"):
                return 1
        if speaker.contains("MEASURER"):
                return 3
        return 4

## A small geometric sigil per voice — the record marks who is speaking.
func _speaker_sigil() -> String:
        match _speaker_sigil_id():
                0: return "\\\\"
                2: return "|"
                1: return "X"
                3: return "I"
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
