## TitleScreen — the first frame of the game: ash, the city backdrop, and a
## designation instead of a title screen promise.
class_name TitleScreen
extends Control

signal new_game_requested
signal continue_requested

var menu: Array = []
var idx := 0
var anim_t := 0.0
var _tex: Texture2D
var _flicker := 0.0

func _ready() -> void:
        set_anchors_preset(Control.PRESET_FULL_RECT)
        _tex = load("res://art/backdrops/backdrop_city.png")
        visible = true
        _rebuild_menu()

func _rebuild_menu() -> void:
        menu = [{"label": "RESTORE THE WORLD", "action": "new"}]
        if GameState.has_save():
                menu.append({"label": "CONTINUE", "action": "continue"})
        menu.append({"label": "QUIT", "action": "quit"})
        idx = 0

func _process(delta: float) -> void:
        anim_t += delta
        _flicker = maxf(0.0, _flicker - delta * 4.0)
        if randf() < 0.003:
                _flicker = 1.0
        if Input.is_action_just_pressed("move_up"):
                idx = (idx - 1 + menu.size()) % menu.size()
                AudioManager.play_sfx("sfx_ui_move", -8.0)
        if Input.is_action_just_pressed("move_down"):
                idx = (idx + 1) % menu.size()
                AudioManager.play_sfx("sfx_ui_move", -8.0)
        if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump"):
                _confirm()
        if Input.is_action_just_pressed("attack"):
                _confirm()
        queue_redraw()

func _confirm() -> void:
        AudioManager.play_sfx("sfx_ui_confirm", -4.0)
        var action: String = menu[idx]["action"]
        if action == "new":
                new_game_requested.emit()
        elif action == "continue":
                continue_requested.emit()
        elif action == "quit":
                get_tree().quit()

func _draw() -> void:
        var vp := get_viewport_rect().size
        draw_rect(Rect2(Vector2.ZERO, vp), E0.VOID)
        # backdrop, dark
        if _tex != null:
                var ts := _tex.get_size()
                var scale_k := maxf(vp.x / ts.x, vp.y / ts.y) * 1.1
                var dst := Rect2(Vector2.ZERO, ts * scale_k)
                dst.position = (vp - dst.size) * 0.5 + Vector2(0, 30)
                draw_texture_rect_region(_tex, dst, Rect2(Vector2.ZERO, ts), Color(0.5, 0.5, 0.52, 0.9))
        # darkening gradient
        for i in 8:
                var t := float(i) / 7.0
                draw_rect(Rect2(0, vp.y * t, vp.x, vp.y / 7.0), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.35 * t))
        # falling ash
        for i in 40:
                var seed_a := float(i) * 1.7
                var ay := fmod(anim_t * (18.0 + fmod(seed_a, 20.0)) + seed_a * 91.0, vp.y + 40.0) - 20.0
                var ax := fmod(seed_a * 137.0 + sin(anim_t * 0.7 + seed_a) * 14.0, vp.x)
                draw_circle(Vector2(ax, ay), fmod(seed_a, 1.6) + 0.6, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.16))
        # title
        var title_y := vp.y * 0.34
        var glitch := _flicker > 0.0
        if E0.mono_bold:
                var big := 74
                var title := "ENTITY_000"
                var tw := E0.mono_bold.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, big).x
                var tx := (vp.x - tw) * 0.5
                if glitch:
                        draw_string(E0.mono_bold, Vector2(tx + 6.0 * _flicker, title_y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, big, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.5))
                        draw_string(E0.mono_bold, Vector2(tx - 5.0 * _flicker, title_y + 3.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, big, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.4))
                draw_string(E0.mono_bold, Vector2(tx, title_y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, big, E0.BONE)
        if E0.mono:
                var sub := "NO NAME · NO HISTORY · NO MEMORY · THESE WERE NOT ISSUED"
                var sw := E0.mono.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
                draw_string(E0.mono, Vector2((vp.x - sw) * 0.5, title_y + 30.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, E0.DIM)
        if E0.serif:
                var tag := "If you were created for a purpose \u2014 do you have the right to reject it?"
                var gw := E0.serif.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
                draw_string(E0.serif, Vector2((vp.x - gw) * 0.5, title_y + 66.0), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.85))
        # menu
        var my := vp.y * 0.66
        for i in menu.size():
                var m: Dictionary = menu[i]
                var sel: bool = i == idx
                var col := E0.BONE if sel else E0.PARCH
                if E0.mono_bold:
                        var label: String = m["label"]
                        var lw := E0.mono_bold.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
                        var lx := (vp.x - lw) * 0.5
                        if sel:
                                # selection strip + gold diamonds + side rules
                                draw_rect(Rect2(lx - 64.0, my - 19.0, lw + 128.0, 30.0), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.72))
                                draw_rect(Rect2(lx - 64.0, my - 19.0, lw + 128.0, 1.0), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.35))
                                draw_rect(Rect2(lx - 64.0, my + 10.0, lw + 128.0, 1.0), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.35))
                                var dc := E0.GOLD if fmod(anim_t, 1.0) < 0.6 else Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.4)
                                _diamond(Vector2(lx - 34.0, my - 6.0), 3.4, dc)
                                _diamond(Vector2(lx + lw + 34.0, my - 6.0), 3.4, dc)
                                draw_line(Vector2(lx - 58.0, my - 6.0), Vector2(lx - 44.0, my - 6.0), Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.8), 1.0)
                                draw_line(Vector2(lx + lw + 44.0, my - 6.0), Vector2(lx + lw + 58.0, my - 6.0), Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.8), 1.0)
                        draw_string(E0.mono_bold, Vector2(lx, my), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, col)
                my += 40.0
        # footer
        if E0.mono:
                var foot := "NATIVE GODOT 4.4 · GDSCRIPT · VERTICAL SLICE · BUILD 818"
                var fw := E0.mono.get_string_size(foot, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
                draw_string(E0.mono, Vector2((vp.x - fw) * 0.5, vp.y - 28.0), foot, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, E0.DIM)
                var ctl := "A/D MOVE · SPACE JUMP · SHIFT ROLL · J ATTACK · TAB OBSERVE · E MODIFY · F INTERACT · ESC PAUSE"
                var cw := E0.mono.get_string_size(ctl, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
                draw_string(E0.mono, Vector2((vp.x - cw) * 0.5, vp.y - 46.0), ctl, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.7))

func hide_screen() -> void:
        visible = false
        set_process(false)

func _diamond(c: Vector2, r: float, col: Color) -> void:
        var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
        draw_colored_polygon(pts, col)

func show_screen() -> void:
        visible = true
        set_process(true)
        _rebuild_menu()
