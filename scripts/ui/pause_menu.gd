## PauseMenu — RESUME / RECORDS (the codex: fragments + observed entities) /
## OPTIONS / RESTART FROM ANCHOR / QUIT TO TITLE. The codex is real: only
## found fragments and actually-observed entities are listed.
class_name PauseMenu
extends Control

signal resume_requested
signal restart_requested
signal quit_to_title_requested
signal options_requested
signal city_requested

const TAB_MEMORY := 0
const TAB_RECORDS := 1

var idx := 0
var menu := []
var screen := 0            # 0 menu · 1 codex · 2 options handoff (never drawn)
var tab := TAB_MEMORY
var records_scroll := 0
var anim_t := 0.0
var _reading_pushed := false

func _ready() -> void:
        set_anchors_preset(Control.PRESET_FULL_RECT)
        visible = false
        _rebuild()

func _rebuild() -> void:
        menu = [
                {"label": "RESUME", "action": "resume"},
                {"label": "RECORDS", "action": "records"},
                {"label": "THE CITY", "action": "city"},
                {"label": "OPTIONS", "action": "options"},
                {"label": "RESTART FROM ANCHOR", "action": "restart"},
                {"label": "QUIT TO TITLE", "action": "quit"},
        ]

func open() -> void:
        visible = true
        idx = 0
        screen = 0
        tab = TAB_MEMORY
        records_scroll = 0
        get_tree().paused = true
        if not _reading_pushed:
                FX.push_reading()
                _reading_pushed = true

func close() -> void:
        visible = false
        get_tree().paused = false
        if _reading_pushed:
                FX.pop_reading()
                _reading_pushed = false

func _process(delta: float) -> void:
        if not visible:
                return
        anim_t += delta
        if GameState.options_open or GameState.map_open:
                queue_redraw()
                return
        if Input.is_action_just_pressed("pause"):
                if screen == 1:
                        screen = 0
                else:
                        close()
                        resume_requested.emit()
                return
        if screen == 1:
                _codex_input()
        else:
                _menu_input()
        queue_redraw()

func _menu_input() -> void:
        if Input.is_action_just_pressed("move_up"):
                idx = (idx - 1 + menu.size()) % menu.size()
                AudioManager.play_sfx("sfx_ui_move", -8.0)
        if Input.is_action_just_pressed("move_down"):
                idx = (idx + 1) % menu.size()
                AudioManager.play_sfx("sfx_ui_move", -8.0)
        if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump"):
                _confirm()

func _codex_input() -> void:
        var rows := GameState.observed_rows()
        var visible_rows := _records_visible_rows()
        if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump"):
                AudioManager.play_sfx("sfx_ui_confirm", -6.0)
                screen = 0
                return
        if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
                var dir := -1 if Input.is_action_just_pressed("move_left") else 1
                tab = wrapi(tab + dir, 0, 2)
                records_scroll = 0
                AudioManager.play_sfx("sfx_ui_move", -8.0)
                return
        if tab == TAB_RECORDS and rows.size() > visible_rows:
                if Input.is_action_just_pressed("move_up"):
                        records_scroll = maxi(0, records_scroll - 1)
                        AudioManager.play_sfx("sfx_ui_move", -12.0)
                if Input.is_action_just_pressed("move_down"):
                        records_scroll = mini(rows.size() - visible_rows, records_scroll + 1)
                        AudioManager.play_sfx("sfx_ui_move", -12.0)

func _records_visible_rows() -> int:
        ## Rows that fit between the header block and the footer hints.
        var vp := get_viewport_rect().size
        var top := 200.0
        var bottom := vp.y - 96.0
        return maxi(1, int((bottom - top) / 66.0))

func clamp_records_scroll() -> void:
        var rows := GameState.observed_rows()
        var visible_rows := _records_visible_rows()
        records_scroll = clampi(records_scroll, 0, maxi(0, rows.size() - visible_rows))

func _confirm() -> void:
        AudioManager.play_sfx("sfx_ui_confirm", -4.0)
        if screen == 1:
                screen = 0
                return
        match String(menu[idx]["action"]):
                "resume":
                        close()
                        resume_requested.emit()
                "records":
                        screen = 1
                "city":
                        city_requested.emit()
                "options":
                        options_requested.emit()
                "restart":
                        close()
                        restart_requested.emit()
                "quit":
                        close()
                        quit_to_title_requested.emit()

func _draw() -> void:
        var vp := get_viewport_rect().size
        draw_rect(Rect2(Vector2.ZERO, vp), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.82))
        if screen == 1:
                _draw_codex(vp)
                return
        if E0.mono_bold:
                var pt := "PAUSED"
                var ptw := E0.mono_bold.get_string_size(pt, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
                var ptx := (vp.x - ptw) * 0.5
                draw_string(E0.mono_bold, Vector2(ptx, vp.y * 0.3), pt, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, E0.BONE)
                draw_line(Vector2(ptx - 30.0, vp.y * 0.3 + 12.0), Vector2(ptx + ptw + 30.0, vp.y * 0.3 + 12.0), Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.6), 1.0)
                _diamond(Vector2(ptx - 42.0, vp.y * 0.3 + 8.0), 2.6, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.7))
                _diamond(Vector2(ptx + ptw + 42.0, vp.y * 0.3 + 8.0), 2.6, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.7))
        var my := vp.y * 0.42
        for i in menu.size():
                var sel: bool = i == idx
                var col := E0.BONE if sel else E0.PARCH
                if E0.mono:
                        var label: String = menu[i]["label"]
                        var lw := E0.mono.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
                        var lx := (vp.x - lw) * 0.5
                        if sel:
                                draw_rect(Rect2(lx - 56.0, my - 18.0, lw + 112.0, 27.0), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.7))
                                draw_rect(Rect2(lx - 56.0, my - 18.0, lw + 112.0, 1.0), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.3))
                                draw_rect(Rect2(lx - 56.0, my + 8.0, lw + 112.0, 1.0), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.3))
                                _diamond(Vector2(lx - 30.0, my - 5.0), 2.8, E0.GOLD if fmod(anim_t, 1.0) < 0.6 else Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.4))
                                _diamond(Vector2(lx + lw + 30.0, my - 5.0), 2.8, E0.GOLD if fmod(anim_t, 1.0) < 0.6 else Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.4))
                        draw_string(E0.mono, Vector2(lx, my), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
                my += 36.0
        if E0.mono:
                var hint := "CONSISTENCY %03d%% · S%d — %s" % [GameState.consistency, GameState.stage, GameState.stage_name()]
                var hw := E0.mono.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
                draw_string(E0.mono, Vector2((vp.x - hw) * 0.5, vp.y * 0.3 + 26.0), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, E0.CYAN)

# ------------------------------------------------------------------ codex
func _draw_codex(vp: Vector2) -> void:
        if E0.mono_bold:
                draw_string(E0.mono_bold, Vector2(120.0, 84.0), "THE RECORD", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, E0.BONE)
        # tab bar — MEMORY | RECORDS, gold rule under the active tab
        var tab_x := 120.0
        var tabs := [["MEMORY", TAB_MEMORY], ["RECORDS", TAB_RECORDS]]
        for t in tabs:
                var label: String = t[0]
                var tid: int = t[1]
                var active: bool = tid == tab
                if E0.mono:
                        var col := E0.BONE if active else E0.DIM
                        draw_string(E0.mono, Vector2(tab_x, 114.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
                        var lw := E0.mono.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
                        if active:
                                draw_line(Vector2(tab_x, 120.0), Vector2(tab_x + lw, 120.0), E0.GOLD, 1.5)
                        else:
                                _diamond(Vector2(tab_x + lw + 10.0, 110.0), 2.0, Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.9))
                        tab_x += lw + 44.0
        # counts on the right of the tab bar
        if E0.mono:
                var count := ""
                if tab == TAB_MEMORY:
                        count = "FOUND: %d / 4" % GameState.fragments.size()
                else:
                        count = "OBSERVED: %d" % GameState.observed.size()
                var cw := E0.mono.get_string_size(count, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
                draw_string(E0.mono, Vector2(vp.x - 120.0 - cw, 112.0), count, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, E0.DIM)
        if tab == TAB_MEMORY:
                _draw_memory(vp)
        else:
                _draw_records(vp)
        # footer hints
        if E0.mono:
                var hint := "LEFT/RIGHT SWITCH · UP/DOWN SCROLL · F BACK"
                var hw := E0.mono.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
                draw_string(E0.mono, Vector2(120.0, vp.y - 48.0), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, E0.DIM)

func _draw_memory(vp: Vector2) -> void:
        var y := 160.0
        var x := 120.0
        var w := vp.x - 240.0
        # found fragments — real records only, framed cards
        for frag_id in GameState.fragments:
                var def: Dictionary = GameState.FRAGMENT_DEFS.get(frag_id, {})
                if def.is_empty():
                        continue
                draw_rect(Rect2(x, y - 16.0, w, 58.0), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.8))
                draw_rect(Rect2(x, y - 16.0, w, 58.0), Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.35), false, 1.0)
                draw_rect(Rect2(x, y - 16.0, 3.0, 58.0), E0.GOLD)
                _diamond(Vector2(x + 16.0, y - 4.0), 2.2, E0.GOLD)
                draw_string(E0.mono, Vector2(x + 26.0, y), String(def["code"]) + "  ·  " + String(def["title"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, E0.BONE)
                draw_string(E0.mono, Vector2(x + w - 16.0 - E0.mono.get_string_size("STATE: " + String(def["integrity"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x, y - 2.0), "STATE: " + String(def["integrity"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, E0.DIM)
                draw_string(E0.mono, Vector2(x + 26.0, y + 20.0), String(def["note"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, E0.PARCH)
                y += 70.0
        if GameState.fragments.is_empty():
                draw_string(E0.mono, Vector2(x, y), "NO FRAGMENTS FOUND. MEMORY IS NOT ISSUED. IT IS RECOVERED.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, E0.DIM)
                y += 30.0
        # the withheld sixth
        draw_string(E0.mono, Vector2(x, y + 18.0), "A SIXTH FUNDAMENTAL IS WHISPERED TO EXIST.", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.7))
        draw_string(E0.mono, Vector2(x, y + 36.0), "IT IS NOT WRITTEN ANYWHERE. THAT IS NOT THE SAME AS ABSENT.", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, E0.DIM)

func _draw_records(vp: Vector2) -> void:
        var rows := GameState.observed_rows()
        var x := 120.0
        var w := vp.x - 240.0
        var y := 200.0
        if rows.is_empty():
                draw_string(E0.mono, Vector2(x, y), "NOTHING HAS BEEN OBSERVED YET.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, E0.DIM)
                draw_string(E0.mono, Vector2(x, y + 24.0), "THE CITY KEEPS ITS OWN RECORD. TAB READS WHAT IT HAS SHOWN YOU.", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, E0.DIM)
                return
        var visible_rows := _records_visible_rows()
        clamp_records_scroll()
        var end := mini(rows.size(), records_scroll + visible_rows)
        for i in range(records_scroll, end):
                var r: Dictionary = rows[i]
                # zebra backing + hairline frame — rows read as filed cards
                var zebra := 0.62 if (i % 2) == 0 else 0.8
                draw_rect(Rect2(x, y - 16.0, w, 54.0), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, zebra))
                draw_rect(Rect2(x, y - 16.0, w, 54.0), Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.32), false, 1.0)
                draw_rect(Rect2(x, y - 16.0, 3.0, 54.0), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.85))
                _diamond(Vector2(x + 15.0, y - 3.0), 2.2, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.8))
                # title + ID live on ONE line — no eye-travel to the far edge
                draw_string(E0.mono, Vector2(x + 26.0, y - 2.0), String(r["display"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, E0.BONE)
                var id_txt := "  ·  " + String(r["id"])
                draw_string(E0.mono, Vector2(x + 26.0 + E0.mono.get_string_size(String(r["display"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 2.0, y - 1.0), id_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, E0.DIM)
                # type stays right — a classification stamp, readable at a glance
                var type_txt := String(r["type"])
                draw_string(E0.mono, Vector2(x + w - E0.mono.get_string_size(type_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x - 14.0, y - 1.0), type_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.95))
                var mem := String(r["memory"])
                if not mem.is_empty():
                        draw_string(E0.mono, Vector2(x + 26.0, y + 18.0), mem, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, E0.PARCH)
                y += 66.0
        # scroll position
        if rows.size() > visible_rows:
                if E0.mono:
                        var scr := "%d – %d / %d" % [records_scroll + 1, end, rows.size()]
                        var sw := E0.mono.get_string_size(scr, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
                        draw_string(E0.mono, Vector2(vp.x - 120.0 - sw, vp.y - 72.0), scr, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, E0.DIM)
                # scrollbar
                var track_y := 200.0
                var track_h := float(visible_rows) * 66.0
                var grip_h := track_h * (float(visible_rows) / float(rows.size()))
                var grip_y := track_y + (track_h - grip_h) * (float(records_scroll) / float(maxi(1, rows.size() - visible_rows)))
                draw_line(Vector2(vp.x - 108.0, track_y), Vector2(vp.x - 108.0, track_y + track_h), Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.7), 2.0)
                draw_line(Vector2(vp.x - 108.0, grip_y), Vector2(vp.x - 108.0, grip_y + grip_h), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.8), 2.0)

func _diamond(c: Vector2, r: float, col: Color) -> void:
        var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
        draw_colored_polygon(pts, col)
