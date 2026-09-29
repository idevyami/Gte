## OptionsScreen — the settings the vessel is permitted to keep: bus volumes,
## screen shake, dialogue ticks, artwork mode, and the erasure of records.
## Runs from the title (tree running) and from pause (tree paused) — this node
## always processes. Persisted instantly to user://settings.json.
class_name OptionsScreen
extends Control

signal closed
signal save_erased

var idx := 0
var anim_t := 0.0
var parent_mode := "title"     # "title" | "pause"
var erase_happened := false

var _rows: Array = []
var _erase_state := 0          # 0 idle · 1 armed · 2 done
var _erase_timer := 0.0
var _hold_dir := 0
var _hold_t := 0.0
var _open_grace := 0           # frames of input silence after open

const SLIDER_W := 230.0
const STEP := 0.1

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        set_anchors_preset(Control.PRESET_FULL_RECT)
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        visible = false
        _rebuild()

func _rebuild() -> void:
        _rows = [
                {"kind": "slider", "label": "MASTER VOLUME", "key": "master"},
                {"kind": "slider", "label": "MUSIC", "key": "music"},
                {"kind": "slider", "label": "AMBIENCE", "key": "ambient"},
                {"kind": "slider", "label": "EFFECTS", "key": "sfx"},
                {"kind": "slider", "label": "SCREEN SHAKE", "key": "shake"},
                {"kind": "slider", "label": "VIBRATION", "key": "vibration"},
                {"kind": "toggle", "label": "DIALOGUE TICKS", "key": "blips", "on": "ON", "off": "OFF"},
                {"kind": "toggle", "label": "ARTWORK", "key": "art_mode", "on": "PAINTED", "off": "PROCEDURAL"},
                {"kind": "erase", "label": "ERASE SAVE"},
                {"kind": "back", "label": "BACK"},
        ]

func open(parent: String) -> void:
        parent_mode = parent
        visible = true
        idx = 0
        _erase_state = 0
        _hold_dir = 0
        _hold_t = 0.0
        _open_grace = 10
        GameState.options_open = true

func close() -> void:
        visible = false
        GameState.options_open = false
        closed.emit()

func _process(delta: float) -> void:
        if not visible:
                return
        anim_t += delta
        if _open_grace > 0:
                _open_grace -= 1
                queue_redraw()
                return
        if _erase_state == 1:
                _erase_timer -= delta
                if _erase_timer <= 0.0:
                        _erase_state = 0
        elif _erase_state == 2:
                _erase_timer -= delta
                if _erase_timer <= 0.0:
                        _erase_state = 0
        if Input.is_action_just_pressed("pause"):
                AudioManager.play_sfx("sfx_ui_deny", -8.0)
                close()
                return
        if Input.is_action_just_pressed("move_up"):
                idx = (idx - 1 + _rows.size()) % _rows.size()
                _hold_dir = 0
                AudioManager.play_sfx("sfx_ui_move", -8.0)
        if Input.is_action_just_pressed("move_down"):
                idx = (idx + 1) % _rows.size()
                _hold_dir = 0
                AudioManager.play_sfx("sfx_ui_move", -8.0)
        if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump"):
                _confirm()
        _handle_lr(delta)
        queue_redraw()

func _handle_lr(delta: float) -> void:
        var dir := 0
        if Input.is_action_pressed("move_left"):
                dir -= 1
        if Input.is_action_pressed("move_right"):
                dir += 1
        if dir == 0:
                _hold_dir = 0
                _hold_t = 0.0
                return
        if dir != _hold_dir:
                _hold_dir = dir
                _hold_t = 0.0
                _adjust(dir)   # first press steps immediately
                return
        # hold to repeat
        _hold_t += delta
        if _hold_t > 0.28:
                var over := _hold_t - 0.28
                while over > 0.07:
                        _adjust(dir)
                        over -= 0.07
                _hold_t = 0.28 + over

func _adjust(dir: int) -> void:
        var row: Dictionary = _rows[idx]
        var kind := String(row["kind"])
        if kind == "slider":
                var mx := float(row.get("max", 1.0))
                var v := clampf(float(GameState.settings[row["key"]]) + dir * STEP, 0.0, mx)
                GameState.set_setting(String(row["key"]), v)
                AudioManager.play_sfx("sfx_ui_move", -14.0)
        elif kind == "toggle":
                _cycle(row)
                AudioManager.play_sfx("sfx_ui_confirm", -10.0)
        elif kind == "erase":
                _confirm()

func _cycle(row: Dictionary) -> void:
        var key := String(row["key"])
        if key == "blips":
                GameState.set_setting(key, not bool(GameState.settings[key]))
        elif key == "art_mode":
                GameState.set_setting(key, "procedural" if String(GameState.settings[key]) == "painted" else "painted")

func _confirm() -> void:
        var row: Dictionary = _rows[idx]
        match String(row["kind"]):
                "toggle":
                        _cycle(row)
                        AudioManager.play_sfx("sfx_ui_confirm", -10.0)
                "erase":
                        if _erase_state == 0:
                                if not GameState.has_save():
                                        AudioManager.play_sfx("sfx_ui_deny", -6.0)
                                        return
                                _erase_state = 1
                                _erase_timer = 2.4
                                AudioManager.play_sfx("sfx_ui_deny", -6.0)
                        elif _erase_state == 1:
                                GameState.clear_save()
                                _erase_state = 2
                                _erase_timer = 2.0
                                erase_happened = true
                                save_erased.emit()
                                AudioManager.play_sfx("sfx_correction", -4.0)
                        else:
                                AudioManager.play_sfx("sfx_ui_deny", -8.0)
                "back":
                        AudioManager.play_sfx("sfx_ui_confirm", -6.0)
                        close()

# ------------------------------------------------------------------ drawing
func _draw() -> void:
        var vp := get_viewport_rect().size
        draw_rect(Rect2(Vector2.ZERO, vp), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.9))
        var cx := vp.x * 0.5
        # header — ruled like the pause title
        var hy := vp.y * 0.16
        if E0.mono_bold:
                var t := "OPTIONS"
                var tw := E0.mono_bold.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
                draw_string(E0.mono_bold, Vector2(cx - tw * 0.5, hy), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, E0.BONE)
                draw_line(Vector2(cx - tw * 0.5 - 30.0, hy + 12.0), Vector2(cx + tw * 0.5 + 30.0, hy + 12.0), Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.6), 1.0)
                _diamond(Vector2(cx - tw * 0.5 - 42.0, hy + 8.0), 2.6, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.7))
                _diamond(Vector2(cx + tw * 0.5 + 42.0, hy + 8.0), 2.6, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.7))
        if E0.mono:
                var sub := "THE DESIGN PERMITS ADJUSTMENT"
                var sw := E0.mono.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
                draw_string(E0.mono, Vector2(cx - sw * 0.5, hy + 26.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, E0.DIM)
        # rows
        var col_w := 560.0
        var x0 := cx - col_w * 0.5
        var y := vp.y * 0.30
        for i in _rows.size():
                var row: Dictionary = _rows[i]
                var sel: bool = i == idx
                _draw_row(row, x0, y, col_w, sel)
                y += 42.0
        # footer — controls reference
        if E0.mono:
                var fy := vp.y - 64.0
                var l1 := "A/D OR ARROWS ADJUST · F CONFIRM · ESC BACK"
                var l1w := E0.mono.get_string_size(l1, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
                draw_string(E0.mono, Vector2(cx - l1w * 0.5, fy), l1, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, E0.DIM)
                var l2 := "GAMEPAD: STICK/D-PAD MOVE · A CONFIRM · B ROLL · Y OBSERVE · RB MODIFY · START PAUSE"
                var l2w := E0.mono.get_string_size(l2, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
                draw_string(E0.mono, Vector2(cx - l2w * 0.5, fy + 18.0), l2, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.7))

func _draw_row(row: Dictionary, x: float, y: float, w: float, sel: bool) -> void:
        var kind := String(row["kind"])
        var label := String(row["label"])
        var label_col := E0.BONE if sel else E0.PARCH
        if kind == "erase" and _erase_state == 1:
                label = "CONFIRM — ERASE EVERYTHING?"
                label_col = E0.CRIMSON
        elif kind == "erase" and _erase_state == 2:
                label = "THE RECORD IS ERASED"
                label_col = E0.DIM
        elif kind == "erase" and not GameState.has_save():
                label_col = Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.55)
        # selection strip
        if sel:
                draw_rect(Rect2(x - 18.0, y - 17.0, w + 36.0, 27.0), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.72))
                draw_rect(Rect2(x - 18.0, y - 17.0, w + 36.0, 1.0), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.3))
                draw_rect(Rect2(x - 18.0, y + 9.0, w + 36.0, 1.0), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.3))
        if E0.mono:
                draw_string(E0.mono, Vector2(x, y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, label_col)
        # right-aligned control
        if kind == "slider":
                _draw_slider(row, x + w - SLIDER_W, y - 5.0, sel)
        elif kind == "toggle":
                var key := String(row["key"])
                var on: bool
                if key == "blips":
                        on = bool(GameState.settings[key])
                else:
                        on = String(GameState.settings[key]) == "painted"
                var val := String(row["on"]) if on else String(row["off"])
                var col: Color = E0.GOLD if on else E0.DIM
                if E0.mono:
                        var vw := E0.mono.get_string_size(val, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
                        draw_string(E0.mono, Vector2(x + w - vw, y), val, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
        elif kind == "erase":
                var note := ""
                if _erase_state == 0 and GameState.has_save():
                        note = "ONE RECORD EXISTS"
                elif _erase_state == 1:
                        note = "PRESS AGAIN"
                elif not GameState.has_save():
                        note = "NOTHING REMAINS"
                if E0.mono and not note.is_empty():
                        var nw := E0.mono.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
                        draw_string(E0.mono, Vector2(x + w - nw, y), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.8))

func _draw_slider(row: Dictionary, x: float, y: float, sel: bool) -> void:
        var mx := float(row.get("max", 1.0))
        var v := clampf(float(GameState.settings[row["key"]]) / mx, 0.0, 1.0)
        # track
        draw_line(Vector2(x, y), Vector2(x + SLIDER_W, y), Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.9), 2.0)
        # notch ticks at each 25%
        for k in 5:
                var nx := x + SLIDER_W * (float(k) / 4.0)
                draw_line(Vector2(nx, y - 4.0), Vector2(nx, y + 4.0), Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.55), 1.0)
        # fill
        draw_line(Vector2(x, y), Vector2(x + SLIDER_W * v, y), E0.GOLD, 2.0)
        # thumb diamond
        var th := Vector2(x + SLIDER_W * v, y)
        var tcol := E0.GOLD if sel else Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.6)
        if sel:
                tcol = E0.GOLD if fmod(anim_t, 1.0) < 0.6 else Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.4)
        _diamond(th, 4.0, tcol)
        # percentage
        if E0.mono:
                var pct := "%d%%" % roundi(float(GameState.settings[row["key"]]) * 100.0)
                draw_string(E0.mono, Vector2(x + SLIDER_W + 12.0, y + 5.0), pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, E0.DIM)

func _diamond(c: Vector2, r: float, col: Color) -> void:
        var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
        draw_colored_polygon(pts, col)
