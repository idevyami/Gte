## PauseMenu — RESUME / MEMORY (the fragment index) / RESTART FROM ANCHOR /
## QUIT TO TITLE. The memory index is real: only found fragments are listed.
class_name PauseMenu
extends Control

signal resume_requested
signal restart_requested
signal quit_to_title_requested

var idx := 0
var menu := []
var show_memory := false
var anim_t := 0.0

func _ready() -> void:
        set_anchors_preset(Control.PRESET_FULL_RECT)
        visible = false
        _rebuild()

func _rebuild() -> void:
        menu = [
                {"label": "RESUME", "action": "resume"},
                {"label": "MEMORY", "action": "memory"},
                {"label": "RESTART FROM ANCHOR", "action": "restart"},
                {"label": "QUIT TO TITLE", "action": "quit"},
        ]

func open() -> void:
        visible = true
        idx = 0
        show_memory = false
        get_tree().paused = true

func close() -> void:
        visible = false
        get_tree().paused = false

func _process(delta: float) -> void:
        if not visible:
                return
        anim_t += delta
        if Input.is_action_just_pressed("pause"):
                if show_memory:
                        show_memory = false
                else:
                        close()
                        resume_requested.emit()
                return
        if Input.is_action_just_pressed("move_up"):
                idx = (idx - 1 + menu.size()) % menu.size()
                AudioManager.play_sfx("sfx_ui_move", -8.0)
        if Input.is_action_just_pressed("move_down"):
                idx = (idx + 1) % menu.size()
                AudioManager.play_sfx("sfx_ui_move", -8.0)
        if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump"):
                _confirm()
        queue_redraw()

func _confirm() -> void:
        AudioManager.play_sfx("sfx_ui_confirm", -4.0)
        if show_memory:
                show_memory = false
                return
        match String(menu[idx]["action"]):
                "resume":
                        close()
                        resume_requested.emit()
                "memory":
                        show_memory = true
                "restart":
                        close()
                        restart_requested.emit()
                "quit":
                        close()
                        quit_to_title_requested.emit()

func _draw() -> void:
        var vp := get_viewport_rect().size
        draw_rect(Rect2(Vector2.ZERO, vp), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.82))
        if show_memory:
                _draw_memory(vp)
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

func _draw_memory(vp: Vector2) -> void:
        if E0.mono_bold:
                draw_string(E0.mono_bold, Vector2(120.0, 90.0), "MEMORY INDEX", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, E0.BONE)
        if E0.mono:
                draw_string(E0.mono, Vector2(120.0, 114.0), "FOUND: %d / 4" % GameState.fragments.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, E0.DIM)
        var y := 160.0
        var x := 120.0
        var w := vp.x - 240.0
        # found fragments — real records only
        for frag_id in GameState.fragments:
                var def: Dictionary = GameState.FRAGMENT_DEFS.get(frag_id, {})
                if def.is_empty():
                        continue
                draw_rect(Rect2(x, y - 16.0, w, 58.0), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.8))
                draw_rect(Rect2(x, y - 16.0, 3.0, 58.0), E0.GOLD)
                draw_string(E0.mono, Vector2(x + 14.0, y), String(def["code"]) + "  ·  " + String(def["title"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, E0.BONE)
                draw_string(E0.mono, Vector2(x + 14.0, y + 20.0), "STATE: " + String(def["integrity"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, E0.DIM)
                draw_string(E0.mono, Vector2(x + 14.0, y + 38.0), String(def["note"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, E0.PARCH)
                y += 70.0
        if GameState.fragments.is_empty():
                draw_string(E0.mono, Vector2(x, y), "NO FRAGMENTS FOUND. MEMORY IS NOT ISSUED. IT IS RECOVERED.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, E0.DIM)
                y += 30.0
        # the withheld sixth
        draw_string(E0.mono, Vector2(x, y + 18.0), "A SIXTH FUNDAMENTAL IS WHISPERED TO EXIST.", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.7))
        draw_string(E0.mono, Vector2(x, y + 36.0), "IT IS NOT WRITTEN ANYWHERE. THAT IS NOT THE SAME AS ABSENT.", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, E0.DIM)
        draw_string(E0.mono, Vector2(x, vp.y - 60.0), "[F] BACK", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, E0.DIM)

func _diamond(c: Vector2, r: float, col: Color) -> void:
        var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
        draw_colored_polygon(pts, col)
